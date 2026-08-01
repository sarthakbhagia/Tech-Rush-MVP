import React, { createContext, useContext, useState, useCallback, useRef, useEffect } from 'react';
import { View, Text, Animated, TouchableOpacity } from 'react-native';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

export type ToastType = 'success' | 'warning' | 'error' | 'info';

interface ToastMessage {
  id: string;
  title: string;
  message?: string;
  type: ToastType;
}

interface ToastContextType {
  showToast: (title: string, message?: string, type?: ToastType) => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toast, setToast] = useState<ToastMessage | null>(null);
  const insets = useSafeAreaInsets();
  const slideAnim = useRef(new Animated.Value(-100)).current;

  const showToast = useCallback((title: string, message?: string, type: ToastType = 'success') => {
    const id = Math.random().toString();
    setToast({ id, title, message, type });
  }, []);

  const hideToast = useCallback(() => {
    Animated.timing(slideAnim, {
      toValue: -100,
      duration: 250,
      useNativeDriver: true,
    }).start(() => setToast(null));
  }, [slideAnim]);

  useEffect(() => {
    if (toast) {
      slideAnim.setValue(-100);
      Animated.spring(slideAnim, {
        toValue: Math.max(insets.top, 16) + 8,
        useNativeDriver: true,
        damping: 18,
        stiffness: 200,
      }).start();

      const timer = setTimeout(() => {
        hideToast();
      }, 3500);

      return () => clearTimeout(timer);
    }
  }, [toast, insets.top, slideAnim, hideToast]);

  const getStyleForType = (type: ToastType) => {
    switch (type) {
      case 'success':
        return {
          border: 'border-[#10b981]/40',
          bg: 'bg-surface',
          text: 'text-success-600',
          icon: <CheckCircle2 size={18} color="#10b981" strokeWidth={2} />,
        };
      case 'warning':
        return {
          border: 'border-[#f59e0b]/40',
          bg: 'bg-surface',
          text: 'text-warning-600',
          icon: <AlertCircle size={18} color="#f59e0b" strokeWidth={2} />,
        };
      case 'error':
        return {
          border: 'border-[#dc2626]/40',
          bg: 'bg-surface',
          text: 'text-danger-600',
          icon: <AlertCircle size={18} color="#dc2626" strokeWidth={2} />,
        };
      case 'info':
      default:
        return {
          border: 'border-[#d97706]/40',
          bg: 'bg-surface',
          text: 'text-brand-600',
          icon: <Info size={18} color="#d97706" strokeWidth={2} />,
        };
    }
  };

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}

      {toast && (
        <Animated.View
          style={{
            transform: [{ translateY: slideAnim }],
          }}
          className="absolute inset-x-5 z-50 self-center max-w-md"
        >
          {(() => {
            const config = getStyleForType(toast.type);
            return (
              <View
                className={`p-3.5 rounded-card ${config.bg} border ${config.border} shadow-floating flex-row items-start justify-between gap-3`}
              >
                <View className="flex-row items-start gap-2.5 flex-1">
                  <View className="mt-0.5">{config.icon}</View>
                  <View className="flex-1">
                    <Text className={`text-xs font-mono font-bold ${config.text}`}>
                      {toast.title}
                    </Text>
                    {toast.message && (
                      <Text className="text-xs text-ink-900 mt-0.5 leading-4">
                        {toast.message}
                      </Text>
                    )}
                  </View>
                </View>

                <TouchableOpacity onPress={hideToast} className="p-1">
                  <X size={14} color="#a8a29a" strokeWidth={2} />
                </TouchableOpacity>
              </View>
            );
          })()}
        </Animated.View>
      )}
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
}
