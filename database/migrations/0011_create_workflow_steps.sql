-- =============================================================================
-- Migration: 0011_create_workflow_steps
-- Sprint:    SP-008 (BK-011)
-- ADR:       ADR-0008
-- ES:        ES-008
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.workflow_steps
-- ---------------------------------------------------------------------------
CREATE TABLE public.workflow_steps (
  id                UUID        NOT NULL DEFAULT gen_random_uuid(),
  workflow_id       UUID        NOT NULL,
  sequence          INTEGER     NOT NULL,
  step_type         TEXT        NOT NULL,
  assigned_agent_id UUID,
  tool_name         TEXT,
  approval_required BOOLEAN     NOT NULL DEFAULT false,
  timeout_seconds   INTEGER,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_workflow_steps PRIMARY KEY (id),

  CONSTRAINT fk_workflow_steps_workflow
    FOREIGN KEY (workflow_id) REFERENCES public.workflows (id) ON DELETE CASCADE,

  CONSTRAINT fk_workflow_steps_agent
    FOREIGN KEY (assigned_agent_id) REFERENCES public.ai_agents (id) ON DELETE SET NULL
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workflow_steps_workflow ON public.workflow_steps (workflow_id);
CREATE INDEX idx_workflow_steps_sequence ON public.workflow_steps (workflow_id, sequence);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.workflow_steps ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_workflow_steps_select ON public.workflow_steps
  FOR SELECT USING (
    workflow_id IN (
      SELECT id FROM public.workflows
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workflow_steps_insert ON public.workflow_steps
  FOR INSERT WITH CHECK (
    workflow_id IN (
      SELECT id FROM public.workflows
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workflow_steps_update ON public.workflow_steps
  FOR UPDATE USING (
    workflow_id IN (
      SELECT id FROM public.workflows
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workflow_steps_delete ON public.workflow_steps
  FOR DELETE USING (
    workflow_id IN (
      SELECT id FROM public.workflows
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );
