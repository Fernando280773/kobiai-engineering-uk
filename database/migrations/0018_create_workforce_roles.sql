-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0018_create_workforce_roles.sql
-- Sprint:    SP-009 (BK-012)
-- ADR:       ADR-0009
-- ES:        ES-008
-- Description: Creates the workforce_roles table. Defines named roles within a
--              workforce with authority levels and permission configurations.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.workforce_roles
-- ---------------------------------------------------------------------------
CREATE TABLE public.workforce_roles (
  id              UUID        NOT NULL DEFAULT gen_random_uuid(),
  workforce_id    UUID        NOT NULL,
  name            TEXT        NOT NULL,
  description     TEXT,
  authority_level INTEGER     NOT NULL DEFAULT 1,
  permissions     JSONB       NOT NULL DEFAULT '{}'::jsonb,
  created_by      UUID        NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_workforce_roles PRIMARY KEY (id),

  CONSTRAINT fk_workforce_roles_workforce
    FOREIGN KEY (workforce_id) REFERENCES public.workforces (id) ON DELETE CASCADE,

  CONSTRAINT fk_workforce_roles_created_by
    FOREIGN KEY (created_by) REFERENCES auth.users (id) ON DELETE CASCADE,

  CONSTRAINT chk_workforce_roles_authority_level
    CHECK (authority_level BETWEEN 1 AND 5)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workforce_roles_workforce ON public.workforce_roles (workforce_id);
CREATE INDEX idx_workforce_roles_authority ON public.workforce_roles (workforce_id, authority_level);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.workforce_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_workforce_roles_select ON public.workforce_roles
  FOR SELECT USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_roles_insert ON public.workforce_roles
  FOR INSERT WITH CHECK (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_roles_update ON public.workforce_roles
  FOR UPDATE USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_roles_delete ON public.workforce_roles
  FOR DELETE USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );
