-- =============================================================================
-- Migration: 0012_create_workflow_executions
-- Sprint:    SP-008 (BK-011)
-- ADR:       ADR-0008
-- ES:        ES-008
-- Note:      This table is IMMUTABLE. No updated_at column.
--            Trigger trg_immutable_workflow_executions blocks UPDATE and DELETE.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Immutability Function
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_workflow_execution_mutation()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'workflow_executions are immutable and cannot be modified or deleted.';
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Table: public.workflow_executions
-- ---------------------------------------------------------------------------
CREATE TABLE public.workflow_executions (
  id               UUID        NOT NULL DEFAULT gen_random_uuid(),
  workflow_id      UUID        NOT NULL,
  session_id       UUID,
  execution_status TEXT        NOT NULL DEFAULT 'pending',
  started_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at     TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_workflow_executions PRIMARY KEY (id),

  CONSTRAINT fk_workflow_executions_workflow
    FOREIGN KEY (workflow_id) REFERENCES public.workflows (id) ON DELETE CASCADE,

  CONSTRAINT fk_workflow_executions_session
    FOREIGN KEY (session_id) REFERENCES public.agent_sessions (id) ON DELETE SET NULL
);

-- ---------------------------------------------------------------------------
-- Immutability Trigger
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_immutable_workflow_executions
  BEFORE UPDATE OR DELETE ON public.workflow_executions
  FOR EACH ROW EXECUTE FUNCTION prevent_workflow_execution_mutation();

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workflow_executions_workflow ON public.workflow_executions (workflow_id);
CREATE INDEX idx_workflow_executions_session  ON public.workflow_executions (session_id);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.workflow_executions ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_workflow_executions_select ON public.workflow_executions
  FOR SELECT USING (
    workflow_id IN (
      SELECT id FROM public.workflows
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workflow_executions_insert ON public.workflow_executions
  FOR INSERT WITH CHECK (
    workflow_id IN (
      SELECT id FROM public.workflows
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );
