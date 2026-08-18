-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0020_create_workforce_assignments.sql
-- Sprint:    SP-009 (BK-012)
-- ADR:       ADR-0009
-- ES:        ES-008
-- Description: Creates the workforce_assignments table. Links a workforce to
--              a project or workflow engagement. Carries assignment lifecycle
--              status, date window, and freeform context metadata.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.workforce_assignments
-- ---------------------------------------------------------------------------
CREATE TABLE public.workforce_assignments (
  id                UUID        NOT NULL DEFAULT gen_random_uuid(),
  workforce_id      UUID        NOT NULL,
  project_id        UUID,
  workflow_id       UUID,
  assignment_status TEXT        NOT NULL DEFAULT 'pending',
  assigned_by       UUID        NOT NULL,
  start_date        TIMESTAMPTZ,
  end_date          TIMESTAMPTZ,
  context           JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_workforce_assignments PRIMARY KEY (id),

  CONSTRAINT fk_workforce_assignments_workforce
    FOREIGN KEY (workforce_id) REFERENCES public.workforces (id) ON DELETE CASCADE,

  CONSTRAINT fk_workforce_assignments_project
    FOREIGN KEY (project_id) REFERENCES public.projects (id) ON DELETE SET NULL,

  CONSTRAINT fk_workforce_assignments_workflow
    FOREIGN KEY (workflow_id) REFERENCES public.workflows (id) ON DELETE SET NULL,

  CONSTRAINT fk_workforce_assignments_assigned_by
    FOREIGN KEY (assigned_by) REFERENCES auth.users (id) ON DELETE CASCADE,

  CONSTRAINT chk_workforce_assignments_status
    CHECK (assignment_status IN ('pending', 'active', 'completed', 'cancelled'))
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workforce_assignments_workforce ON public.workforce_assignments (workforce_id);
CREATE INDEX idx_workforce_assignments_project   ON public.workforce_assignments (project_id);
CREATE INDEX idx_workforce_assignments_workflow   ON public.workforce_assignments (workflow_id);
CREATE INDEX idx_workforce_assignments_status     ON public.workforce_assignments (workforce_id, assignment_status);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.workforce_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_workforce_assignments_select ON public.workforce_assignments
  FOR SELECT USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_assignments_insert ON public.workforce_assignments
  FOR INSERT WITH CHECK (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_assignments_update ON public.workforce_assignments
  FOR UPDATE USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_assignments_delete ON public.workforce_assignments
  FOR DELETE USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );
