import React, { useEffect, useRef } from 'react';
import { View, Animated } from 'react-native';
import { cn } from '../utils/cn';

interface SkeletonServiceCardProps {
  className?: string;
}

export function SkeletonServiceCard({ className }: SkeletonServiceCardProps) {
  const opacityAnim = useRef(new Animated.Value(0.35)).current;

  useEffect(() => {
    const shimmerAnimation = Animated.loop(
      Animated.sequence([
        Animated.timing(opacityAnim, {
          toValue: 0.9,
          duration: 650,
          useNativeDriver: true,
        }),
        Animated.timing(opacityAnim, {
          toValue: 0.35,
          duration: 650,
          useNativeDriver: true,
        }),
      ])
    );
    shimmerAnimation.start();
    return () => shimmerAnimation.stop();
  }, [opacityAnim]);

  return (
    <View
      className={cn(
        'flex-row gap-3 rounded-card bg-surface p-3 border border-[#262320] shadow-card mb-2.5',
        className
      )}
    >
      {/* Thumbnail placeholder */}
      <Animated.View
        style={{ opacity: opacityAnim }}
        className="h-20 w-20 shrink-0 rounded-xl bg-surface-raised border border-[#262320]"
      />

      {/* Text lines placeholders */}
      <View className="flex-1 justify-between py-1">
        <View className="space-y-2">
          {/* Title line */}
          <Animated.View
            style={{ opacity: opacityAnim }}
            className="h-3.5 w-3/4 rounded bg-surface-raised"
          />
          {/* Subtitle / Category line */}
          <Animated.View
            style={{ opacity: opacityAnim }}
            className="h-3 w-1/2 rounded bg-surface-raised mt-1.5"
          />
        </View>

        {/* Price / Footer line */}
        <Animated.View
          style={{ opacity: opacityAnim }}
          className="h-3 w-1/4 rounded bg-surface-raised mt-2"
        />
      </View>
    </View>
  );
}

export function SkeletonList({ count = 4, className }: { count?: number; className?: string }) {
  return (
    <View className={cn('space-y-3', className)}>
      {Array.from({ length: count }).map((_, i) => (
        <SkeletonServiceCard key={i} />
      ))}
    </View>
  );
}
