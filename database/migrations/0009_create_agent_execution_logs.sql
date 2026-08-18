-- Migration: 0009_create_agent_execution_logs
-- Sprint:     SP-007 (BK-010 — AI Runtime Foundation)
-- Created:    July 16, 2026

-- ============================================================
-- TABLE: agent_execution_logs
-- NOTE: This table is IMMUTABLE. No UPDATE or DELETE permitted.
--       Enforced via trigger: trg_immutable_execution_logs
-- ============================================================

CREATE TABLE IF NOT EXISTS public.agent_execution_logs (
  id               UUID        NOT NULL DEFAULT gen_random_uuid(),
  session_id       UUID        NOT NULL,
  agent_id         UUID,
  model_provider   TEXT        NOT NULL,
  model_name       TEXT        NOT NULL,
  prompt_version   TEXT        NOT NULL,
  tokens_input     INTEGER     NOT NULL DEFAULT 0,
  tokens_output    INTEGER     NOT NULL DEFAULT 0,
  tool_calls       JSONB       NOT NULL DEFAULT '{}'::jsonb,
  execution_status TEXT        NOT NULL,
  latency_ms       INTEGER     NOT NULL DEFAULT 0,
  error_message    TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_agent_execution_logs PRIMARY KEY (id),

  CONSTRAINT fk_agent_execution_logs_session
    FOREIGN KEY (session_id)
    REFERENCES public.agent_sessions (id)
    ON DELETE CASCADE,

  CONSTRAINT fk_agent_execution_logs_agent
    FOREIGN KEY (agent_id)
    REFERENCES public.ai_agents (id)
    ON DELETE SET NULL
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_agent_execution_logs_session
  ON public.agent_execution_logs (session_id);

CREATE INDEX IF NOT EXISTS idx_agent_execution_logs_agent
  ON public.agent_execution_logs (agent_id);

-- ============================================================
-- IMMUTABILITY TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION prevent_execution_log_mutation()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'agent_execution_logs are immutable and cannot be modified or deleted.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_immutable_execution_logs
  BEFORE UPDATE OR DELETE ON public.agent_execution_logs
  FOR EACH ROW EXECUTE FUNCTION prevent_execution_log_mutation();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.agent_execution_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_agent_execution_logs_select
  ON public.agent_execution_logs
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

CREATE POLICY rls_agent_execution_logs_insert
  ON public.agent_execution_logs
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
