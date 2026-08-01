import React from 'react';
import { View, Text } from 'react-native';
import { Check } from 'lucide-react-native';

export type JobStage = 'posted' | 'interested' | 'assigned' | 'completed';

interface JobStatusStepperProps {
  currentStage: JobStage;
}

const STAGES: { key: JobStage; label: string }[] = [
  { key: 'posted', label: 'Posted' },
  { key: 'interested', label: 'Interested' },
  { key: 'assigned', label: 'Assigned' },
  { key: 'completed', label: 'Completed' },
];

export const JobStatusStepper: React.FC<JobStatusStepperProps> = ({ currentStage }) => {
  const stageIndexMap: Record<JobStage, number> = {
    posted: 0,
    interested: 1,
    assigned: 2,
    completed: 3,
  };

  const currentIndex = stageIndexMap[currentStage] ?? 0;
  const fillPercentage = (currentIndex / (STAGES.length - 1)) * 88;

  return (
    <View className="bg-surface p-4 rounded-card border border-[#262320] shadow-card mb-5">
      <View className="flex-row items-center justify-between relative px-2">
        
        {/* Background Connecting Line */}
        <View className="absolute left-6 right-6 top-3.5 h-[2px] bg-[#262320]" />
        
        {/* Active Stage Proportionally Filled Progress Bar */}
        <View
          className="absolute left-6 top-3.5 h-[2px] bg-brand-600 transition-all duration-300"
          style={{
            width: `${fillPercentage}%`,
          }}
        />

        {/* Stage Nodes */}
        {STAGES.map((stage, idx) => {
          const isPassed = idx < currentIndex;
          const isCurrent = idx === currentIndex;
          const isFuture = idx > currentIndex;

          return (
            <View key={stage.key} className="items-center z-10">
              <View
                className={`w-7 h-7 rounded-full items-center justify-center border transition-all ${
                  isPassed
                    ? 'bg-success-600 border-success-600'
                    : isCurrent
                    ? 'bg-brand-600 border-brand-600 shadow-sm'
                    : 'bg-surface border-[#262320]'
                }`}
              >
                {isPassed ? (
                  <Check size={14} color="#FFFFFF" strokeWidth={2.5} />
                ) : isCurrent ? (
                  <Check size={14} color="#FFFFFF" strokeWidth={2.5} />
                ) : (
                  <Text className="text-[10px] font-mono text-ink-600 font-bold">
                    0{idx + 1}
                  </Text>
                )}
              </View>

              <Text
                className={`text-[11px] font-mono mt-2 font-medium ${
                  isCurrent
                    ? 'text-brand-600 font-bold'
                    : isPassed
                    ? 'text-success-600'
                    : 'text-ink-600'
                }`}
              >
                {stage.label}
              </Text>
            </View>
          );
        })}

      </View>
    </View>
  );
};
