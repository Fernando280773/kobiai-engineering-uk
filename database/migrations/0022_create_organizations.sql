-- =============================================================================
-- Migration: 0022_create_organizations.sql
-- Sprint:    SP-010 (BK-013)
-- ADR:       ADR-0010
-- ES:        ES-009
-- Description: Creates the organizations table. Workspace-scoped business
--              entity representing companies, firms, and named organisations.
--              Parent entity for customers and contacts.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.organizations
-- ---------------------------------------------------------------------------
CREATE TABLE public.organizations (
  id           UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id UUID        NOT NULL,
  name         TEXT        NOT NULL,
  industry     TEXT,
  size         TEXT,
  website      TEXT,
  status       TEXT        NOT NULL DEFAULT 'active',
  metadata     JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_organizations PRIMARY KEY (id),

  CONSTRAINT fk_organizations_workspace
    FOREIGN KEY (workspace_id) REFERENCES public.workspaces (id) ON DELETE CASCADE,

  CONSTRAINT uq_organizations_workspace_name
    UNIQUE (workspace_id, name),

  CONSTRAINT chk_organizations_size
    CHECK (size IN ('solo', 'small', 'medium', 'large', 'enterprise')),

  CONSTRAINT chk_organizations_status
    CHECK (status IN ('active', 'inactive', 'archived'))
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_organizations_workspace ON public.organizations (workspace_id);
CREATE INDEX idx_organizations_status    ON public.organizations (status);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_organizations_select ON public.organizations
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_organizations_insert ON public.organizations
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_organizations_update ON public.organizations
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_organizations_delete ON public.organizations
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
