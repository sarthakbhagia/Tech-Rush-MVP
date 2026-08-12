-- =============================================================
-- KaamSetu: Verified Job Completion Workflow Migration
-- Run AFTER: 20260812220000_create_payouts_table.sql
-- =============================================================

-- ── 1. Update jobs.status constraint to include intermediate statuses ────────

ALTER TABLE public.jobs
  DROP CONSTRAINT IF EXISTS jobs_status_check;

ALTER TABLE public.jobs
  ADD CONSTRAINT jobs_status_check
  CHECK (status IN (
    'open',
    'assigned',
    'on_the_way',
    'arrived',
    'working',
    'proof_submitted',
    'completed',
    'cancelled'
  ));

-- ── 2. Create completion_proofs table ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.completion_proofs (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id               UUID        NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  worker_id            UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  proof_image_urls     TEXT[]      NOT NULL DEFAULT '{}',
  worker_confirmed     BOOLEAN     NOT NULL DEFAULT FALSE,
  submitted_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  verification_status  TEXT        NOT NULL DEFAULT 'pending'
                         CHECK (verification_status IN ('pending', 'verified', 'disputed')),
  verified_by          UUID        REFERENCES public.profiles(id) ON DELETE SET NULL,
  verified_at          TIMESTAMPTZ,
  notes                TEXT,
  CONSTRAINT unique_completion_proof_per_job UNIQUE (job_id, worker_id)
);

-- ── 3. Indexes ───────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_completion_proofs_job    ON public.completion_proofs(job_id);
CREATE INDEX IF NOT EXISTS idx_completion_proofs_worker ON public.completion_proofs(worker_id);

-- ── 4. Row Level Security ────────────────────────────────────────────────────

ALTER TABLE public.completion_proofs ENABLE ROW LEVEL SECURITY;

-- Clean up existing policies safely
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_tables
    WHERE schemaname = 'public' AND tablename = 'completion_proofs'
  ) THEN
    DROP POLICY IF EXISTS "Workers can insert own completion proof"   ON public.completion_proofs;
    DROP POLICY IF EXISTS "Involved parties can view completion proof" ON public.completion_proofs;
    DROP POLICY IF EXISTS "Employers can verify completion proof"      ON public.completion_proofs;
  END IF;
END $$;

-- Worker can INSERT their own proof (only for jobs they are assigned to)
CREATE POLICY "Workers can insert own completion proof"
  ON public.completion_proofs FOR INSERT
  WITH CHECK (
    auth.uid() = worker_id
    AND EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_id
        AND j.assigned_worker_id = auth.uid()
        AND j.status IN ('working', 'proof_submitted')
    )
  );

-- Both worker (own proof) and employer (their job's proof) can view
CREATE POLICY "Involved parties can view completion proof"
  ON public.completion_proofs FOR SELECT
  USING (
    auth.uid() = worker_id
    OR EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_id AND j.household_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_id AND j.employer_id = auth.uid()
    )
  );

-- Only the employer who owns the job can UPDATE the proof (to verify/dispute it)
-- Workers CANNOT update their own proof after submission (prevents self-verification)
CREATE POLICY "Employers can verify completion proof"
  ON public.completion_proofs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_id
        AND (j.household_id = auth.uid() OR j.employer_id = auth.uid())
    )
  )
  WITH CHECK (
    -- Employer can only update verification fields, not swap the worker
    worker_id = OLD.worker_id
    AND job_id = OLD.job_id
  );
