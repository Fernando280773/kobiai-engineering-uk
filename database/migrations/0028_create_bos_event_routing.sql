-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0028_create_bos_event_routing.sql
-- Sprint:    SP-011 (BK-014)
-- ADR:       ADR-0011
-- ES:        ES-010
-- Description: Creates the bos_event_routing table. Interface A — maps
--              canonical BOS event types to Workflow definitions. When a
--              BOS event fires, this table is queried to determine which
--              workflow(s) to trigger.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.bos_event_routing
-- ---------------------------------------------------------------------------
CREATE TABLE public.bos_event_routing (
  id           UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id UUID        NOT NULL,
  event_type   TEXT        NOT NULL,
  workflow_id  UUID        NOT NULL,
  is_active    BOOLEAN     NOT NULL DEFAULT true,
  metadata     JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_by   UUID        NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Primary Key
  CONSTRAINT pk_bos_event_routing PRIMARY KEY (id),

  -- Foreign Keys
  CONSTRAINT fk_bos_event_routing_workspace
    FOREIGN KEY (workspace_id) REFERENCES public.workspaces (id) ON DELETE CASCADE,

  CONSTRAINT fk_bos_event_routing_workflow
    FOREIGN KEY (workflow_id) REFERENCES public.workflows (id) ON DELETE CASCADE,

  CONSTRAINT fk_bos_event_routing_created_by
    FOREIGN KEY (created_by) REFERENCES auth.users (id) ON DELETE CASCADE,

  -- Uniqueness: one routing rule per (workspace, event_type, workflow) combination
  CONSTRAINT uq_bos_event_routing_rule
    UNIQUE (workspace_id, event_type, workflow_id),

  -- Canonical BOS Event Catalogue (STD-BOS-005)
  -- Extended by migration 0029 after catalogue is formally defined
  CONSTRAINT chk_bos_event_routing_event_type
    CHECK (event_type IN (
      'organization.created', 'organization.updated', 'organization.archived',
      'customer.created', 'customer.updated', 'customer.status_changed', 'customer.archived',
      'contact.created', 'contact.updated', 'contact.archived',
      'opportunity.created', 'opportunity.stage_changed',
      'opportunity.won', 'opportunity.lost', 'opportunity.archived',
      'activity.call_logged', 'activity.email_logged', 'activity.meeting_scheduled',
      'activity.note_added', 'activity.task_created', 'activity.completed',
      'dashboard.created', 'dashboard.updated'
    ))
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_bos_event_routing_workspace
  ON public.bos_event_routing (workspace_id);

CREATE INDEX idx_bos_event_routing_event_type
  ON public.bos_event_routing (workspace_id, event_type);

CREATE INDEX idx_bos_event_routing_workflow
  ON public.bos_event_routing (workflow_id);

CREATE INDEX idx_bos_event_routing_active
  ON public.bos_event_routing (workspace_id, event_type, is_active)
  WHERE is_active = true;

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.bos_event_routing ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_bos_event_routing_select ON public.bos_event_routing
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_bos_event_routing_insert ON public.bos_event_routing
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_bos_event_routing_update ON public.bos_event_routing
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_bos_event_routing_delete ON public.bos_event_routing
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
