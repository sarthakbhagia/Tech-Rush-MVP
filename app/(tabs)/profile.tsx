import React, { useState } from 'react';
import { View, Text, ScrollView, TouchableOpacity } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Avatar } from 'react-native-paper';
import { User, ShieldCheck, RefreshCw, ChevronRight, Settings, Award, Star, Plus, Check, CalendarX } from 'lucide-react-native';
import { useRole } from '../../lib/context';
import { TrustBadgeRow } from '../../components/TrustBadgeRow';
import { BottomSheet } from '../../components/BottomSheet';
import { EmptyState } from '../../components/EmptyState';

export default function ProfileScreen() {
  const { role, setRole } = useRole();
  const isWorker = role === 'worker';

  const [availability, setAvailability] = useState<'available' | 'busy'>('available');
  const [skills, setSkills] = useState<string[]>([
    'House Painting',
    'Plumbing',
    'Wall Tiling',
    'Waterproofing',
  ]);
  const [isSkillsSheetOpen, setIsSkillsSheetOpen] = useState(false);

  const availableSkillOptions = [
    'House Painting',
    'Plumbing',
    'Wall Tiling',
    'Waterproofing',
    'Electrical',
    'Deep Cleaning',
    'Carpentry',
    'Gardening',
  ];

  const toggleSkill = (skill: string) => {
    if (skills.includes(skill)) {
      setSkills(skills.filter((s) => s !== skill));
    } else {
      setSkills([...skills, skill]);
    }
  };

  const toggleAvailability = () => {
    setAvailability((prev) => (prev === 'available' ? 'busy' : 'available'));
  };

  return (
    <SafeAreaView className="flex-1 bg-canvas">
      <ScrollView contentContainerStyle={{ paddingBottom: 32 }} className="px-5 pt-4">
        
        {/* Header Title */}
        <View className="mb-4">
          <Text className="text-2xl font-bold text-ink-900 tracking-tight">System Profile & Settings</Text>
          <Text className="text-[10px] font-mono text-ink-600 mt-0.5 uppercase">OPERATOR ID: #USR-9021</Text>
        </View>

        {/* User Ops Card with Trust Badges */}
        <View className="p-4 rounded-card bg-surface border border-[#262320] shadow-card mb-4">
          <View className="flex-row items-center">
            <Avatar.Text
              size={52}
              label={isWorker ? 'RK' : 'SF'}
              style={{ backgroundColor: '#1c1a17', borderColor: '#262320', borderWidth: 1 }}
              color="#f7f3ea"
            />
            <View className="ml-3 flex-1">
              <View className="flex-row items-center justify-between">
                <Text className="text-base font-bold text-ink-900 tracking-tight">
                  {isWorker ? 'Ramesh Kumar' : 'Sharma Household Ops'}
                </Text>
                <ShieldCheck size={16} color="#10b981" strokeWidth={2} />
              </View>

              <Text className="text-xs font-mono text-ink-600 mt-0.5">+91 98765 43210</Text>
              
              {isWorker && (
                <View className="flex-row items-center gap-1.5 mt-2">
                  <Star size={13} color="#f59e0b" fill="#f59e0b" />
                  <Text className="text-xs font-mono font-bold text-warning-600">4.8</Text>
                  <Text className="text-xs font-mono text-ink-600">(24 verified reviews)</Text>
                </View>
              )}
            </View>
          </View>

          {/* Domain Compliance Trust Badges */}
          <View className="mt-3.5 pt-3 border-t border-[#262320]">
            <TrustBadgeRow />
          </View>
        </View>

        {/* Worker Dispatch Status */}
        {isWorker && (
          <View className="mb-4">
            <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-2">
              Workforce Dispatch Specs
            </Text>

            <View className="p-4 rounded-card bg-surface border border-[#262320] shadow-card">
              <View className="flex-row items-center justify-between py-2 border-b border-[#262320]">
                <View>
                  <Text className="text-xs font-semibold text-ink-900">Availability Status</Text>
                  <Text className="text-[10px] font-mono text-ink-600 mt-0.5">
                    {availability === 'available'
                      ? 'Visible to daily job dispatch requests'
                      : 'Hidden from active worker search'}
                  </Text>
                </View>

                <TouchableOpacity
                  activeOpacity={0.8}
                  onPress={toggleAvailability}
                  className={`px-3 py-1 rounded-control border ${
                    availability === 'available'
                      ? 'bg-success-100 border-[#10b981]/40'
                      : 'bg-danger-100 border-[#dc2626]/40'
                  }`}
                >
                  <Text
                    className={`text-[10px] font-mono font-bold uppercase ${
                      availability === 'available' ? 'text-success-600' : 'text-danger-600'
                    }`}
                  >
                    {availability}
                  </Text>
                </TouchableOpacity>
              </View>

              <View className="flex-row items-center justify-between py-3 border-b border-[#262320]">
                <Text className="text-xs font-semibold text-ink-900">Expected Daily Rate</Text>
                <Text className="text-sm font-mono font-bold text-brand-600">₹650 / day</Text>
              </View>

              <View className="mt-3">
                <View className="flex-row items-center justify-between mb-2">
                  <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider">
                    Verified Skill Classifications ({skills.length})
                  </Text>
                  
                  <TouchableOpacity
                    onPress={() => setIsSkillsSheetOpen(true)}
                    className="flex-row items-center gap-1"
                  >
                    <Plus size={11} color="#a8a29a" strokeWidth={2} />
                    <Text className="text-[10px] font-mono text-ink-600 font-bold underline uppercase">Edit Skills</Text>
                  </TouchableOpacity>
                </View>

                <View className="flex-row flex-wrap gap-1.5">
                  {skills.map((skill) => (
                    <TouchableOpacity
                      key={skill}
                      activeOpacity={0.8}
                      onPress={() => setIsSkillsSheetOpen(true)}
                      className="px-2.5 py-1 rounded-control bg-surface-raised border border-[#262320] active:scale-[0.98]"
                    >
                      <Text className="text-[10px] font-mono text-ink-600">{skill}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            </View>
          </View>
        )}

        {/* Recent Job Dispatches Log */}
        <View className="mb-4">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-2">
            Dispatch Performance & History
          </Text>

          <EmptyState
            icon={<CalendarX size={26} color="#a8a29a" strokeWidth={2} />}
            title="No past job dispatches recorded"
            description={
              isWorker
                ? "Your completed daily jobs and employer ratings will appear here."
                : "Your posted daily job dispatches and assigned workers will appear here."
            }
          />
        </View>

        {/* Role Reconfiguration Section */}
        <View className="mb-4">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-2">
            System Reconfiguration
          </Text>

          <View className="p-4 rounded-card bg-surface border border-[#262320] shadow-card">
            <TouchableOpacity
              activeOpacity={0.8}
              onPress={() => setRole(isWorker ? 'household' : 'worker')}
              className="flex-row items-center justify-between py-1 active:scale-[0.99]"
            >
              <View className="flex-row items-center">
                <View className="p-2.5 rounded-control bg-surface-raised border border-[#262320] mr-3">
                  <RefreshCw size={16} color="#a8a29a" strokeWidth={2} />
                </View>
                <View>
                  <Text className="text-base font-bold text-ink-900 tracking-tight">
                    Switch to {isWorker ? 'Employer Mode' : 'Worker Mode'}
                  </Text>
                  <Text className="text-[10px] font-mono text-ink-600 mt-0.5 uppercase">
                    ACTIVE ROLE: {role.toUpperCase()}
                  </Text>
                </View>
              </View>
              <ChevronRight size={16} color="#a8a29a" strokeWidth={2} />
            </TouchableOpacity>
          </View>
        </View>

        {/* Account System Menu */}
        <View className="mb-4">
          <Text className="text-[10px] font-mono text-ink-600 uppercase tracking-wider mb-2">
            Account & Compliance
          </Text>

          <View className="p-4 rounded-card bg-surface border border-[#262320] shadow-card">
            {[
              { icon: User, label: 'Identity & Profile Records' },
              { icon: ShieldCheck, label: 'Aadhaar & Background Check Status' },
              { icon: Award, label: 'Dispatch Performance Log' },
              { icon: Settings, label: 'System Configuration' },
            ].map((item, idx) => (
              <TouchableOpacity
                key={idx}
                activeOpacity={0.8}
                className="flex-row items-center justify-between py-3 border-b border-[#262320]/50 last:border-b-0 active:scale-[0.99]"
              >
                <View className="flex-row items-center">
                  <item.icon size={16} color="#a8a29a" strokeWidth={2} />
                  <Text className="text-xs font-medium text-ink-900 ml-3">{item.label}</Text>
                </View>
                <ChevronRight size={16} color="#a8a29a" strokeWidth={2} />
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Edit Skills BottomSheet */}
        <BottomSheet
          open={isSkillsSheetOpen}
          onClose={() => setIsSkillsSheetOpen(false)}
          title="Edit Verified Skill Classifications"
        >
          <View className="space-y-2 py-1">
            <Text className="text-xs font-mono text-ink-600 mb-2">
              Select skills to feature on your worker profile:
            </Text>
            {availableSkillOptions.map((option) => {
              const isSelected = skills.includes(option);
              return (
                <TouchableOpacity
                  key={option}
                  activeOpacity={0.8}
                  onPress={() => toggleSkill(option)}
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
                    {option}
                  </Text>
                  {isSelected && <Check size={16} color="#d97706" strokeWidth={2} />}
                </TouchableOpacity>
              );
            })}
          </View>
        </BottomSheet>

      </ScrollView>
    </SafeAreaView>
  );
}
