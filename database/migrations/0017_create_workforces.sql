-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0017_create_workforces.sql
-- Sprint:    SP-009 (BK-012)
-- ADR:       ADR-0009
-- ES:        ES-008
-- Description: Creates the root workforces table. Workspace-scoped. Supports
--              human, AI, and mixed workforce types. Carries lifecycle status.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.workforces
-- ---------------------------------------------------------------------------
CREATE TABLE public.workforces (
  id             UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id   UUID        NOT NULL,
  project_id     UUID,
  name           TEXT        NOT NULL,
  description    TEXT,
  workforce_type TEXT        NOT NULL DEFAULT 'mixed',
  status         TEXT        NOT NULL DEFAULT 'draft',
  created_by     UUID        NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_workforces PRIMARY KEY (id),

  CONSTRAINT fk_workforces_workspace
    FOREIGN KEY (workspace_id) REFERENCES public.workspaces (id) ON DELETE CASCADE,

  CONSTRAINT fk_workforces_project
    FOREIGN KEY (project_id) REFERENCES public.projects (id) ON DELETE SET NULL,

  CONSTRAINT fk_workforces_created_by
    FOREIGN KEY (created_by) REFERENCES auth.users (id) ON DELETE CASCADE,

  CONSTRAINT chk_workforces_type
    CHECK (workforce_type IN ('human', 'ai', 'mixed')),

  CONSTRAINT chk_workforces_status
    CHECK (status IN ('draft', 'active', 'archived', 'disbanded'))
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workforces_workspace ON public.workforces (workspace_id);
CREATE INDEX idx_workforces_project   ON public.workforces (project_id);
CREATE INDEX idx_workforces_status    ON public.workforces (status);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.workforces ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_workforces_select ON public.workforces
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_workforces_insert ON public.workforces
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_workforces_update ON public.workforces
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_workforces_delete ON public.workforces
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
