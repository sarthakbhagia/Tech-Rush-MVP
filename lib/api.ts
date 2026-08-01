import { supabase } from './supabase';
import { Profile, WorkerProfile, Job, JobInterest, Rating, JobStatus, UserRole } from '../types';

// ==========================================
// 1. PROFILES API
// ==========================================

export async function getProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();

  if (error) {
    console.error('Error fetching profile:', error.message);
    return null;
  }
  return data as Profile;
}

export async function upsertProfile(profile: Partial<Profile> & { id: string; role: UserRole; name: string }): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .upsert(profile)
    .select()
    .single();

  if (error) {
    console.error('Error upserting profile:', error.message);
    return null;
  }
  return data as Profile;
}

export async function getWorkerProfile(workerId: string): Promise<WorkerProfile | null> {
  const { data, error } = await supabase
    .from('worker_profiles')
    .select('*, profile:profiles(*)')
    .eq('id', workerId)
    .single();

  if (error) {
    console.error('Error fetching worker profile:', error.message);
    return null;
  }
  return data as WorkerProfile;
}

export async function upsertWorkerProfile(workerProfile: Partial<WorkerProfile> & { id: string }): Promise<WorkerProfile | null> {
  const { data, error } = await supabase
    .from('worker_profiles')
    .upsert(workerProfile)
    .select()
    .single();

  if (error) {
    console.error('Error upserting worker profile:', error.message);
    return null;
  }
  return data as WorkerProfile;
}

// ==========================================
// 2. JOBS API
// ==========================================

export async function fetchJobs(options?: {
  category?: string;
  status?: JobStatus;
  householdId?: string;
}): Promise<Job[]> {
  let query = supabase
    .from('jobs')
    .select('*, household:profiles(*)')
    .order('created_at', { ascending: false });

  if (options?.category && options.category !== 'All') {
    query = query.eq('category', options.category);
  }
  if (options?.status) {
    query = query.eq('status', options.status);
  }
  if (options?.householdId) {
    query = query.eq('household_id', options.householdId);
  }

  const { data, error } = await query;

  if (error) {
    console.error('Error fetching jobs:', error.message);
    return [];
  }
  return data as Job[];
}

export async function fetchJobDetails(jobId: string): Promise<Job | null> {
  const { data, error } = await supabase
    .from('jobs')
    .select('*, household:profiles(*), assigned_worker:profiles(*)')
    .eq('id', jobId)
    .single();

  if (error) {
    console.error('Error fetching job details:', error.message);
    return null;
  }
  return data as Job;
}

export async function createJob(job: {
  household_id: string;
  title: string;
  description?: string;
  category: string;
  location: string;
  budget: number;
  job_date?: string;
}): Promise<Job | null> {
  const { data, error } = await supabase
    .from('jobs')
    .insert([job])
    .select()
    .single();

  if (error) {
    console.error('Error creating job:', error.message);
    return null;
  }
  return data as Job;
}

export async function updateJobStatus(jobId: string, status: JobStatus, assignedWorkerId?: string): Promise<boolean> {
  const updates: Partial<Job> = { status };
  if (assignedWorkerId !== undefined) {
    updates.assigned_worker_id = assignedWorkerId;
  }

  const { error } = await supabase
    .from('jobs')
    .update(updates)
    .eq('id', jobId);

  if (error) {
    console.error('Error updating job status:', error.message);
    return false;
  }
  return true;
}

// ==========================================
// 3. JOB INTERESTS API
// ==========================================

export async function expressInterest(jobId: string, workerId: string): Promise<JobInterest | null> {
  const { data, error } = await supabase
    .from('job_interests')
    .insert([{ job_id: jobId, worker_id: workerId }])
    .select()
    .single();

  if (error) {
    console.error('Error expressing job interest:', error.message);
    return null;
  }
  return data as JobInterest;
}

export async function fetchJobInterests(jobId: string): Promise<JobInterest[]> {
  const { data, error } = await supabase
    .from('job_interests')
    .select('*, worker_profile:worker_profiles(*, profile:profiles(*))')
    .eq('job_id', jobId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching job interests:', error.message);
    return [];
  }
  return data as unknown as JobInterest[];
}

export async function updateInterestStatus(interestId: string, status: 'pending' | 'selected' | 'not_selected'): Promise<boolean> {
  const { error } = await supabase
    .from('job_interests')
    .update({ status })
    .eq('id', interestId);

  if (error) {
    console.error('Error updating interest status:', error.message);
    return false;
  }
  return true;
}

// ==========================================
// 4. RATINGS API
// ==========================================

export async function submitRating(rating: {
  job_id: string;
  from_user_id: string;
  to_user_id: string;
  value: 'up' | 'down';
  comment?: string;
}): Promise<Rating | null> {
  const { data, error } = await supabase
    .from('ratings')
    .insert([rating])
    .select()
    .single();

  if (error) {
    console.error('Error submitting rating:', error.message);
    return null;
  }
  return data as Rating;
}
