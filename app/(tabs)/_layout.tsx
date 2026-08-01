import React from 'react';
import { View, TouchableOpacity } from 'react-native';
import { Tabs } from 'expo-router';
import { LayoutDashboard, Briefcase, User } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRole } from '../../lib/context';

export default function TabLayout() {
  const { role } = useRole();
  const insets = useSafeAreaInsets();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#d97706',
        tabBarInactiveTintColor: '#a8a29a',
        tabBarStyle: {
          backgroundColor: '#151412',
          borderTopWidth: 1,
          borderTopColor: '#262320',
          height: 60 + Math.max(insets.bottom, 12),
          paddingBottom: Math.max(insets.bottom, 10),
          paddingTop: 8,
          elevation: 12,
          shadowColor: '#0b0b0c',
          shadowOffset: { width: 0, height: -4 },
          shadowOpacity: 0.5,
          shadowRadius: 10,
        },
        tabBarLabelStyle: {
          fontSize: 10,
          fontWeight: '600',
          fontFamily: 'monospace',
          marginTop: 2,
        },
        tabBarButton: (props) => (
          <TouchableOpacity
            {...(props as any)}
            activeOpacity={0.7}
            className="flex-1 items-center justify-center active:scale-[0.94] transition-transform"
          />
        ),
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Dashboard',
          tabBarIcon: ({ color, focused }) => (
            <View className="items-center justify-center">
              {focused && (
                <View className="w-5 h-1 rounded-full bg-brand-600 mb-1" />
              )}
              <LayoutDashboard size={20} color={color} strokeWidth={2} />
            </View>
          ),
        }}
      />
      <Tabs.Screen
        name="jobs"
        options={{
          title: role === 'worker' ? 'Available Jobs' : 'Job Postings',
          tabBarIcon: ({ color, focused }) => (
            <View className="items-center justify-center">
              {focused && (
                <View className="w-5 h-1 rounded-full bg-brand-600 mb-1" />
              )}
              <Briefcase size={20} color={color} strokeWidth={2} />
            </View>
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'System Profile',
          tabBarIcon: ({ color, focused }) => (
            <View className="items-center justify-center">
              {focused && (
                <View className="w-5 h-1 rounded-full bg-brand-600 mb-1" />
              )}
              <User size={20} color={color} strokeWidth={2} />
            </View>
          ),
        }}
      />
    </Tabs>
  );
}
