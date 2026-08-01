import React from 'react';
import { View, Text, TouchableOpacity, Modal, Platform, TouchableWithoutFeedback } from 'react-native';
import { X } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { cn } from '../utils/cn';

let motion: any = null;
let AnimatePresence: any = null;

if (Platform.OS === 'web') {
  try {
    const FM = require('framer-motion');
    motion = FM.motion;
    AnimatePresence = FM.AnimatePresence;
  } catch (e) {}
}

interface BottomSheetProps {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  className?: string;
}

export function BottomSheet({
  open,
  onClose,
  title,
  children,
  className,
}: BottomSheetProps) {
  const insets = useSafeAreaInsets();

  if (Platform.OS === 'web' && motion && AnimatePresence) {
    return (
      <AnimatePresence>
        {open && (
          <>
            <motion.div
              className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={onClose}
            />
            <motion.div
              className={cn(
                'fixed inset-x-0 bottom-0 z-50 rounded-t-3xl bg-surface border-t border-[#262320] p-5 shadow-floating max-w-lg mx-auto',
                className
              )}
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ type: 'spring', damping: 30, stiffness: 300 }}
              drag="y"
              dragConstraints={{ top: 0 }}
              dragElastic={0.2}
              onDragEnd={(_: any, info: any) => info.offset.y > 100 && onClose()}
            >
              <div className="mx-auto mb-3 h-1.5 w-10 rounded-pill bg-[#262320] cursor-grab active:cursor-grabbing" />
              
              <div className="flex items-center justify-between pb-3 border-b border-[#262320]">
                <h3 className="text-base font-bold text-ink-900">{title}</h3>
                <button
                  onClick={onClose}
                  className="rounded-lg p-1.5 bg-[#1c1a17] border border-[#262320] hover:bg-[#262320] transition-colors"
                >
                  <X size={16} color="#a8a29a" strokeWidth={2} />
                </button>
              </div>

              <div className="mt-4 pb-[max(env(safe-area-inset-bottom),16px)]">{children}</div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    );
  }

  return (
    <Modal visible={open} transparent animationType="slide" onRequestClose={onClose}>
      <TouchableWithoutFeedback onPress={onClose}>
        <View className="flex-1 bg-black/60 justify-end">
          <TouchableWithoutFeedback>
            <View
              className={cn(
                'bg-surface border-t border-[#262320] rounded-t-3xl px-5 pt-3 shadow-floating',
                className
              )}
              style={{ paddingBottom: Math.max(insets.bottom, 20) }}
            >
              <View className="w-10 h-1.5 rounded-pill bg-[#262320] self-center mb-3" />

              <View className="flex-row items-center justify-between pb-3 border-b border-[#262320] mb-4">
                <Text className="text-base font-bold text-ink-900">{title}</Text>
                <TouchableOpacity
                  onPress={onClose}
                  className="p-1.5 rounded-lg bg-surface-raised border border-[#262320]"
                >
                  <X size={16} color="#a8a29a" strokeWidth={2} />
                </TouchableOpacity>
              </View>

              <View>{children}</View>
            </View>
          </TouchableWithoutFeedback>
        </View>
      </TouchableWithoutFeedback>
    </Modal>
  );
}

export function DemoBottomSheetTrigger() {
  const [open, setOpen] = React.useState(false);

  return (
    <View className="p-4">
      <TouchableOpacity
        onPress={() => setOpen(true)}
        className="bg-brand-600 py-3 px-5 rounded-control items-center"
      >
        <Text className="text-white font-mono font-semibold text-xs">
          Open Demo Bottom Sheet
        </Text>
      </TouchableOpacity>

      <BottomSheet
        open={open}
        onClose={() => setOpen(false)}
        title="Filter Job Dispatches"
      >
        <View className="space-y-3 py-2">
          <Text className="text-xs font-mono text-ink-600">Select Category Filter:</Text>
          <View className="flex-row flex-wrap gap-2">
            {['All', 'Cleaning', 'Plumbing', 'Painting', 'Gardening'].map((cat) => (
              <TouchableOpacity
                key={cat}
                onPress={() => setOpen(false)}
                className="px-3 py-2 rounded-control bg-surface-raised border border-[#262320]"
              >
                <Text className="text-xs font-mono text-ink-900">{cat}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>
      </BottomSheet>
    </View>
  );
}
