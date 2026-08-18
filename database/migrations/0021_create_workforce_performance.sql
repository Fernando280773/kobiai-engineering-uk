-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0021_create_workforce_performance.sql
-- Sprint:    SP-009 (BK-012)
-- ADR:       ADR-0009
-- ES:        ES-008
-- Note:      This table is IMMUTABLE — append-only audit record.
--            Trigger trg_immutable_workforce_performance blocks UPDATE and DELETE.
--            No updated_at column. Records are permanent once written.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Immutability Function
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_workforce_performance_mutation()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'workforce_performance records are immutable and cannot be modified or deleted.';
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Table: public.workforce_performance
-- ---------------------------------------------------------------------------
CREATE TABLE public.workforce_performance (
  id           UUID        NOT NULL DEFAULT gen_random_uuid(),
  workforce_id UUID        NOT NULL,
  member_id    UUID,
  period_start TIMESTAMPTZ NOT NULL,
  period_end   TIMESTAMPTZ NOT NULL,
  metrics      JSONB       NOT NULL DEFAULT '{}'::jsonb,
  recorded_by  UUID        NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_workforce_performance PRIMARY KEY (id),

  CONSTRAINT fk_workforce_performance_workforce
    FOREIGN KEY (workforce_id) REFERENCES public.workforces (id) ON DELETE CASCADE,

  CONSTRAINT fk_workforce_performance_member
    FOREIGN KEY (member_id) REFERENCES public.workforce_members (id) ON DELETE SET NULL,

  CONSTRAINT fk_workforce_performance_recorded_by
    FOREIGN KEY (recorded_by) REFERENCES auth.users (id) ON DELETE CASCADE,

  CONSTRAINT chk_workforce_performance_period
    CHECK (period_end > period_start)
);

-- ---------------------------------------------------------------------------
-- Immutability Trigger
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_immutable_workforce_performance
  BEFORE UPDATE OR DELETE ON public.workforce_performance
  FOR EACH ROW EXECUTE FUNCTION prevent_workforce_performance_mutation();

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workforce_performance_workforce ON public.workforce_performance (workforce_id);
CREATE INDEX idx_workforce_performance_member    ON public.workforce_performance (member_id);
CREATE INDEX idx_workforce_performance_period    ON public.workforce_performance (workforce_id, period_start, period_end);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.workforce_performance ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_workforce_performance_select ON public.workforce_performance
  FOR SELECT USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_performance_insert ON public.workforce_performance
  FOR INSERT WITH CHECK (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );
