import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { cn } from '../utils/cn';

export interface StickyBottomBarProps {
  label?: string;
  price?: number | string;
  ctaLabel: string;
  onCta: () => void;
  disabled?: boolean;
  icon?: React.ReactNode;
  className?: string;
}

export function StickyBottomBar({
  label = 'DAILY WAGE RATE',
  price,
  ctaLabel,
  onCta,
  disabled = false,
  icon,
  className,
}: StickyBottomBarProps) {
  const insets = useSafeAreaInsets();

  return (
    <View
      className={cn(
        'absolute inset-x-0 bottom-0 z-40 border-t border-[#262320] bg-surface px-5 pt-3 shadow-floating',
        className
      )}
      style={{
        paddingBottom: Math.max(insets.bottom, 12),
      }}
    >
      <View className="flex-row items-center justify-between gap-3">
        {price !== undefined && (
          <View className="pr-2">
            {label && (
              <Text className="text-[10px] font-mono font-medium text-ink-600 uppercase tracking-wider">
                {label}
              </Text>
            )}
            <Text className="text-xl font-mono font-bold text-brand-600">
              {typeof price === 'number' ? `₹${price.toLocaleString()}` : price}
            </Text>
          </View>
        )}

        <TouchableOpacity
          activeOpacity={0.85}
          disabled={disabled}
          onPress={onCta}
          className={cn(
            'flex-1 h-12 rounded-control flex-row items-center justify-center border border-brand-600 transition-transform active:scale-[0.97]',
            disabled ? 'bg-brand-600/50 border-transparent' : 'bg-brand-600'
          )}
        >
          {icon && <View className="mr-2">{icon}</View>}
          <Text className="text-white font-semibold text-sm">{ctaLabel}</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}
