import React from 'react';
import { View, Text } from 'react-native';
import { Layers } from 'lucide-react-native';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  showSubtitle?: boolean;
  variant?: 'centered' | 'header';
}

export const Logo: React.FC<LogoProps> = ({
  size = 'md',
  showSubtitle = true,
  variant = 'centered',
}) => {
  if (variant === 'header') {
    return (
      <View className="flex-row items-center gap-2">
        <View className="w-8 h-8 rounded-control bg-surface border border-[#262320] items-center justify-center shadow-card">
          <Layers size={18} color="#d97706" strokeWidth={2} />
        </View>
        <View className="flex-row items-center">
          <Text className="text-base font-bold text-ink-900 tracking-tight">Kaam</Text>
          <Text className="text-base font-bold text-brand-600 tracking-tight">Setu</Text>
          <Text className="text-[9px] font-mono text-ink-600 ml-1.5 px-1 py-0.5 rounded bg-surface-raised border border-[#262320]">
            OPS
          </Text>
        </View>
      </View>
    );
  }

  const textSize = size === 'sm' ? 'text-lg' : size === 'md' ? 'text-2xl' : 'text-3xl';
  
  return (
    <View className="items-center">
      {/* Brand Icon Badge */}
      <View className="bg-surface w-14 h-14 rounded-card items-center justify-center border border-[#262320] shadow-card mb-3">
        <Layers size={28} color="#d97706" strokeWidth={2} />
      </View>

      {/* Brand Title */}
      <View className="flex-row items-center">
        <Text className={`${textSize} font-bold text-ink-900 tracking-tight`}>Kaam</Text>
        <Text className={`${textSize} font-bold text-brand-600 tracking-tight`}>Setu</Text>
        <Text className="text-[10px] font-mono text-ink-600 ml-1.5 px-1.5 py-0.5 rounded-control bg-surface-raised border border-[#262320]">
          OPS v1.0
        </Text>
      </View>

      {/* Subtitle */}
      {showSubtitle && (
        <Text className="text-xs text-ink-600 font-medium tracking-wide mt-1.5 text-center">
          Daily Workforce Dispatch & Operations System
        </Text>
      )}
    </View>
  );
};
