import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';
import { Platform } from 'react-native';

// SSR-safe storage adapter for Supabase & AsyncStorage
const customStorage = {
  getItem: async (key: string) => {
    if (Platform.OS === 'web' && typeof window === 'undefined') {
      return null;
    }
    return await AsyncStorage.getItem(key);
  },
  setItem: async (key: string, value: string) => {
    if (Platform.OS === 'web' && typeof window === 'undefined') {
      return;
    }
    await AsyncStorage.setItem(key, value);
  },
  removeItem: async (key: string) => {
    if (Platform.OS === 'web' && typeof window === 'undefined') {
      return;
    }
    await AsyncStorage.removeItem(key);
  },
};

// Environment variables from Expo with live Supabase project fallbacks
const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || 'https://movsaslnwjqbtdynvcwb.supabase.co';
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vdnNhc2xud2pxYnRkeW52Y3diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU1Nzg0MDMsImV4cCI6MjEwMTE1NDQwM30.PkZFCfw5OhwGGNYf_FY-yBiUEm60QAZtSXNb5_2A4vs';

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: customStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
