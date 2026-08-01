import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { cn } from '../utils/cn';

export interface DateSlot {
  id: string;
  label: string;
  disabled?: boolean;
  urgent?: boolean;
  scarce?: boolean;
}

interface TimeSlotPickerProps {
  slots: DateSlot[];
  selectedId?: string;
  onSelect: (id: string) => void;
  className?: string;
}

export function TimeSlotPicker({
  slots,
  selectedId,
  onSelect,
  className,
}: TimeSlotPickerProps) {
  return (
    <View className={cn('flex-row flex-wrap gap-2', className)}>
      {slots.map((slot) => {
        const active = slot.id === selectedId;
        const isUrgent = slot.urgent || slot.scarce;

        return (
          <TouchableOpacity
            key={slot.id}
            disabled={slot.disabled}
            activeOpacity={0.8}
            onPress={() => onSelect(slot.id)}
            className={cn(
              'relative rounded-control border px-3 py-2.5 items-center justify-center min-w-[30%] flex-1 transition-all active:scale-[0.96] my-1',
              active
                ? 'border-brand-600 bg-brand-50 shadow-sm'
                : 'border-[#3D332B] bg-surface hover:border-[#5E82D6]',
              slot.disabled && 'opacity-40 border-[#3D332B] bg-surface-muted'
            )}
          >
            <Text
              className={cn(
                'text-xs font-mono font-medium',
                active ? 'text-brand-600 font-bold' : slot.disabled ? 'text-ink-400' : 'text-ink-900'
              )}
            >
              {slot.label}
            </Text>

            {/* Same-day Urgent Dispatch Badge */}
            {isUrgent && !slot.disabled && (
              <View className="absolute -top-1.5 -right-1.5 rounded-pill bg-warning-600 px-1.5 py-0.5 border border-[#3D332B]">
                <Text className="text-[8px] font-mono font-bold text-white uppercase tracking-wider">
                  URGENT
                </Text>
              </View>
            )}
          </TouchableOpacity>
        );
      })}
    </View>
  );
}
