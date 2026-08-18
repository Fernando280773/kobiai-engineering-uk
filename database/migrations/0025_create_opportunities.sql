-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0025_create_opportunities.sql
-- Sprint:    SP-010 (BK-013)
-- ADR:       ADR-0010
-- ES:        ES-009
-- Description: Creates the opportunities table. Workspace-scoped CRM entity
--              representing a potential business deal linked to a customer
--              and optionally a contact or organisation. Carries a pipeline
--              stage, an estimated value, and a projected close date.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.opportunities
-- ---------------------------------------------------------------------------
CREATE TABLE public.opportunities (
  id              UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id    UUID        NOT NULL,
  customer_id     UUID        NOT NULL,
  contact_id      UUID,
  organization_id UUID,
  title           TEXT        NOT NULL,
  stage           TEXT        NOT NULL DEFAULT 'prospecting',
  value           NUMERIC(15, 2),
  currency        TEXT        NOT NULL DEFAULT 'GBP',
  close_date      DATE,
  status          TEXT        NOT NULL DEFAULT 'open',
  metadata        JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_by      UUID        NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_opportunities PRIMARY KEY (id),

  CONSTRAINT fk_opportunities_workspace
    FOREIGN KEY (workspace_id) REFERENCES public.workspaces (id) ON DELETE CASCADE,

  CONSTRAINT fk_opportunities_customer
    FOREIGN KEY (customer_id) REFERENCES public.customers (id) ON DELETE CASCADE,

  CONSTRAINT fk_opportunities_contact
    FOREIGN KEY (contact_id) REFERENCES public.contacts (id) ON DELETE SET NULL,

  CONSTRAINT fk_opportunities_organization
    FOREIGN KEY (organization_id) REFERENCES public.organizations (id) ON DELETE SET NULL,

  CONSTRAINT fk_opportunities_created_by
    FOREIGN KEY (created_by) REFERENCES auth.users (id) ON DELETE CASCADE,

  CONSTRAINT chk_opportunities_stage
    CHECK (stage IN ('prospecting', 'qualification', 'proposal', 'negotiation', 'closed_won', 'closed_lost')),

  CONSTRAINT chk_opportunities_status
    CHECK (status IN ('open', 'won', 'lost', 'archived')),

  CONSTRAINT chk_opportunities_value
    CHECK (value IS NULL OR value >= 0)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_opportunities_workspace    ON public.opportunities (workspace_id);
CREATE INDEX idx_opportunities_customer     ON public.opportunities (customer_id);
CREATE INDEX idx_opportunities_contact      ON public.opportunities (contact_id);
CREATE INDEX idx_opportunities_organization ON public.opportunities (organization_id);
CREATE INDEX idx_opportunities_stage        ON public.opportunities (stage);
CREATE INDEX idx_opportunities_status       ON public.opportunities (status);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.opportunities ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_opportunities_select ON public.opportunities
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_opportunities_insert ON public.opportunities
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_opportunities_update ON public.opportunities
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_opportunities_delete ON public.opportunities
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
