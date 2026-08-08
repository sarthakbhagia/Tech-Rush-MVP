-- MIGRATION 20260808000000: Fix applications update RLS + notifications insert RLS policies

-- 1. Fix applications RLS update policy to only allow the job owner (employer) to update status
DROP POLICY IF EXISTS "Job Owners and Applicants Can Update Applications" ON public.applications;
CREATE POLICY "Job Owners Can Update Applications" ON public.applications 
  FOR UPDATE TO authenticated 
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs 
      WHERE jobs.id = applications.job_id 
      AND jobs.employer_id = auth.uid()
    )
  );

-- 2. Fix notifications RLS insert policy to allow any authenticated user to insert notifications
DROP POLICY IF EXISTS "Users or System Can Insert Notifications" ON public.notifications;
CREATE POLICY "Users or System Can Insert Notifications"
  ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (true);
