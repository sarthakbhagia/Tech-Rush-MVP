-- KaamSetu: Realistic Payout / Payment lifecycle migration

CREATE TABLE IF NOT EXISTS public.payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    employer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('payment_pending', 'payout_processing', 'paid')),
    transaction_reference TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    processed_at TIMESTAMPTZ,
    CONSTRAINT unique_job_payout UNIQUE (job_id)
);

CREATE INDEX IF NOT EXISTS idx_payouts_job ON public.payouts(job_id);
CREATE INDEX IF NOT EXISTS idx_payouts_worker ON public.payouts(worker_id);
CREATE INDEX IF NOT EXISTS idx_payouts_employer ON public.payouts(employer_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON public.payouts(status);

ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read payouts they are involved in" ON public.payouts;
CREATE POLICY "Users can read payouts they are involved in"
ON public.payouts FOR SELECT TO authenticated
USING (
    auth.uid() = worker_id OR auth.uid() = employer_id
);

DROP POLICY IF EXISTS "System can insert payouts" ON public.payouts;
CREATE POLICY "System can insert payouts"
ON public.payouts FOR INSERT TO authenticated
WITH CHECK (
    auth.uid() = employer_id
);

DROP POLICY IF EXISTS "System can update payouts" ON public.payouts;
CREATE POLICY "System can update payouts"
ON public.payouts FOR UPDATE TO authenticated
USING (
    auth.uid() = employer_id OR auth.uid() = worker_id
);
