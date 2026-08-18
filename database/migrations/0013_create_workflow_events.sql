-- =============================================================================
-- Migration: 0013_create_workflow_events
-- Sprint:    SP-008 (BK-011)
-- ADR:       ADR-0008
-- ES:        ES-008
-- Note:      This table is IMMUTABLE — append-only audit record.
--            Trigger trg_immutable_workflow_events blocks UPDATE and DELETE.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Immutability Function
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_workflow_event_mutation()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'workflow_events are immutable and cannot be modified or deleted.';
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Table: public.workflow_events
-- ---------------------------------------------------------------------------
CREATE TABLE public.workflow_events (
  id             UUID        NOT NULL DEFAULT gen_random_uuid(),
  execution_id   UUID        NOT NULL,
  event_type     TEXT        NOT NULL,
  event_payload  JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_workflow_events PRIMARY KEY (id),

  CONSTRAINT fk_workflow_events_execution
    FOREIGN KEY (execution_id) REFERENCES public.workflow_executions (id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- Immutability Trigger
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_immutable_workflow_events
  BEFORE UPDATE OR DELETE ON public.workflow_events
  FOR EACH ROW EXECUTE FUNCTION prevent_workflow_event_mutation();

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workflow_events_execution ON public.workflow_events (execution_id);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.workflow_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_workflow_events_select ON public.workflow_events
  FOR SELECT USING (
    execution_id IN (
      SELECT we.id FROM public.workflow_executions we
      JOIN public.workflows w ON we.workflow_id = w.id
      WHERE w.workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workflow_events_insert ON public.workflow_events
  FOR INSERT WITH CHECK (
    execution_id IN (
      SELECT we.id FROM public.workflow_executions we
      JOIN public.workflows w ON we.workflow_id = w.id
      WHERE w.workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );
