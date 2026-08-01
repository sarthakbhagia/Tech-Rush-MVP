import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';
import { UserRole } from '../types';

interface RoleContextType {
  role: UserRole;
  setRole: (role: UserRole) => Promise<void>;
  isLoading: boolean;
}

const RoleContext = createContext<RoleContextType>({
  role: 'household',
  setRole: async () => {},
  isLoading: true,
});

const ROLE_STORAGE_KEY = '@kaamsetu_user_role';

export const RoleProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [role, setRoleState] = useState<UserRole>('household');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (Platform.OS === 'web' && typeof window === 'undefined') {
      setIsLoading(false);
      return;
    }
    // Load persisted role preference
    AsyncStorage.getItem(ROLE_STORAGE_KEY)
      .then((savedRole) => {
        if (savedRole === 'worker' || savedRole === 'household') {
          setRoleState(savedRole);
        }
      })
      .catch((err) => console.error('Failed to load stored role', err))
      .finally(() => setIsLoading(false));
  }, []);

  const setRole = async (newRole: UserRole) => {
    setRoleState(newRole);
    if (Platform.OS === 'web' && typeof window === 'undefined') {
      return;
    }
    try {
      await AsyncStorage.setItem(ROLE_STORAGE_KEY, newRole);
    } catch (err) {
      console.error('Failed to save role', err);
    }
  };

  return (
    <RoleContext.Provider value={{ role, setRole, isLoading }}>
      {children}
    </RoleContext.Provider>
  );
};

export const useRole = () => useContext(RoleContext);
