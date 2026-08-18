-- =============================================================================
-- Migration: 0023_create_customers.sql
-- Sprint:    SP-010 (BK-013)
-- ADR:       ADR-0010
-- ES:        ES-009
-- Description: Creates the customers table. Workspace-scoped CRM entity
--              representing individuals or organisations as customers.
--              Optionally links to an organisation. Carries a unique
--              customer_code per workspace and a lifecycle status.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.customers
-- ---------------------------------------------------------------------------
CREATE TABLE public.customers (
  id              UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id    UUID        NOT NULL,
  organization_id UUID,
  customer_code   TEXT        NOT NULL,
  customer_type   TEXT        NOT NULL DEFAULT 'individual',
  name            TEXT        NOT NULL,
  email           TEXT,
  phone           TEXT,
  status          TEXT        NOT NULL DEFAULT 'active',
  metadata        JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_customers PRIMARY KEY (id),

  CONSTRAINT fk_customers_workspace
    FOREIGN KEY (workspace_id) REFERENCES public.workspaces (id) ON DELETE CASCADE,

  CONSTRAINT fk_customers_organization
    FOREIGN KEY (organization_id) REFERENCES public.organizations (id) ON DELETE SET NULL,

  CONSTRAINT uq_customers_workspace_code
    UNIQUE (workspace_id, customer_code),

  CONSTRAINT chk_customers_type
    CHECK (customer_type IN ('individual', 'organization')),

  CONSTRAINT chk_customers_status
    CHECK (status IN ('active', 'inactive', 'archived'))
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_customers_workspace    ON public.customers (workspace_id);
CREATE INDEX idx_customers_organization ON public.customers (organization_id);
CREATE INDEX idx_customers_status       ON public.customers (status);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_customers_select ON public.customers
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_customers_insert ON public.customers
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_customers_update ON public.customers
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_customers_delete ON public.customers
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
