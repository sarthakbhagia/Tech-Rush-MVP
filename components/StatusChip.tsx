import React, { useEffect, useRef } from 'react';
import { View, Text, Animated } from 'react-native';
import { cn } from '../utils/cn';

export type JobStatus = 'OPEN' | 'ASSIGNED' | 'COMPLETED' | 'INTERESTED' | 'open' | 'assigned' | 'completed' | 'interested';

interface StatusChipProps {
  status: JobStatus;
  labelOverride?: string;
  className?: string;
}

interface StatusStyleConfig {
  label: string;
  bg: string;
  border: string;
  text: string;
  pulseBg: string;
  pulse: boolean;
}

const STATUS_CONFIG: Record<string, StatusStyleConfig> = {
  open: {
    label: 'OPEN',
    bg: 'bg-warning-100',
    border: 'border-[#f59e0b]/40',
    text: 'text-warning-600',
    pulseBg: 'bg-[#f59e0b]',
    pulse: true,
  },
  interested: {
    label: 'INTERESTED',
    bg: 'bg-brand-50',
    border: 'border-[#d97706]/40',
    text: 'text-brand-600',
    pulseBg: 'bg-[#d97706]',
    pulse: true,
  },
  assigned: {
    label: 'ASSIGNED',
    bg: 'bg-brand-50',
    border: 'border-[#d97706]/40',
    text: 'text-brand-600',
    pulseBg: 'bg-[#d97706]',
    pulse: true,
  },
  completed: {
    label: 'COMPLETED',
    bg: 'bg-success-100',
    border: 'border-[#10b981]/40',
    text: 'text-success-600',
    pulseBg: 'bg-[#10b981]',
    pulse: false,
  },
};

export function StatusChip({ status, labelOverride, className }: StatusChipProps) {
  const normalizedKey = status.toLowerCase();
  const config = STATUS_CONFIG[normalizedKey] || STATUS_CONFIG.open;
  const label = labelOverride || config.label;

  const pulseAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    if (config.pulse) {
      const animation = Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 0.35,
            duration: 750,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 750,
            useNativeDriver: true,
          }),
        ])
      );
      animation.start();
      return () => animation.stop();
    }
  }, [config.pulse, pulseAnim]);

  return (
    <View
      className={cn(
        'flex-row items-center px-2.5 py-1 rounded-pill border',
        config.bg,
        config.border,
        className
      )}
    >
      {config.pulse && (
        <View className="mr-1.5 flex-row items-center justify-center relative w-2 h-2">
          <Animated.View
            style={{ opacity: pulseAnim }}
            className={cn('absolute w-2 h-2 rounded-full', config.pulseBg)}
          />
          <View className={cn('w-1.5 h-1.5 rounded-full', config.pulseBg)} />
        </View>
      )}
      <Text className={cn('text-[10px] font-mono font-bold tracking-wider uppercase', config.text)}>
        {label}
      </Text>
    </View>
  );
}
