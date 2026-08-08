-- Restrict application management to the employer who owns the job.
-- This replaces legacy permissive policies from earlier migrations.
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users Can Update Applications" ON public.applications;
DROP POLICY IF EXISTS "Job Owners and Applicants Can Update Applications" ON public.applications;
DROP POLICY IF EXISTS "Only Job Owner Can Update Application Status" ON public.applications;
DROP POLICY IF EXISTS "Only Job Owners Can Update Applications" ON public.applications;
DROP POLICY IF EXISTS "Anyone Authenticated Can Read Applications" ON public.applications;
DROP POLICY IF EXISTS "Job Owners and Applicants Can Read Applications" ON public.applications;

CREATE POLICY "Job Owners Can Update Application Status"
  ON public.applications FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs
      WHERE jobs.id = applications.job_id
        AND jobs.employer_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.jobs
      WHERE jobs.id = applications.job_id
        AND jobs.employer_id = auth.uid()
    )
  );

-- Ensure the read policy is limited to the applicant and the job owner.
CREATE POLICY "Job Owners and Applicants Can Read Applications"
  ON public.applications FOR SELECT TO authenticated
  USING (
    auth.uid() = worker_id
    OR EXISTS (
      SELECT 1 FROM public.jobs
      WHERE jobs.id = applications.job_id
        AND jobs.employer_id = auth.uid()
    )
  );

-- Notifications are delivered live to the same provider used by the bell and
-- notifications screen. Add the table only if it is not already published.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;
