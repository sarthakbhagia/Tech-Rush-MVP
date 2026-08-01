import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity, ActivityIndicator } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { ArrowLeft, MapPin, Briefcase, Clock, Users } from 'lucide-react-native';
import { useRole } from '../../lib/context';
import { JobStatusStepper, JobStage } from '../../components/JobStatusStepper';
import { StatusChip } from '../../components/StatusChip';
import { ProviderCard } from '../../components/ProviderCard';
import { TrustBadgeRow } from '../../components/TrustBadgeRow';
import { RatingBreakdown } from '../../components/RatingBreakdown';
import { StickyBottomBar } from '../../components/StickyBottomBar';
import { useToast } from '../../lib/ToastContext';
import { EmptyState } from '../../components/EmptyState';

export default function JobDetailScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const { role } = useRole();
  const { showToast } = useToast();
  const isWorker = role === 'worker';

  const [hasApplied, setHasApplied] = useState(false);
  const [isApplying, setIsApplying] = useState(false);
  const [assignedWorker, setAssignedWorker] = useState<string | null>(null);

  const currentStage: JobStage = assignedWorker
    ? 'assigned'
    : hasApplied
    ? 'interested'
    : 'posted';

  const job = {
    id: id || '1',
    jobId: '#8491',
    title: 'Full House Painting (Interior Walls)',
    category: 'Painting',
    location: 'HSR Layout Sector 3, Bengaluru',
    budget: 1500,
    jobDate: 'Tomorrow 09:00',
    household: 'Sharma Household Ops',
    description: 'Looking for 1 experienced painter to paint living room and 2 bedrooms. Wall primer and paint materials provided on site. Estimated duration: 1 day (8 hours).',
  };

  const applicants = [
    {
      id: 'w1',
      name: 'Ramesh Kumar',
      skills: ['Painting', 'Wall Tiling', 'Waterproofing'],
      wage: 650,
      rating: 4.8,
      reviewsCount: 24,
      jobsCompleted: 32,
      phone: '+91 98765 43210',
    },
    {
      id: 'w2',
      name: 'Sunil Sharma',
      skills: ['Painting', 'Plumbing'],
      wage: 700,
      rating: 4.9,
      reviewsCount: 38,
      jobsCompleted: 54,
      phone: '+91 98123 45678',
    },
  ];

  const handleApply = () => {
    setIsApplying(true);
    setTimeout(() => {
      setIsApplying(false);
      setHasApplied(true);
      showToast('Interest Registered', 'Your application has been logged on the job dispatch ledger.', 'success');
    }, 600);
  };

  const handleHireWorker = (workerName: string) => {
    setAssignedWorker(workerName);
    showToast('Worker Assigned', `${workerName} assigned to Job ${job.jobId}. Contact unlocked.`, 'success');
  };

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <ScrollView contentContainerStyle={{ paddingBottom: 110 }} className="px-5 pt-4">
        
        {/* Navigation Bar */}
        <View className="flex-row items-center justify-between mb-4">
          <TouchableOpacity
            onPress={() => router.back()}
            className="bg-surface p-2.5 rounded-control border border-[#262320] shadow-sm active:scale-[0.98]"
          >
            <ArrowLeft size={18} color="#a8a29a" strokeWidth={2} />
          </TouchableOpacity>

          <View className="flex-row items-center gap-2">
            <StatusChip status={assignedWorker ? 'assigned' : hasApplied ? 'interested' : 'open'} />
            <View className="px-2.5 py-1 rounded bg-surface-raised border border-[#262320]">
              <Text className="text-[10px] font-mono font-medium text-ink-600 uppercase">{job.category.toUpperCase()}</Text>
            </View>
          </View>
        </View>

        {/* SIGNATURE ELEMENT: Horizontal 4-Stage Job Stepper */}
        <JobStatusStepper currentStage={currentStage} />

        {/* Job Header & Rate Specs Card */}
        <View className="p-4 rounded-card bg-surface border border-[#262320] shadow-card mb-4">
          <View className="flex-row items-start justify-between mb-2">
            <View className="flex-1 pr-3">
              <Text className="text-xl font-bold text-ink-900 tracking-tight leading-7">{job.title}</Text>
              <Text className="text-[10px] font-mono text-ink-600 mt-1">DISPATCH: {job.jobId} • {job.household}</Text>
            </View>
            <View className="items-end bg-surface-raised px-3 py-1.5 rounded-control border border-[#262320]">
              <Text className="text-lg font-mono font-bold text-brand-600">₹{job.budget}</Text>
              <Text className="text-[9px] font-mono text-ink-600 uppercase">DAILY RATE</Text>
            </View>
          </View>

          <View className="my-3 h-[1px] bg-[#262320]" />

          <View className="flex-row items-center justify-between">
            <View className="flex-row items-center flex-1 mr-2">
              <MapPin size={14} color="#a8a29a" strokeWidth={2} />
              <Text className="text-[10px] font-mono text-ink-600 ml-1.5 flex-1" numberOfLines={1}>
                {job.location}
              </Text>
            </View>

            <View className="flex-row items-center">
              <Clock size={14} color="#a8a29a" strokeWidth={2} />
              <Text className="text-[10px] font-mono text-ink-600 ml-1.5">
                {job.jobDate}
              </Text>
            </View>
          </View>
        </View>

        {/* Employer Trust Layer Block */}
        <View className="mb-4">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-2">Job Poster Verification</Text>
          <ProviderCard
            name="Sharma Household Ops"
            primarySkill="Verified Employer"
            rating={4.9}
            jobsCompleted={18}
            phone="+91 98765 00000"
            skills={['Verified Address', 'Fast Payout', 'Aadhaar Linked']}
            isVerified={true}
          />
        </View>

        {/* Domain Compliance Trust Badges */}
        <View className="mb-4">
          <TrustBadgeRow />
        </View>

        {/* Task Requirements & Specs Card */}
        <View className="p-4 rounded-card bg-surface border border-[#262320] shadow-card mb-4">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-2">Task Requirements & Specs</Text>
          <Text className="text-xs text-ink-600 leading-5">{job.description}</Text>
        </View>

        {/* Rating Breakdown */}
        <View className="mb-4">
          <RatingBreakdown average={4.8} total={24} />
        </View>

        {/* Household Applicants Section (Employer Mode) */}
        {!isWorker && (
          <View className="mb-4">
            <View className="flex-row items-center justify-between mb-2.5">
              <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider">
                Interested Workers ({applicants.length})
              </Text>
              <Text className="text-[10px] font-mono text-[#10b981] uppercase">VERIFIED WORKFORCE</Text>
            </View>

            {applicants.length === 0 ? (
              <EmptyState
                icon={<Users size={26} color="#a8a29a" strokeWidth={2} />}
                title="No worker applications yet"
                description="Your job dispatch is actively broadcasted to verified workers nearby."
              />
            ) : (
              applicants.map((worker) => (
                <ProviderCard
                  key={worker.id}
                  name={worker.name}
                  rating={worker.rating}
                  reviewsCount={worker.reviewsCount}
                  jobsCompleted={worker.jobsCompleted}
                  phone={worker.phone}
                  skills={worker.skills}
                  wage={worker.wage}
                  isAssigned={assignedWorker === worker.name}
                  onHire={() => handleHireWorker(worker.name)}
                />
              ))
            )}
          </View>
        )}

      </ScrollView>

      {/* STICKY CONVERSION BAR */}
      <StickyBottomBar
        label="DAILY RATE"
        price={job.budget}
        ctaLabel={
          isApplying
            ? 'Registering Interest...'
            : isWorker
            ? hasApplied
              ? 'Interest Logged ✓'
              : 'Express Interest & Apply'
            : assignedWorker
            ? `Assigned to ${assignedWorker}`
            : 'Select Worker Above'
        }
        disabled={isApplying || (isWorker ? hasApplied : !assignedWorker)}
        onCta={isWorker ? handleApply : () => {}}
        icon={
          isApplying ? (
            <ActivityIndicator size="small" color="#FFFFFF" />
          ) : (
            <Briefcase size={16} color="#FFFFFF" strokeWidth={2} />
          )
        }
      />
    </SafeAreaView>
  );
}
