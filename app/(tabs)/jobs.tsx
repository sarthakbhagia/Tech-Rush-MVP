import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Searchbar } from 'react-native-paper';
import { MapPin, Plus, Clock, SearchX, Filter, Check } from 'lucide-react-native';
import { useRole } from '../../lib/context';
import { useRouter } from 'expo-router';
import { StatusChip } from '../../components/StatusChip';
import { SkeletonList } from '../../components/SkeletonServiceCard';
import { BottomSheet } from '../../components/BottomSheet';
import { EmptyState } from '../../components/EmptyState';

export default function JobsScreen() {
  const router = useRouter();
  const { role } = useRole();
  const isWorker = role === 'worker';
  
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [selectedStatus, setSelectedStatus] = useState('open');
  const [isCategorySheetOpen, setIsCategorySheetOpen] = useState(false);
  const [isFilterLoading, setIsFilterLoading] = useState(false);

  const categories = ['All', 'Cleaning', 'Plumbing', 'Painting', 'Cooking', 'Gardening', 'Electrical'];

  const handleSelectCategory = (cat: string) => {
    setIsFilterLoading(true);
    setSelectedCategory(cat);
    setIsCategorySheetOpen(false);
    setTimeout(() => setIsFilterLoading(false), 250);
  };

  const handleSelectStatus = (status: string) => {
    setIsFilterLoading(true);
    setSelectedStatus(status);
    setTimeout(() => setIsFilterLoading(false), 250);
  };

  const jobsList = [
    {
      id: '1',
      jobId: '#8491',
      title: 'Full House Painting (Interior Walls)',
      category: 'Painting',
      location: 'HSR Layout Sector 3',
      budget: 1500,
      jobDate: 'Tomorrow 09:00',
      status: 'open',
      household: 'Kapoor Family',
      interests: 4,
    },
    {
      id: '2',
      jobId: '#8492',
      title: 'Deep Kitchen & Chimney Cleaning',
      category: 'Cleaning',
      location: 'Koramangala 5th Block',
      budget: 900,
      jobDate: 'Today 15:00',
      status: 'open',
      household: 'Ananya Roy',
      interests: 2,
    },
    {
      id: '3',
      jobId: '#8493',
      title: 'Garden Lawn Mowing & Trimming',
      category: 'Gardening',
      location: 'Indiranagar 100ft Road',
      budget: 700,
      jobDate: '05 Aug 2026',
      status: 'assigned',
      household: 'Dr. Mehta',
      interests: 6,
    },
    {
      id: '4',
      jobId: '#8494',
      title: 'Main Door Lock Repair & Hinge Fix',
      category: 'Plumbing',
      location: 'BTM Layout 2nd Stage',
      budget: 500,
      jobDate: '02 Aug 2026',
      status: 'completed',
      household: 'Vikram Singh',
      interests: 1,
    },
  ];

  const filteredJobs = jobsList.filter(job => {
    const matchesCategory = selectedCategory === 'All' || job.category === selectedCategory;
    const matchesStatus = job.status === selectedStatus;
    const matchesSearch = job.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          job.location.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesStatus && matchesSearch;
  });

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <View className="px-5 pt-4 flex-1">
        
        {/* Header Title & Overline Subhead */}
        <View className="flex-row items-center justify-between mb-4">
          <View>
            <Text className="text-2xl font-bold text-ink-900 tracking-tight">
              {isWorker ? 'Available Jobs Ledger' : 'Job Dispatch Registry'}
            </Text>
            <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mt-0.5">
              {isWorker ? 'ACTIVE WORK OPPORTUNITIES NEARBY' : 'MANAGE CREATED DISPATCHES'}
            </Text>
          </View>
          
          {!isWorker && (
            <TouchableOpacity
              activeOpacity={0.85}
              onPress={() => router.push('/post-job' as any)}
              className="bg-brand-600 p-2.5 rounded-card border border-brand-600 active:scale-[0.98]"
            >
              <Plus size={18} color="#FFFFFF" strokeWidth={2} />
            </TouchableOpacity>
          )}
        </View>

        {/* Search Bar */}
        <Searchbar
          placeholder="Filter by title or location..."
          placeholderTextColor="#a8a29a"
          onChangeText={setSearchQuery}
          value={searchQuery}
          iconColor="#a8a29a"
          inputStyle={{ fontSize: 13, color: '#f7f3ea' }}
          style={{
            backgroundColor: '#151412',
            borderRadius: 12,
            marginBottom: 12,
            borderWidth: 1,
            borderColor: '#262320',
            elevation: 0,
          }}
        />

        {/* Category Filter Trigger */}
        <View className="flex-row items-center justify-between mb-3">
          <TouchableOpacity
            activeOpacity={0.85}
            onPress={() => setIsCategorySheetOpen(true)}
            className="flex-1 flex-row items-center justify-between px-3.5 py-2 rounded-control bg-surface border border-[#262320] shadow-sm active:scale-[0.98] mr-2"
          >
            <View className="flex-row items-center gap-2">
              <Filter size={14} color="#a8a29a" strokeWidth={2} />
              <Text className="text-xs font-mono text-ink-600">Category Filter:</Text>
              <Text className="text-xs font-mono font-bold text-brand-600">{selectedCategory}</Text>
            </View>

            <View className="px-2 py-0.5 rounded bg-surface-raised border border-[#262320]">
              <Text className="text-[10px] font-mono text-ink-600 font-bold uppercase">CHANGE</Text>
            </View>
          </TouchableOpacity>
        </View>

        {/* Status Filter Tabs */}
        <View className="flex-row bg-surface p-1 rounded-card border border-[#262320] mb-4">
          {[
            { label: 'OPEN', val: 'open' },
            { label: 'ASSIGNED', val: 'assigned' },
            { label: 'COMPLETED', val: 'completed' },
          ].map((tab) => (
            <TouchableOpacity
              key={tab.val}
              onPress={() => handleSelectStatus(tab.val)}
              className={`flex-1 py-2 items-center rounded-control ${
                selectedStatus === tab.val ? 'bg-surface-raised border border-[#262320]' : ''
              }`}
            >
              <Text
                className={`text-xs font-mono font-bold ${
                  selectedStatus === tab.val ? 'text-brand-600' : 'text-ink-600'
                }`}
              >
                {tab.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Dense Ops Row List */}
        <ScrollView contentContainerStyle={{ paddingBottom: 32 }} showsVerticalScrollIndicator={false}>
          {isFilterLoading ? (
            <SkeletonList count={3} />
          ) : filteredJobs.length === 0 ? (
            <EmptyState
              icon={<SearchX size={26} color="#a8a29a" strokeWidth={2} />}
              title="No matching dispatches found"
              description={`No job listings match category "${selectedCategory}" with status "${selectedStatus.toUpperCase()}".`}
              actionLabel="Clear All Filters"
              onAction={() => {
                setSelectedCategory('All');
                setSelectedStatus('open');
                setSearchQuery('');
              }}
            />
          ) : (
            filteredJobs.map((job) => (
              <TouchableOpacity
                key={job.id}
                activeOpacity={0.88}
                onPress={() => router.push(`/job/${job.id}` as any)}
                className="p-3.5 rounded-card bg-surface border border-[#262320] shadow-card mb-2.5 active:scale-[0.98]"
              >
                <View className="flex-row items-center justify-between mb-1.5">
                  <View className="flex-row items-center gap-2">
                    <StatusChip status={job.status as any} />
                    <Text className="text-xs font-mono text-ink-600">{job.category}</Text>
                    <Text className="text-[10px] font-mono text-ink-600">• {job.household}</Text>
                  </View>

                  <Text className="text-base font-mono font-bold text-brand-600">
                    ₹{job.budget}
                  </Text>
                </View>

                <Text className="text-base font-bold text-ink-900 tracking-tight mb-2">{job.title}</Text>

                {/* Receded Metadata Row */}
                <View className="flex-row items-center justify-between pt-2 border-t border-[#262320]">
                  <View className="flex-row items-center gap-3">
                    <View className="flex-row items-center">
                      <MapPin size={12} color="#a8a29a" strokeWidth={2} />
                      <Text className="text-[10px] font-mono text-ink-600 ml-1">{job.location}</Text>
                    </View>
                    <View className="flex-row items-center">
                      <Clock size={12} color="#a8a29a" strokeWidth={2} />
                      <Text className="text-[10px] font-mono text-ink-600 ml-1">{job.jobDate}</Text>
                    </View>
                  </View>

                  <Text className="text-[10px] font-mono text-ink-600">JOB ID: {job.jobId}</Text>
                </View>
              </TouchableOpacity>
            ))
          )}
        </ScrollView>

        {/* Category Filter BottomSheet */}
        <BottomSheet
          open={isCategorySheetOpen}
          onClose={() => setIsCategorySheetOpen(false)}
          title="Filter Dispatches by Category"
        >
          <View className="space-y-2 py-1">
            {categories.map((cat) => {
              const isSelected = selectedCategory === cat;
              return (
                <TouchableOpacity
                  key={cat}
                  activeOpacity={0.8}
                  onPress={() => handleSelectCategory(cat)}
                  className={`flex-row items-center justify-between p-3 rounded-control border ${
                    isSelected
                      ? 'bg-surface-raised border-brand-600'
                      : 'bg-surface border-[#262320]'
                  }`}
                >
                  <Text
                    className={`text-xs font-mono font-medium ${
                      isSelected ? 'text-brand-600 font-bold' : 'text-ink-900'
                    }`}
                  >
                    {cat}
                  </Text>
                  {isSelected && <Check size={16} color="#d97706" strokeWidth={2} />}
                </TouchableOpacity>
              );
            })}
          </View>
        </BottomSheet>

      </View>
    </SafeAreaView>
  );
}
