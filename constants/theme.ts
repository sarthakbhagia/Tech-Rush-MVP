import { MD3DarkTheme } from 'react-native-paper';

export const COLORS = {
  canvas: '#0b0b0c',        // Warm Dark Background: #0b0b0c
  surface: '#151412',       // Surface Card: #151412
  surfaceRaised: '#1c1a17', // Surface Tier 2 / Active: #1c1a17
  border: '#262320',        // Warm Hairline Border: #262320
  
  textPrimary: '#f7f3ea',   // Primary Soft Off-White Text: #f7f3ea
  textMuted: '#a8a29a',     // Muted Warm Gray Text: #a8a29a
  
  primary: '#d97706',       // Base Warm Amber/Gold Brand: #d97706
  primarySubtle: 'rgba(217, 119, 6, 0.12)',
  
  statusAmber: '#f59e0b',   // Distinct Warning Amber: #f59e0b
  statusSage: '#10b981',    // Emerald Success: #10b981
  statusClay: '#dc2626',    // Warm Red Error: #dc2626
};

export const paperTheme = {
  ...MD3DarkTheme,
  colors: {
    ...MD3DarkTheme.colors,
    primary: COLORS.primary,
    onPrimary: '#FFFFFF',
    primaryContainer: COLORS.surfaceRaised,
    onPrimaryContainer: COLORS.textPrimary,
    secondary: COLORS.primary,
    onSecondary: '#FFFFFF',
    background: COLORS.canvas,
    surface: COLORS.surface,
    surfaceVariant: COLORS.surfaceRaised,
    onSurface: COLORS.textPrimary,
    onSurfaceVariant: COLORS.textMuted,
    outline: COLORS.border,
  },
  roundness: 12,
};
