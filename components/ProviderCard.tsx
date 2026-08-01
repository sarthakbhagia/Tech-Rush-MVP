import React from 'react';
import { View, Text, TouchableOpacity, Linking, Alert } from 'react-native';
import { Avatar } from 'react-native-paper';
import { ShieldCheck, Star, Phone, MessageSquare, CheckCircle2 } from 'lucide-react-native';
import { cn } from '../utils/cn';

interface WorkerProviderCardProps {
  name: string;
  primarySkill?: string;
  skills?: string[];
  dailyRate?: number;
  wage?: number;
  rating: number;
  jobsCompleted: number;
  reviewsCount?: number;
  phone?: string;
  isVerified?: boolean;
  isAssigned?: boolean;
  onHire?: () => void;
  onCall?: () => void;
  onMessage?: () => void;
  className?: string;
}

export function ProviderCard({
  name,
  primarySkill = 'Painting Pro',
  skills = ['Painting', 'Plumbing'],
  dailyRate,
  wage,
  rating,
  jobsCompleted,
  reviewsCount = 24,
  phone = '+91 98765 43210',
  isVerified = true,
  isAssigned = false,
  onHire,
  onCall,
  onMessage,
  className,
}: WorkerProviderCardProps) {
  const effectiveRate = dailyRate ?? wage ?? 650;
  const handleCall = () => {
    if (onCall) {
      onCall();
    } else {
      Linking.openURL(`tel:${phone.replace(/\s+/g, '')}`).catch(() => {
        Alert.alert('Phone Call', `Dialing ${name} (${phone})`);
      });
    }
  };

  const handleMessage = () => {
    if (onMessage) {
      onMessage();
    } else {
      Linking.openURL(`sms:${phone.replace(/\s+/g, '')}`).catch(() => {
        Alert.alert('Message', `Sending SMS to ${name} (${phone})`);
      });
    }
  };

  const initials = name
    .split(' ')
    .map((n) => n[0])
    .join('');

  return (
    <View
      className={cn(
        'p-3.5 rounded-card bg-surface border border-[#262320] shadow-card mb-2.5',
        isAssigned && 'border-[#10b981] bg-[#10b981]/10',
        className
      )}
    >
      {/* Header Info */}
      <View className="flex-row items-start justify-between mb-2">
        <View className="flex-row items-center flex-1 pr-2">
          <Avatar.Text
            size={42}
            label={initials}
            style={{ backgroundColor: '#1c1a17', borderColor: '#262320', borderWidth: 1 }}
            color="#f7f3ea"
          />
          <View className="ml-3 flex-1">
            <View className="flex-row items-center gap-1.5">
              <Text className="text-sm font-bold text-ink-900">{name}</Text>
              {isVerified && <ShieldCheck size={14} color="#10b981" strokeWidth={2} />}
            </View>

            <Text className="text-[11px] font-mono text-ink-600 mt-0.5">{primarySkill}</Text>

            <View className="flex-row items-center mt-1">
              <Star size={11} color="#f59e0b" fill="#f59e0b" />
              <Text className="text-xs font-mono font-bold text-warning-600 ml-1">
                {rating.toFixed(1)}
              </Text>
              <Text className="text-xs font-mono text-ink-600 ml-1">
                ({jobsCompleted} jobs completed)
              </Text>
            </View>
          </View>
        </View>

        {effectiveRate !== undefined && (
          <View className="items-end bg-surface-raised px-2.5 py-1 rounded-control border border-[#262320]">
            <Text className="text-sm font-mono font-bold text-brand-600">₹{effectiveRate}</Text>
            <Text className="text-[8px] font-mono text-ink-600">/ DAY RATE</Text>
          </View>
        )}
      </View>

      {/* Skill Badges */}
      {skills.length > 0 && (
        <View className="flex-row flex-wrap gap-1 mb-3 mt-1">
          {skills.map((skill) => (
            <View key={skill} className="px-2 py-0.5 rounded-control bg-surface-raised border border-[#262320]">
              <Text className="text-[10px] font-mono text-ink-600">{skill}</Text>
            </View>
          ))}
        </View>
      )}

      {/* Worker Actions */}
      {isAssigned ? (
        <View className="bg-success-100 p-2.5 rounded-control border border-[#10b981]/40 flex-row flex-wrap items-center justify-between gap-2 mt-1">
          <View className="flex-row items-center">
            <CheckCircle2 size={16} color="#10b981" strokeWidth={2} />
            <Text className="text-xs font-mono font-bold text-[#10b981] ml-1.5">WORKER ASSIGNED</Text>
          </View>

          <View className="flex-row items-center gap-2">
            <TouchableOpacity
              onPress={handleMessage}
              className="bg-surface-raised border border-[#262320] p-2 rounded-lg"
            >
              <MessageSquare size={14} color="#f7f3ea" strokeWidth={2} />
            </TouchableOpacity>

            <TouchableOpacity
              onPress={handleCall}
              className="bg-success-600 px-2.5 py-1.5 rounded-lg flex-row items-center"
            >
              <Phone size={12} color="#FFFFFF" strokeWidth={2} />
              <Text className="text-white text-[10px] font-mono font-bold ml-1">{phone}</Text>
            </TouchableOpacity>
          </View>
        </View>
      ) : (
        <View className="flex-row items-center justify-between gap-2 mt-1">
          <View className="flex-row items-center gap-2">
            <TouchableOpacity
              onPress={handleMessage}
              className="bg-surface-raised border border-[#262320] p-2.5 rounded-control active:scale-[0.97]"
            >
              <MessageSquare size={14} color="#a8a29a" strokeWidth={2} />
            </TouchableOpacity>

            <TouchableOpacity
              onPress={handleCall}
              className="bg-surface-raised border border-[#262320] p-2.5 rounded-control active:scale-[0.97]"
            >
              <Phone size={14} color="#a8a29a" strokeWidth={2} />
            </TouchableOpacity>
          </View>

          {onHire ? (
            <TouchableOpacity
              activeOpacity={0.85}
              onPress={onHire}
              className="bg-brand-600 py-2 px-4 rounded-control flex-1 items-center border border-brand-600 active:scale-[0.98]"
            >
              <Text className="text-white font-mono text-xs font-semibold">Assign & Dispatch Job</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity
              activeOpacity={0.85}
              onPress={handleCall}
              className="bg-brand-600 py-2 px-4 rounded-control flex-1 items-center border border-brand-600 flex-row justify-center active:scale-[0.98]"
            >
              <Phone size={12} color="#FFFFFF" strokeWidth={2} className="mr-1.5" />
              <Text className="text-white font-mono text-xs font-semibold ml-1">Contact Worker</Text>
            </TouchableOpacity>
          )}
        </View>
      )}
    </View>
  );
}
