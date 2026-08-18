-- Migration: 0008_create_agent_memory
-- Sprint:     SP-007 (BK-010 — AI Runtime Foundation)
-- Created:    July 16, 2026

-- ============================================================
-- TABLE: agent_memory
-- ============================================================

CREATE TABLE IF NOT EXISTS public.agent_memory (
  id           UUID        NOT NULL DEFAULT gen_random_uuid(),
  session_id   UUID        NOT NULL,
  memory_type  TEXT        NOT NULL,
  memory_scope TEXT        NOT NULL,
  content      JSONB       NOT NULL DEFAULT '{}'::jsonb,
  version      TEXT        NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_agent_memory PRIMARY KEY (id),

  CONSTRAINT fk_agent_memory_session
    FOREIGN KEY (session_id)
    REFERENCES public.agent_sessions (id)
    ON DELETE CASCADE
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_agent_memory_session
  ON public.agent_memory (session_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.agent_memory ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_agent_memory_select
  ON public.agent_memory
  FOR SELECT
  USING (
    session_id IN (
      SELECT id
      FROM public.agent_sessions
      WHERE workspace_id IN (
        SELECT workspace_id
        FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_agent_memory_insert
  ON public.agent_memory
  FOR INSERT
  WITH CHECK (
    session_id IN (
      SELECT id
      FROM public.agent_sessions
      WHERE workspace_id IN (
        SELECT workspace_id
        FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_agent_memory_update
  ON public.agent_memory
  FOR UPDATE
  USING (
    session_id IN (
      SELECT id
      FROM public.agent_sessions
      WHERE workspace_id IN (
        SELECT workspace_id
        FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );
