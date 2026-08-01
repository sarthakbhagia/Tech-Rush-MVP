// TypeScript definitions for KaamSetu

export type UserRole = 'worker' | 'household';

export type AvailabilityStatus = 'available' | 'busy';

export type JobStatus = 'open' | 'assigned' | 'completed' | 'cancelled';

export type InterestStatus = 'pending' | 'selected' | 'not_selected';

export type RatingValue = 'up' | 'down';

export interface Profile {
  id: string;
  name: string;
  phone?: string | null;
  role: UserRole;
  photo_url?: string | null;
  created_at: string;
}

export interface WorkerProfile {
  id: string;
  skills: string[];
  expected_wage: number;
  availability: AvailabilityStatus;
  bio?: string | null;
  rating_avg: number;
  rating_count: number;
  location?: string | null;
  // Joined relation option
  profile?: Profile;
}

export interface Job {
  id: string;
  household_id: string;
  title: string;
  description?: string | null;
  category: string;
  location: string;
  budget: number;
  job_date: string;
  status: JobStatus;
  assigned_worker_id?: string | null;
  created_at: string;
  // Joined relations options
  household?: Profile;
  assigned_worker?: Profile;
  interests_count?: number;
}

export interface JobInterest {
  id: string;
  job_id: string;
  worker_id: string;
  status: InterestStatus;
  created_at: string;
  // Joined relation option
  worker_profile?: WorkerProfile & { profile?: Profile };
  job?: Job;
}

export interface Rating {
  id: string;
  job_id: string;
  from_user_id: string;
  to_user_id: string;
  value: RatingValue;
  comment?: string | null;
  created_at: string;
  from_user?: Profile;
}

// App UI State types
export interface AppState {
  currentRole: UserRole;
  user: Profile | null;
  workerDetails: WorkerProfile | null;
  isLoading: boolean;
}
