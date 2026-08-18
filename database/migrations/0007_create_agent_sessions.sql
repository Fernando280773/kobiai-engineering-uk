-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- Migration: 0007_create_agent_sessions
-- Sprint:     SP-007 (BK-010 — AI Runtime Foundation)
-- Created:    July 16, 2026

-- ============================================================
-- TABLE: agent_sessions
-- ============================================================

CREATE TABLE IF NOT EXISTS public.agent_sessions (
  id            UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id  UUID        NOT NULL,
  project_id    UUID,
  agent_id      UUID        NOT NULL,
  user_id       UUID        NOT NULL,
  session_status TEXT       NOT NULL DEFAULT 'active',
  started_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at      TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_agent_sessions PRIMARY KEY (id),

  CONSTRAINT fk_agent_sessions_workspace
    FOREIGN KEY (workspace_id)
    REFERENCES public.workspaces (id)
    ON DELETE CASCADE,

  CONSTRAINT fk_agent_sessions_project
    FOREIGN KEY (project_id)
    REFERENCES public.projects (id)
    ON DELETE SET NULL,

  CONSTRAINT fk_agent_sessions_agent
    FOREIGN KEY (agent_id)
    REFERENCES public.ai_agents (id)
    ON DELETE CASCADE,

  CONSTRAINT fk_agent_sessions_user
    FOREIGN KEY (user_id)
    REFERENCES auth.users (id)
    ON DELETE CASCADE
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_agent_sessions_workspace
  ON public.agent_sessions (workspace_id);

CREATE INDEX IF NOT EXISTS idx_agent_sessions_agent
  ON public.agent_sessions (agent_id);

CREATE INDEX IF NOT EXISTS idx_agent_sessions_project
  ON public.agent_sessions (project_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.agent_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_agent_sessions_select
  ON public.agent_sessions
  FOR SELECT
  USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_agent_sessions_insert
  ON public.agent_sessions
  FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_agent_sessions_update
  ON public.agent_sessions
  FOR UPDATE
  USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
