import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { cn } from '../utils/cn';

interface EmptyStateProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
  className?: string;
}

export function EmptyState({
  icon,
  title,
  description,
  actionLabel,
  onAction,
  className,
}: EmptyStateProps) {
  return (
    <View
      className={cn(
        'items-center justify-center py-10 px-6 border border-dashed border-[#262320] rounded-card bg-surface/50 my-2',
        className
      )}
    >
      {/* Icon Badge Container */}
      <View className="w-14 h-14 rounded-full bg-surface-raised items-center justify-center mb-3 border border-[#262320]">
        {icon}
      </View>

      {/* Heading */}
      <Text className="text-base font-bold text-ink-900 text-center mb-1">
        {title}
      </Text>

      {/* One-Line / Short Explanation */}
      <Text className="text-xs text-ink-600 text-center leading-5 mb-4 max-w-[280px]">
        {description}
      </Text>

      {/* Optional Action Button */}
      {actionLabel && onAction && (
        <TouchableOpacity
          activeOpacity={0.85}
          onPress={onAction}
          className="bg-brand-600/10 border border-brand-600 px-4 py-2 rounded-control active:scale-[0.98]"
        >
          <Text className="text-xs font-mono font-bold text-brand-600">{actionLabel}</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}
