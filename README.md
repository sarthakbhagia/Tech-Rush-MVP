# KaamSetu — Daily Workforce Dispatch & Operations Platform

KaamSetu (*Bridge to Work*) is a real-time daily workforce dispatch platform built for India's unorganized daily-wage market. It connects households and local businesses directly with verified daily-wage workers (painters, plumbers, cleaners, cooks, electricians, gardeners) for immediate daily jobs.

---

## The Problem & What KaamSetu Solves

### The Problem
Finding reliable daily help for short 1-day tasks (e.g. painting a living room, deep kitchen cleaning, tap repair) in Indian cities remains fragmented:
* **For Households**: Unreliable word-of-mouth recommendations, zero background verification, and arbitrary daily pricing.
* **For Workers**: Unpredictable daily work, middleman commission cuts (up to 30%), and no permanent record or reputation history.

### The Solution
KaamSetu digitizes daily labor dispatch into a clean, mobile-first experience:
1. **60-Second Dispatch**: Households create a daily job posting with task requirements and daily rates. Nearby verified workers receive notifications instantly.
2. **Dual-Mode Architecture**: Users can switch seamlessly between **Employer Mode** (posting jobs) and **Worker Mode** (finding daily work) inside the exact same app session with a single tap.
3. **Direct Connection & Verification**: Worker profiles display Aadhaar verification badges and skill tags. Phone numbers unlock once a worker is assigned to a job.
4. **Transparent Rates**: Jobs list upfront daily pay rates with zero middleman deductions.

---

## What's Built in the Repo Today

* **Product Landing Screen**: Single-line logo lockup in the top navigation bar, product headline, live trust metrics, and direct entry points to Employer and Worker feeds.
* **OTP Mobile Authentication**: Phone number authentication screen with 4-digit verification code input, countdown resend timers, and toast alert feedback.
* **Dual-Mode Dashboard**:
  * *Employer Mode*: Overview of active postings, category distribution, and job dispatch triggers.
  * *Worker Mode*: Availability status, current sector radius, and expected daily wage rate settings.
* **Job Dispatch Ledger**: Full-screen job search with real-time text query filtering, modal category selector (`BottomSheet`), and tabbed status management (`OPEN`, `ASSIGNED`, `COMPLETED`).
* **4-Stage Job Stepper**: Visual progress tracker (`Posted` → `Interested` → `Assigned` → `Completed`) with task specs, applicant worker cards, and sticky bottom action bar.
* **System Profile & Skills Management**: Worker profile editor to toggle availability (`available` / `busy`), customize skill badges via slide-up sheet, view ratings, and access compliance records.
* **Warm Dark Mode System**: Custom Tailwind design tokens (`#0b0b0c` canvas, `#151412` cards, `#262320` borders) with strict single-accent color discipline (`#d97706` gold reserved for primary CTAs, active states, and prices).

---

## Tech Stack

| Layer | Library / Tool | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | Expo (Expo Router) | `~54.0.0` / `~6.0.24` | React Native file-based navigation |
| **Language** | TypeScript | `~5.9.2` | Strict type checking (`tsc --noEmit`) |
| **Styling** | NativeWind / Tailwind CSS | `^4.2.6` / `^3.4.19` | Custom design tokens and utility classes |
| **UI Library** | React Native Paper & Primitives | `^5.15.3` | Accessible UI controls, text inputs, and bottom sheets |
| **Icons** | Lucide React Native | `^1.28.0` | Standardized icon system with uniform 2px stroke width |
| **Database & Auth** | Supabase JS Client | `^2.111.0` | PostgreSQL client with Row Level Security (RLS) |

---

## Project Structure

```
Tech-Rush-MVP/
├── app/                        # Expo Router pages
│   ├── (tabs)/                 # Main tab navigation routes
│   │   ├── index.tsx           # Home Dashboard (Employer / Worker dual view)
│   │   ├── jobs.tsx            # Job Dispatch Registry / Jobs Ledger
│   │   └── profile.tsx         # System Profile, Skills & Settings
│   ├── auth.tsx                # Mobile OTP authentication screen
│   ├── index.tsx               # Pre-Auth landing screen
│   ├── job/[id].tsx            # Detailed job view & application stepper
│   └── post-job.tsx            # Job dispatch creation modal
├── components/                 # Shared UI components
│   ├── BottomSheet.tsx         # Slide-up modal sheet with backdrop blur
│   ├── EmptyState.tsx          # Zero-data fallback component
│   ├── JobStatusStepper.tsx    # 4-stage job progress stepper
│   ├── Logo.tsx                # Brand header lockup
│   ├── ProviderCard.tsx        # Worker profile summary card
│   ├── RatingBreakdown.tsx     # Rating score and review counter
│   ├── StatusChip.tsx          # Color-coded job status badge
│   ├── StickyBottomBar.tsx     # Fixed bottom CTA bar
│   └── TrustBadgeRow.tsx       # Aadhaar & RLS compliance badges
├── constants/                  # Theme tokens and static config
├── lib/                        # Infrastructure, context, and helper libraries
│   ├── api.ts                  # Backend API abstraction layer
│   ├── context.tsx             # Global RoleContext state (Worker / Employer mode)
│   ├── supabase.ts             # Initialized Supabase client instance
│   └── ToastContext.tsx        # Toast alert system
├── supabase/
│   └── schema.sql              # Production PostgreSQL schema & RLS policies
└── tailwind.config.js          # Warm Dark Mode token definitions
```

---

## Local Setup

### 1. Installation
Clone the repository and install dependencies using Node 18+:

```bash
git clone https://github.com/your-username/Tech-Rush-MVP.git
cd Tech-Rush-MVP
npm install
```

### 2. Configure Environment (.env)
Create a `.env` file in the project root:

```env
EXPO_PUBLIC_SUPABASE_URL=https://movsaslnwjqbtdynvcwb.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 3. Run Development Server
Start the Metro bundler with Expo tunnel:

```bash
npx expo start --tunnel
```

Scan the printed QR code using the **Expo Go** app on iOS or Android.

---

## Design System

KaamSetu uses a warm dark mode theme configured in `tailwind.config.js`:
* **Background Canvas**: `#0b0b0c` (Warm dark tone instead of harsh pure black)
* **Card Surfaces**: `#151412` (Base card) and `#1c1a17` (Elevated panels)
* **Dividers & Borders**: `#262320`
* **Text**: `#f7f3ea` (Primary soft off-white) and `#a8a29a` (Muted warm gray)
* **Single-Accent Rule**: Warm amber/gold (`#d97706`) is strictly used for primary action CTAs, active tab indicators, and scannable prices/ratings.

---

## License & Status

Private / Internal Development.
