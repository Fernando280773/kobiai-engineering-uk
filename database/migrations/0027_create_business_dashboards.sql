-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0027_create_business_dashboards.sql
-- Sprint:    SP-010 (BK-013)
-- ADR:       ADR-0010
-- ES:        ES-009
-- Description: Creates the business_dashboards table. Workspace-scoped
--              dashboard configuration store. Layout and config are stored as
--              JSONB enabling flexible panel composition without schema changes.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.business_dashboards
-- ---------------------------------------------------------------------------
CREATE TABLE public.business_dashboards (
  id             UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id   UUID        NOT NULL,
  project_id     UUID,
  name           TEXT        NOT NULL,
  dashboard_type TEXT        NOT NULL,
  layout         JSONB       NOT NULL DEFAULT '{}'::jsonb,
  config         JSONB       NOT NULL DEFAULT '{}'::jsonb,
  status         TEXT        NOT NULL DEFAULT 'active',
  created_by     UUID        NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_business_dashboards PRIMARY KEY (id),

  CONSTRAINT fk_business_dashboards_workspace
    FOREIGN KEY (workspace_id) REFERENCES public.workspaces (id) ON DELETE CASCADE,

  CONSTRAINT fk_business_dashboards_project
    FOREIGN KEY (project_id) REFERENCES public.projects (id) ON DELETE SET NULL,

  CONSTRAINT fk_business_dashboards_created_by
    FOREIGN KEY (created_by) REFERENCES auth.users (id) ON DELETE CASCADE,

  CONSTRAINT chk_business_dashboards_type
    CHECK (dashboard_type IN ('business_health', 'crm_summary', 'ai_workforce_summary', 'workflow_summary', 'kpi_framework')),

  CONSTRAINT chk_business_dashboards_status
    CHECK (status IN ('active', 'inactive', 'archived'))
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_business_dashboards_workspace ON public.business_dashboards (workspace_id);
CREATE INDEX idx_business_dashboards_project   ON public.business_dashboards (project_id);
CREATE INDEX idx_business_dashboards_type      ON public.business_dashboards (dashboard_type);
CREATE INDEX idx_business_dashboards_status    ON public.business_dashboards (status);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.business_dashboards ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_business_dashboards_select ON public.business_dashboards
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_business_dashboards_insert ON public.business_dashboards
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_business_dashboards_update ON public.business_dashboards
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_business_dashboards_delete ON public.business_dashboards
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
