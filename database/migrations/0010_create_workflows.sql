-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0010_create_workflows
-- Sprint:    SP-008 (BK-011)
-- ADR:       ADR-0008
-- ES:        ES-008
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.workflows
-- ---------------------------------------------------------------------------
CREATE TABLE public.workflows (
  id           UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id UUID        NOT NULL,
  project_id   UUID,
  name         TEXT        NOT NULL,
  description  TEXT,
  version      TEXT        NOT NULL DEFAULT '1.0.0',
  status       TEXT        NOT NULL DEFAULT 'draft',
  created_by   UUID        NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_workflows PRIMARY KEY (id),

  CONSTRAINT fk_workflows_workspace
    FOREIGN KEY (workspace_id) REFERENCES public.workspaces (id) ON DELETE CASCADE,

  CONSTRAINT fk_workflows_project
    FOREIGN KEY (project_id) REFERENCES public.projects (id) ON DELETE SET NULL,

  CONSTRAINT fk_workflows_created_by
    FOREIGN KEY (created_by) REFERENCES auth.users (id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workflows_workspace ON public.workflows (workspace_id);
CREATE INDEX idx_workflows_project   ON public.workflows (project_id);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.workflows ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_workflows_select ON public.workflows
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_workflows_insert ON public.workflows
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_workflows_update ON public.workflows
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_workflows_delete ON public.workflows
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
