import React, { useState } from 'react';
import { View, Text, TouchableOpacity, Image } from 'react-native';
import { Heart, Star } from 'lucide-react-native';
import { cn } from '../utils/cn';

interface ServiceCardProps {
  image?: string;
  title: string;
  category: string;
  rating: number;
  reviewCount: number;
  price: number;
  originalPrice?: number;
  verified?: boolean;
  onSelect?: () => void;
  className?: string;
}

export function ServiceCard({
  image,
  title,
  category,
  rating,
  reviewCount,
  price,
  originalPrice,
  verified = true,
  onSelect,
  className,
}: ServiceCardProps) {
  const [saved, setSaved] = useState(false);

  return (
    <TouchableOpacity
      activeOpacity={0.88}
      onPress={onSelect}
      className={cn(
        'flex-row w-full gap-3 rounded-card bg-surface p-3 border border-[#3D332B] shadow-card active:scale-[0.98] mb-2.5',
        className
      )}
    >
      <View className="relative h-20 w-20 shrink-0 overflow-hidden rounded-xl bg-surface-raised items-center justify-center">
        {image ? (
          <Image source={{ uri: image }} className="h-full w-full" style={{ resizeMode: 'cover' }} />
        ) : (
          <View className="h-full w-full bg-[#2A231F] items-center justify-center">
            <Text className="text-xs font-mono text-ink-600 uppercase">{category.substring(0, 3)}</Text>
          </View>
        )}
        {verified && (
          <View className="absolute bottom-1 left-1 rounded-pill bg-surface/95 px-1.5 py-0.5 border border-[#3D332B]">
            <Text className="text-[9px] font-mono font-semibold text-brand-600">Verified</Text>
          </View>
        )}
      </View>

      <View className="flex-1 justify-between py-0.5">
        <View>
          <Text className="text-[10px] font-mono font-medium uppercase tracking-wider text-ink-600">
            {category}
          </Text>
          <Text className="text-sm font-semibold text-ink-900 mt-0.5" numberOfLines={1}>
            {title}
          </Text>
          <View className="flex-row items-center gap-1 mt-1">
            <Star size={12} color="#E5A93C" fill="#E5A93C" />
            <Text className="text-xs font-mono font-medium text-warning-600">{rating.toFixed(1)}</Text>
            <Text className="text-xs font-mono text-ink-600">({reviewCount})</Text>
          </View>
        </View>

        <View className="flex-row items-end justify-between mt-2">
          <View className="flex-row items-baseline gap-1.5">
            <Text className="text-base font-mono font-bold text-brand-600">₹{price}</Text>
            {originalPrice && (
              <Text className="text-xs font-mono text-ink-400 line-through">₹{originalPrice}</Text>
            )}
          </View>

          <TouchableOpacity
            onPress={(e) => {
              e.stopPropagation();
              setSaved((s) => !s);
            }}
            className="p-1"
          >
            <Heart size={16} color={saved ? '#D66853' : '#BAACA0'} fill={saved ? '#D66853' : 'transparent'} />
          </TouchableOpacity>
        </View>
      </View>
    </TouchableOpacity>
  );
}
