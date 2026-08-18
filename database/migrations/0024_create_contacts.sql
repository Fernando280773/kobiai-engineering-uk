-- =============================================================================
-- Migration: 0024_create_contacts.sql
-- Sprint:    SP-010 (BK-013)
-- ADR:       ADR-0010
-- ES:        ES-009
-- Description: Creates the contacts table. Workspace-scoped CRM entity
--              representing individual people. A contact may link to a
--              customer, an organisation, both, or neither.
--              Email is unique per workspace where provided.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.contacts
-- ---------------------------------------------------------------------------
CREATE TABLE public.contacts (
  id              UUID        NOT NULL DEFAULT gen_random_uuid(),
  workspace_id    UUID        NOT NULL,
  customer_id     UUID,
  organization_id UUID,
  first_name      TEXT        NOT NULL,
  last_name       TEXT        NOT NULL,
  email           TEXT,
  phone           TEXT,
  role            TEXT,
  status          TEXT        NOT NULL DEFAULT 'active',
  metadata        JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_contacts PRIMARY KEY (id),

  CONSTRAINT fk_contacts_workspace
    FOREIGN KEY (workspace_id) REFERENCES public.workspaces (id) ON DELETE CASCADE,

  CONSTRAINT fk_contacts_customer
    FOREIGN KEY (customer_id) REFERENCES public.customers (id) ON DELETE SET NULL,

  CONSTRAINT fk_contacts_organization
    FOREIGN KEY (organization_id) REFERENCES public.organizations (id) ON DELETE SET NULL,

  CONSTRAINT uq_contacts_workspace_email
    UNIQUE (workspace_id, email),

  CONSTRAINT chk_contacts_status
    CHECK (status IN ('active', 'inactive', 'archived'))
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_contacts_workspace    ON public.contacts (workspace_id);
CREATE INDEX idx_contacts_customer     ON public.contacts (customer_id);
CREATE INDEX idx_contacts_organization ON public.contacts (organization_id);
CREATE INDEX idx_contacts_status       ON public.contacts (status);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_contacts_select ON public.contacts
  FOR SELECT USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_contacts_insert ON public.contacts
  FOR INSERT WITH CHECK (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_contacts_update ON public.contacts
  FOR UPDATE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY rls_contacts_delete ON public.contacts
  FOR DELETE USING (
    workspace_id IN (
      SELECT workspace_id
      FROM public.workspace_members
      WHERE user_id = auth.uid()
    )
  );
