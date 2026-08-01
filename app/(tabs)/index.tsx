import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Plus, MapPin, ArrowRight, Activity, Clock, WifiOff } from 'lucide-react-native';
import { useRole } from '../../lib/context';
import { useRouter } from 'expo-router';
import { StatusChip } from '../../components/StatusChip';
import { SkeletonList } from '../../components/SkeletonServiceCard';
import { EmptyState } from '../../components/EmptyState';

export default function HomeScreen() {
  const { role, setRole } = useRole();
  const router = useRouter();
  const isWorker = role === 'worker';

  const [loading, setLoading] = useState(false);
  const [hasError, setHasError] = useState(false);

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <ScrollView contentContainerStyle={{ paddingBottom: 32 }} className="px-5 pt-4">
        
        {/* Top Header & Role Mode Toggle */}
        <View className="flex-row items-center justify-between mb-4">
          <View>
            <View className="flex-row items-center gap-1.5 mb-1">
              <View className="w-2 h-2 rounded-full bg-[#10b981]" />
              <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider">
                OPS SYSTEM ONLINE
              </Text>
            </View>
            <Text className="text-xl font-bold text-ink-900 tracking-tight">
              {isWorker ? 'Ramesh Kumar (ID: W-4091)' : 'Sharma Household Ops'}
            </Text>
          </View>

          {/* Role Toggle Button */}
          <TouchableOpacity
            activeOpacity={0.85}
            onPress={() => setRole(isWorker ? 'household' : 'worker')}
            className="px-3 py-1.5 rounded-control bg-surface border border-[#262320] flex-row items-center shadow-sm active:scale-[0.98]"
          >
            <Text className="text-xs font-mono text-ink-900 font-medium mr-1">
              {isWorker ? 'MODE: WORKER' : 'MODE: EMPLOYER'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* System Summary Card Banner */}
        <View className="p-4 rounded-card bg-surface border border-[#262320] shadow-card mb-4">
          <View className="flex-row items-center justify-between mb-3">
            <View className="flex-row items-center gap-2">
              <Activity size={16} color="#a8a29a" strokeWidth={2} />
              <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider">
                {isWorker ? 'Dispatch Status' : 'Workforce Overview'}
              </Text>
            </View>

            {/* StatusChip Component */}
            <StatusChip
              status={isWorker ? 'open' : 'open'}
              labelOverride={isWorker ? 'STATUS: AVAILABLE' : '2 POSTINGS ACTIVE'}
            />
          </View>

          <Text className="text-xs text-ink-600 mb-4 leading-5">
            {isWorker
              ? 'Profile active in Indiranagar sector. Expected rate: ₹650/day.'
              : 'Active postings receiving worker applications in HSR Layout Sector 3.'}
          </Text>

          {/* Primary Action CTAs */}
          <View className="flex-row items-center gap-3">
            {isWorker ? (
              <TouchableOpacity
                activeOpacity={0.85}
                onPress={() => router.push('/(tabs)/jobs')}
                className="bg-brand-600 py-2 px-3.5 rounded-control flex-row items-center border border-brand-600 active:scale-[0.98]"
              >
                <Text className="text-white font-mono text-xs font-medium mr-1.5">View 12 Open Jobs</Text>
                <ArrowRight size={14} color="#FFFFFF" strokeWidth={2} />
              </TouchableOpacity>
            ) : (
              <TouchableOpacity
                activeOpacity={0.85}
                onPress={() => router.push('/post-job' as any)}
                className="bg-brand-600 py-2 px-3.5 rounded-control flex-row items-center border border-brand-600 active:scale-[0.98]"
              >
                <Plus size={14} color="#FFFFFF" strokeWidth={2} className="mr-1" />
                <Text className="text-white font-mono text-xs font-medium ml-1">Dispatch New Job</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>

        {/* Overline Tier: Section Label */}
        <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-2">
          {isWorker ? 'Work Parameters' : 'Dispatch Categories'}
        </Text>
        
        <View className="flex-row flex-wrap justify-between mb-4">
          {(isWorker
            ? [
                { label: 'PRIMARY SKILL', val: 'Painting', detail: 'Interior / Wall' },
                { label: 'DAILY RATE', val: '₹650', detail: 'per 8hr shift' },
                { label: 'SECTOR', val: 'Indiranagar', detail: 'Radius: 5km' },
                { label: 'RATING', val: '4.8 / 5', detail: '24 Reviews' },
              ]
            : [
                { label: 'PLUMBING', val: '14 Active', detail: 'Avg ₹600/day' },
                { label: 'CLEANING', val: '22 Active', detail: 'Avg ₹800/day' },
                { label: 'PAINTING', val: '8 Active', detail: 'Avg ₹1200/day' },
                { label: 'COOKING', val: '11 Active', detail: 'Avg ₹700/day' },
              ]
          ).map((item, idx) => (
            <View
              key={idx}
              className="w-[48%] p-3 rounded-card bg-surface border border-[#262320] shadow-card mb-2.5"
            >
              <Text className="text-[10px] font-mono text-ink-600 uppercase">{item.label}</Text>
              <Text className="text-sm font-bold text-ink-900 font-mono mt-0.5">{item.val}</Text>
              <Text className="text-[10px] text-ink-600 mt-1">{item.detail}</Text>
            </View>
          ))}
        </View>

        {/* Section Header */}
        <View className="flex-row items-center justify-between mb-3">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider">
            {isWorker ? 'Available Job Dispatch Feed' : 'Recent Job Postings'}
          </Text>
          <TouchableOpacity onPress={() => router.push('/(tabs)/jobs')}>
            <Text className="text-xs font-mono text-ink-600 font-medium underline">View All</Text>
          </TouchableOpacity>
        </View>

        {/* Loading State, Error State, or Recent Job Postings */}
        {hasError ? (
          <EmptyState
            icon={<WifiOff size={26} color="#f59e0b" strokeWidth={2} />}
            title="Dispatch Connection Error"
            description="Unable to sync live workforce dispatches with the central server. Please check your network."
            actionLabel="Retry Connection"
            onAction={() => {
              setHasError(false);
              setLoading(true);
              setTimeout(() => setLoading(false), 400);
            }}
          />
        ) : loading ? (
          <SkeletonList count={2} />
        ) : (
          <View className="space-y-2">
            {/* Job Posting Card 1 */}
            <TouchableOpacity
              activeOpacity={0.88}
              onPress={() => router.push('/job/1' as any)}
              className="p-3.5 rounded-card bg-surface border border-[#262320] shadow-card active:scale-[0.98] mb-2.5"
            >
              <View className="flex-row items-center justify-between mb-1.5">
                <View className="flex-row items-center gap-2">
                  <StatusChip status="open" />
                  <Text className="text-xs font-mono text-ink-600">Painting</Text>
                </View>
                <Text className="text-sm font-mono font-bold text-brand-600">₹1,500</Text>
              </View>

              <Text className="text-base font-bold text-ink-900 tracking-tight mb-2">
                Full House Painting (Interior Walls)
              </Text>

              <View className="flex-row items-center justify-between pt-2 border-t border-[#262320]">
                <View className="flex-row items-center gap-3">
                  <View className="flex-row items-center">
                    <MapPin size={12} color="#a8a29a" strokeWidth={2} />
                    <Text className="text-[10px] font-mono text-ink-600 ml-1">HSR Layout</Text>
                  </View>
                  <View className="flex-row items-center">
                    <Clock size={12} color="#a8a29a" strokeWidth={2} />
                    <Text className="text-[10px] font-mono text-ink-600 ml-1">Tomorrow 09:00</Text>
                  </View>
                </View>

                <Text className="text-[10px] font-mono text-ink-600">JOB ID: #8491</Text>
              </View>
            </TouchableOpacity>

            {/* Job Posting Card 2 */}
            <TouchableOpacity
              activeOpacity={0.88}
              onPress={() => router.push('/job/2' as any)}
              className="p-3.5 rounded-card bg-surface border border-[#262320] shadow-card active:scale-[0.98] mb-2.5"
            >
              <View className="flex-row items-center justify-between mb-1.5">
                <View className="flex-row items-center gap-2">
                  <StatusChip status="open" />
                  <Text className="text-xs font-mono text-ink-600">Cleaning</Text>
                </View>
                <Text className="text-sm font-mono font-bold text-brand-600">₹900</Text>
              </View>

              <Text className="text-base font-bold text-ink-900 tracking-tight mb-2">
                Deep Kitchen & Chimney Cleaning
              </Text>

              <View className="flex-row items-center justify-between pt-2 border-t border-[#262320]">
                <View className="flex-row items-center gap-3">
                  <View className="flex-row items-center">
                    <MapPin size={12} color="#a8a29a" strokeWidth={2} />
                    <Text className="text-[10px] font-mono text-ink-600 ml-1">Koramangala</Text>
                  </View>
                  <View className="flex-row items-center">
                    <Clock size={12} color="#a8a29a" strokeWidth={2} />
                    <Text className="text-[10px] font-mono text-ink-600 ml-1">Today 15:00</Text>
                  </View>
                </View>

                <Text className="text-[10px] font-mono text-ink-600">JOB ID: #8492</Text>
              </View>
            </TouchableOpacity>
          </View>
        )}

      </ScrollView>
    </SafeAreaView>
  );
}
