/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,jsx,ts,tsx}",
    "./components/**/*.{js,jsx,ts,tsx}",
    "./screens/**/*.{js,jsx,ts,tsx}",
    "./utils/**/*.{js,jsx,ts,tsx}",
  ],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        // Warm Dark Mode Semantic Palette
        canvas: "#0b0b0c",               // Background: #0b0b0c
        surface: {
          DEFAULT: "#151412",           // Surface: #151412
          muted: "#0b0b0c",             // Background canvas alias
          raised: "#1c1a17",            // Lighter elevation tier 2: #1c1a17
          2: "#1c1a17",                 // Alias for surface-2
        },
        border: {
          DEFAULT: "#262320",           // Border/hairline: #262320
          hairline: "#262320",
        },
        ink: {
          DEFAULT: "#f7f3ea",
          900: "#f7f3ea",               // Primary text: #f7f3ea (soft off-white)
          primary: "#f7f3ea",
          600: "#a8a29a",               // Muted/secondary text: #a8a29a (warm gray)
          muted: "#a8a29a",
          400: "#78726a",               // De-emphasized caption text
        },
        brand: {
          DEFAULT: "#d97706",           // Base brand accent: #d97706 (warm gold/amber)
          600: "#d97706",
          500: "#f59e0b",               // Lighter / active state: #f59e0b
          light: "#f59e0b",
          50: "rgba(217, 119, 6, 0.12)", // Subtle warm fill
        },
        success: {
          100: "rgba(16, 185, 129, 0.12)",
          600: "#10b981",               // Success emerald: #10b981
        },
        warning: {
          100: "rgba(245, 158, 11, 0.12)",
          600: "#f59e0b",               // Visually distinct warning amber: #f59e0b
        },
        danger: {
          100: "rgba(220, 38, 38, 0.12)",
          600: "#dc2626",               // Warm-leaning red error: #dc2626
        },
        // Direct aliases
        primary: {
          DEFAULT: "#d97706",
          hover: "#f59e0b",
          subtle: "rgba(217, 119, 6, 0.12)",
        },
      },
      borderRadius: {
        card: "16px",
        pill: "999px",
        control: "12px",
        xl: "12px",
        DEFAULT: "12px",
      },
      boxShadow: {
        // Subtle warm-tinted shadows
        card: "0 1px 3px rgba(11, 11, 12, 0.6), 0 4px 12px rgba(38, 35, 32, 0.35)",
        floating: "0 8px 24px rgba(11, 11, 12, 0.75)",
      },
      fontFamily: {
        heading: ["Sora", "sans-serif"],
        body: ["Inter", "sans-serif"],
        mono: ["Space Mono", "Courier", "monospace"],
      },
    },
  },
  plugins: [],
};
