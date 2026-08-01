import React from 'react';
import { View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Building2, HardHat, ArrowRight, ShieldCheck, LogIn, CheckCircle2, ChevronRight } from 'lucide-react-native';
import { Logo } from '../components/Logo';
import { useRole } from '../lib/context';

export default function LandingScreen() {
  const router = useRouter();
  const { setRole } = useRole();

  const handleLaunchEmployer = async () => {
    await setRole('household');
    router.replace('/(tabs)');
  };

  const handleLaunchWorker = async () => {
    await setRole('worker');
    router.replace('/(tabs)');
  };

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <ScrollView contentContainerStyle={{ flexGrow: 1, paddingBottom: 28 }} className="px-5 pt-3">
        
        {/* Top-Left Logo Header Lockup & Sign In Action */}
        <View className="flex-row items-center justify-between py-2 mb-3 border-b border-[#262320]/60 pb-3">
          <Logo variant="header" />

          <TouchableOpacity
            activeOpacity={0.8}
            onPress={() => router.push('/auth')}
            className="flex-row items-center bg-surface px-3 py-1.5 rounded-control border border-[#262320]"
          >
            <LogIn size={13} color="#a8a29a" strokeWidth={2} className="mr-1.5" />
            <Text className="text-xs font-mono text-ink-600 font-medium ml-1">Sign In</Text>
          </TouchableOpacity>
        </View>

        {/* Product Headline (Headline Tier) */}
        <View className="my-2">
          <Text className="text-2xl font-bold text-ink-900 text-left tracking-tight leading-8">
            Daily Workforce & Dispatch Operations
          </Text>
          <Text className="text-xs text-ink-600 text-left leading-5 mt-1.5">
            Connecting daily-wage workers with households and local businesses for immediate daily jobs.
          </Text>
        </View>

        {/* Trust Metrics Bar */}
        <View className="flex-row items-center justify-between p-3.5 rounded-card bg-surface border border-[#262320] shadow-card my-3">
          <View className="items-center flex-1 border-r border-[#262320] pr-2">
            <Text className="text-sm font-mono font-bold text-ink-900">1,200+</Text>
            <Text className="text-[10px] font-mono text-ink-600 mt-0.5">Verified Workers</Text>
          </View>
          <View className="items-center flex-1 border-r border-[#262320] px-2">
            <Text className="text-sm font-mono font-bold text-[#10b981]">₹650/day</Text>
            <Text className="text-[10px] font-mono text-ink-600 mt-0.5">Avg Daily Rate</Text>
          </View>
          <View className="items-center flex-1 pl-2">
            <Text className="text-sm font-mono font-bold text-ink-900">60 Seconds</Text>
            <Text className="text-[10px] font-mono text-ink-600 mt-0.5">Job Dispatch</Text>
          </View>
        </View>

        {/* Overline Tier: Section Label */}
        <View className="mt-1 mb-2.5">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider">
            Select Navigation Portal
          </Text>
        </View>

        {/* PORTAL CARD 1: Household & Employer */}
        <TouchableOpacity
          activeOpacity={0.88}
          onPress={handleLaunchEmployer}
          className="p-4 rounded-card bg-surface border border-[#262320] shadow-card mb-3 active:scale-[0.98]"
        >
          <View className="flex-row items-center justify-between mb-2.5">
            <View className="flex-row items-center">
              <View className="w-9 h-9 rounded-control bg-surface-raised border border-[#262320] items-center justify-center mr-3">
                <Building2 size={18} color="#a8a29a" strokeWidth={2} />
              </View>
              <View>
                <Text className="text-base font-bold text-ink-900 tracking-tight">
                  Need Daily Workers?
                </Text>
                <Text className="text-[10px] font-mono text-ink-600 uppercase">
                  FOR HOUSEHOLDS & LOCAL BUSINESSES
                </Text>
              </View>
            </View>

            <ChevronRight size={18} color="#a8a29a" strokeWidth={2} />
          </View>

          <Text className="text-xs text-ink-600 mb-3 leading-5">
            Post daily requirements for cleaning, painting, plumbing, or cooking. Receive applications from verified local workers.
          </Text>

          <View className="flex-row items-center justify-between pt-2.5 border-t border-[#262320]/60">
            <View className="flex-row items-center gap-1.5">
              <CheckCircle2 size={12} color="#10b981" strokeWidth={2} />
              <Text className="text-[10px] font-mono text-ink-600">Instant Job Posting</Text>
            </View>

            <View className="bg-brand-600 px-3 py-1.5 rounded-control flex-row items-center">
              <Text className="text-white text-xs font-mono font-bold mr-1">Employer Portal</Text>
              <ArrowRight size={12} color="#FFFFFF" strokeWidth={2} />
            </View>
          </View>
        </TouchableOpacity>

        {/* PORTAL CARD 2: Skilled Worker */}
        <TouchableOpacity
          activeOpacity={0.88}
          onPress={handleLaunchWorker}
          className="p-4 rounded-card bg-surface border border-[#262320] shadow-card mb-4 active:scale-[0.98]"
        >
          <View className="flex-row items-center justify-between mb-2.5">
            <View className="flex-row items-center">
              <View className="w-9 h-9 rounded-control bg-surface-raised border border-[#262320] items-center justify-center mr-3">
                <HardHat size={18} color="#10b981" strokeWidth={2} />
              </View>
              <View>
                <Text className="text-base font-bold text-ink-900 tracking-tight">
                  Looking for Daily Work?
                </Text>
                <Text className="text-[10px] font-mono text-[#10b981] uppercase">
                  FOR SKILLED DAILY-WAGE WORKERS
                </Text>
              </View>
            </View>

            <ChevronRight size={18} color="#a8a29a" strokeWidth={2} />
          </View>

          <Text className="text-xs text-ink-600 mb-3 leading-5">
            Browse open daily listings nearby, express interest, manage your daily availability, and set your expected daily wage rate.
          </Text>

          <View className="flex-row items-center justify-between pt-2.5 border-t border-[#262320]/60">
            <View className="flex-row items-center gap-1.5">
              <CheckCircle2 size={12} color="#10b981" strokeWidth={2} />
              <Text className="text-[10px] font-mono text-ink-600">Direct Employer Contact</Text>
            </View>

            <View className="bg-surface-raised border border-[#262320] px-3 py-1.5 rounded-control flex-row items-center">
              <Text className="text-ink-900 text-xs font-mono font-bold mr-1">Worker Feed</Text>
              <ArrowRight size={12} color="#f7f3ea" strokeWidth={2} />
            </View>
          </View>
        </TouchableOpacity>

        {/* Footer Security Badge */}
        <View className="flex-row items-center justify-center gap-1.5 mt-auto pt-2">
          <ShieldCheck size={13} color="#10b981" strokeWidth={2} />
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider">
            RLS Enforced • Aadhaar Verified Workforce
          </Text>
        </View>

      </ScrollView>
    </SafeAreaView>
  );
}
