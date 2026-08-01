import React, { useEffect, useRef } from 'react';
import { View, Animated } from 'react-native';

export const SkeletonCard: React.FC = () => {
  const fadeAnim = useRef(new Animated.Value(0.3)).current;

  useEffect(() => {
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(fadeAnim, {
          toValue: 0.8,
          duration: 700,
          useNativeDriver: true,
        }),
        Animated.timing(fadeAnim, {
          toValue: 0.3,
          duration: 700,
          useNativeDriver: true,
        }),
      ])
    );
    animation.start();
    return () => animation.stop();
  }, [fadeAnim]);

  return (
    <Animated.View
      style={{ opacity: fadeAnim }}
      className="p-4 rounded-xl bg-[#1F1A17] border border-[#3D332B] mb-2.5"
    >
      <View className="flex-row items-center justify-between mb-3">
        <View className="flex-row items-center gap-2">
          <View className="w-14 h-5 rounded bg-[#3D332B]" />
          <View className="w-20 h-4 rounded bg-[#3D332B]" />
        </View>
        <View className="w-16 h-5 rounded bg-[#3D332B]" />
      </View>

      <View className="w-3/4 h-5 rounded bg-[#3D332B] mb-3" />

      <View className="flex-row items-center justify-between pt-2 border-t border-[#3D332B]">
        <View className="w-28 h-4 rounded bg-[#3D332B]" />
        <View className="w-16 h-4 rounded bg-[#3D332B]" />
      </View>
    </Animated.View>
  );
};

export const SkeletonList: React.FC<{ count?: number }> = ({ count = 3 }) => {
  return (
    <View className="space-y-2">
      {Array.from({ length: count }).map((_, i) => (
        <SkeletonCard key={i} />
      ))}
    </View>
  );
};
