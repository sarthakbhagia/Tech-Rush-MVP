import React from 'react';
import { View, Text } from 'react-native';
import { BadgeCheck, Fingerprint, Award } from 'lucide-react-native';
import { cn } from '../utils/cn';

interface TrustBadgeRowProps {
  className?: string;
}

const BADGES = [
  { icon: Fingerprint, label: 'Aadhaar Verified' },
  { icon: BadgeCheck, label: 'Background Checked' },
  { icon: Award, label: 'Skill Certified' },
];

export function TrustBadgeRow({ className }: TrustBadgeRowProps) {
  return (
    <View className={cn('flex-row flex-wrap gap-2', className)}>
      {BADGES.map(({ icon: Icon, label }) => (
        <View
          key={label}
          className="flex-row items-center gap-1.5 rounded-pill bg-[#10b981]/10 border border-[#10b981]/30 px-2.5 py-1"
        >
          <Icon size={12} color="#10b981" strokeWidth={2} />
          <Text className="text-[10px] font-mono font-medium text-[#10b981]">{label}</Text>
        </View>
      ))}
    </View>
  );
}
