-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0026_create_activities.sql
-- Sprint:    SP-010 (BK-013)
-- ADR:       ADR-0010
-- ES:        ES-009
-- Description: Creates the activities table. Workspace-scoped CRM entity
--              representing interactions and events (calls, emails, meetings,
--              notes, tasks) linked to customers, contacts, or opportunities.
--              Activities are the audit trail of CRM engagement.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.activities
-- ---------------------------------------------------------------------------
CREATE TABLE public.activities (
  id              UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id    UUID        NOT NULL,
  customer_id     UUID,
  contact_id      UUID,
  opportunity_id  UUID,
  organization_id UUID,
  activity_type   TEXT        NOT NULL,
  subject         TEXT        NOT NULL,
  description     TEXT,
  status          TEXT        NOT NULL DEFAULT 'planned',
  due_at          TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  metadata        JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_by      UUID        NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_activities PRIMARY KEY (id),

  CONSTRAINT fk_activities_workspace
    FOREIGN KEY (workspace_id) REFERENCES public.workspaces (id) ON DELETE CASCADE,

  CONSTRAINT fk_activities_customer
    FOREIGN KEY (customer_id) REFERENCES public.customers (id) ON DELETE SET NULL,

  CONSTRAINT fk_activities_contact
    FOREIGN KEY (contact_id) REFERENCES public.contacts (id) ON DELETE SET NULL,

  CONSTRAINT fk_activities_opportunity
    FOREIGN KEY (opportunity_id) REFERENCES public.opportunities (id) ON DELETE SET NULL,

  CONSTRAINT fk_activities_organization
    FOREIGN KEY (organization_id) REFERENCES public.organizations (id) ON DELETE SET NULL,

  CONSTRAINT fk_activities_created_by
    FOREIGN KEY (created_by) REFERENCES auth.users (id) ON DELETE CASCADE,

  CONSTRAINT chk_activities_type
    CHECK (activity_type IN ('call', 'email', 'meeting', 'note', 'task', 'demo', 'follow_up')),

  CONSTRAINT chk_activities_status
    CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),

  CONSTRAINT chk_activities_completed
    CHECK (completed_at IS NULL OR status = 'completed')
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_activities_workspace    ON public.activities (workspace_id);
CREATE INDEX idx_activities_customer     ON public.activities (customer_id);
CREATE INDEX idx_activities_contact      ON public.activities (contact_id);
CREATE INDEX idx_activities_opportunity  ON public.activities (opportunity_id);
CREATE INDEX idx_activities_organization ON public.activities (organization_id);
CREATE INDEX idx_activities_type         ON public.activities (activity_type);
CREATE INDEX idx_activities_status       ON public.activities (status);
CREATE INDEX idx_activities_due          ON public.activities (due_at);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_activities_select ON public.activities
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_activities_insert ON public.activities
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_activities_update ON public.activities
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_activities_delete ON public.activities
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
