import React from 'react';
import { View, Text } from 'react-native';
import { Star } from 'lucide-react-native';
import { cn } from '../utils/cn';

export type RatingRow = { stars: number; pct: number };

interface RatingBreakdownProps {
  average: number;
  total: number;
  rows?: RatingRow[];
  className?: string;
}

const DEFAULT_ROWS: RatingRow[] = [
  { stars: 5, pct: 82 },
  { stars: 4, pct: 12 },
  { stars: 3, pct: 4 },
  { stars: 2, pct: 1 },
  { stars: 1, pct: 1 },
];

export function RatingBreakdown({
  average,
  total,
  rows = DEFAULT_ROWS,
  className,
}: RatingBreakdownProps) {
  return (
    <View className={cn('rounded-card border border-[#262320] bg-surface p-4 shadow-card', className)}>
      {/* Header average */}
      <View className="flex-row items-baseline gap-2 mb-3">
        <Text className="text-3xl font-mono font-bold text-ink-900">{average.toFixed(1)}</Text>
        <View className="flex-row items-center gap-1">
          <Star size={14} color="#f59e0b" fill="#f59e0b" />
          <Text className="text-xs font-mono text-ink-600">
            ({total.toLocaleString()} verified reviews)
          </Text>
        </View>
      </View>

      {/* Distribution bars */}
      <View className="space-y-2">
        {rows.map((r) => (
          <View key={r.stars} className="flex-row items-center gap-2 my-0.5">
            <Text className="w-6 font-mono text-xs text-ink-600">{r.stars}★</Text>
            <View className="h-1.5 flex-1 overflow-hidden rounded-pill bg-surface-raised border border-[#262320]">
              <View
                className="h-full rounded-pill bg-brand-600"
                style={{ width: `${r.pct}%` }}
              />
            </View>
            <Text className="w-8 font-mono text-[10px] text-ink-600 text-right">{r.pct}%</Text>
          </View>
        ))}
      </View>
    </View>
  );
}
