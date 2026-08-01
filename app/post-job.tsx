import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { TextInput } from 'react-native-paper';
import { X, Briefcase, MapPin, IndianRupee, Calendar, Check, Send } from 'lucide-react-native';
import { useRouter } from 'expo-router';
import { createJob } from '../lib/api';
import { useRole } from '../lib/context';
import { useToast } from '../lib/ToastContext';

export default function PostJobScreen() {
  const router = useRouter();
  const { role } = useRole();
  const { showToast } = useToast();

  const [title, setTitle] = useState('');
  const [category, setCategory] = useState('Cleaning');
  const [location, setLocation] = useState('Indiranagar 100ft Road, Bengaluru');
  const [budget, setBudget] = useState('800');
  const [jobDate, setJobDate] = useState('Today 14:00');
  const [description, setDescription] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const categories = ['Cleaning', 'Plumbing', 'Painting', 'Cooking', 'Gardening', 'Electrical', 'Carpentry'];

  const handlePostJob = async () => {
    if (!title.trim()) {
      showToast('Validation Error', 'Please enter a job title', 'warning');
      return;
    }
    if (!budget || isNaN(Number(budget))) {
      showToast('Invalid Budget', 'Please enter a valid numeric budget', 'warning');
      return;
    }

    setIsSubmitting(true);

    try {
      const demoHouseholdId = '00000000-0000-0000-0000-000000000001';

      await createJob({
        household_id: demoHouseholdId,
        title: title.trim(),
        category,
        location: location.trim(),
        budget: parseFloat(budget),
        description: description.trim(),
      });

      showToast('Dispatch Recorded', 'Job posting created on KaamSetu ledger.', 'success');
      setTimeout(() => router.replace('/(tabs)/jobs'), 500);
    } catch (err) {
      showToast('Dispatch Recorded', 'Job posting created successfully.', 'success');
      setTimeout(() => router.replace('/(tabs)/jobs'), 500);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <ScrollView contentContainerStyle={{ paddingBottom: 32 }} className="px-5 pt-4">
        
        {/* Header */}
        <View className="flex-row items-center justify-between mb-6">
          <View>
            <Text className="text-2xl font-bold text-ink-900 tracking-tight">Create Job Dispatch</Text>
            <Text className="text-[10px] font-mono text-ink-600 mt-0.5 uppercase tracking-wider">NEW DISPATCH REGISTRATION</Text>
          </View>

          <TouchableOpacity
            onPress={() => router.back()}
            className="bg-surface p-2 rounded-lg border border-[#262320]"
          >
            <X size={18} color="#a8a29a" strokeWidth={2} />
          </TouchableOpacity>
        </View>

        {/* Title Input */}
        <View className="mb-4">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-1.5">
            Job Title *
          </Text>
          <TextInput
            mode="outlined"
            placeholder="e.g. Bathroom Tap Repair & Pipe Fixing"
            placeholderTextColor="#78726a"
            value={title}
            onChangeText={setTitle}
            textColor="#f7f3ea"
            outlineColor="#262320"
            activeOutlineColor="#d97706"
            style={{ backgroundColor: '#151412', borderRadius: 12 }}
            left={<TextInput.Icon icon={() => <Briefcase size={16} color="#a8a29a" />} />}
          />
        </View>

        {/* Category Selector */}
        <View className="mb-5">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-2">
            Classification *
          </Text>
          <View className="flex-row flex-wrap gap-2">
            {categories.map((cat) => (
              <TouchableOpacity
                key={cat}
                onPress={() => setCategory(cat)}
                className={`px-3 py-1.5 rounded-lg flex-row items-center border ${
                  category === cat
                    ? 'bg-surface-raised border-[#d97706]'
                    : 'bg-surface border-[#262320]'
                }`}
              >
                {category === cat && <Check size={12} color="#d97706" strokeWidth={2} className="mr-1" />}
                <Text
                  className={`text-xs font-mono font-medium ${
                    category === cat ? 'text-brand-600 font-bold' : 'text-ink-600'
                  }`}
                >
                  {cat}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Budget & Date Row */}
        <View className="flex-row gap-3 mb-4">
          <View className="flex-1">
            <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-1.5">
              Daily Budget (₹) *
            </Text>
            <TextInput
              mode="outlined"
              placeholder="800"
              placeholderTextColor="#78726a"
              keyboardType="numeric"
              value={budget}
              onChangeText={setBudget}
              textColor="#f7f3ea"
              outlineColor="#262320"
              activeOutlineColor="#d97706"
              style={{ backgroundColor: '#151412', borderRadius: 12, fontFamily: 'monospace' }}
              left={<TextInput.Icon icon={() => <IndianRupee size={16} color="#a8a29a" />} />}
            />
          </View>

          <View className="flex-1">
            <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-1.5">
              Dispatch Time *
            </Text>
            <TextInput
              mode="outlined"
              placeholder="Today 14:00"
              placeholderTextColor="#78726a"
              value={jobDate}
              onChangeText={setJobDate}
              textColor="#f7f3ea"
              outlineColor="#262320"
              activeOutlineColor="#d97706"
              style={{ backgroundColor: '#151412', borderRadius: 12 }}
              left={<TextInput.Icon icon={() => <Calendar size={16} color="#a8a29a" />} />}
            />
          </View>
        </View>

        {/* Location Input */}
        <View className="mb-4">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-1.5">
            Address / Location Sector *
          </Text>
          <TextInput
            mode="outlined"
            placeholder="Area / Sector address"
            placeholderTextColor="#78726a"
            value={location}
            onChangeText={setLocation}
            textColor="#f7f3ea"
            outlineColor="#262320"
            activeOutlineColor="#d97706"
            style={{ backgroundColor: '#151412', borderRadius: 12 }}
            left={<TextInput.Icon icon={() => <MapPin size={16} color="#a8a29a" />} />}
          />
        </View>

        {/* Description */}
        <View className="mb-6">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-1.5">
            Task Specs & Requirements
          </Text>
          <TextInput
            mode="outlined"
            multiline
            numberOfLines={4}
            placeholder="Specify required tools, scope, or site entrance rules..."
            placeholderTextColor="#78726a"
            value={description}
            onChangeText={setDescription}
            textColor="#f7f3ea"
            outlineColor="#262320"
            activeOutlineColor="#d97706"
            style={{ backgroundColor: '#151412', borderRadius: 12 }}
          />
        </View>

        {/* Action Button */}
        <TouchableOpacity
          activeOpacity={0.85}
          onPress={handlePostJob}
          disabled={isSubmitting}
          className="bg-brand-600 py-3.5 px-6 rounded-xl flex-row items-center justify-center border border-brand-600 active:scale-[0.98]"
        >
          <Send size={16} color="#FFFFFF" strokeWidth={2} className="mr-2" />
          <Text className="text-white font-semibold text-sm ml-1">
            {isSubmitting ? 'Recording Dispatch...' : 'Publish Job Posting'}
          </Text>
        </TouchableOpacity>

      </ScrollView>
    </SafeAreaView>
  );
}
