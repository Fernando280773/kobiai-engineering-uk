-- NOTE: Adapted for Supabase — FK targets changed from public.users to auth.users
--       (public.users does not exist; Supabase stores users in auth.users).
--       ON DELETE SET NULL changed to CASCADE where the column is NOT NULL.
-- =============================================================================
-- Migration: 0019_create_workforce_members.sql
-- Sprint:    SP-009 (BK-012)
-- ADR:       ADR-0009
-- ES:        ES-008
-- Description: Creates the workforce_members table. Supports both human members
--              (user_id) and AI agent members (agent_id). Member type determines
--              which FK is populated. Both may be null simultaneously for
--              reserved/placeholder members only.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: public.workforce_members
-- ---------------------------------------------------------------------------
CREATE TABLE public.workforce_members (
  id           UUID        NOT NULL DEFAULT gen_random_uuid(),
  workforce_id UUID        NOT NULL,
  role_id      UUID,
  member_type  TEXT        NOT NULL,
  user_id      UUID,
  agent_id     UUID,
  status       TEXT        NOT NULL DEFAULT 'active',
  joined_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by   UUID        NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT pk_workforce_members PRIMARY KEY (id),

  CONSTRAINT fk_workforce_members_workforce
    FOREIGN KEY (workforce_id) REFERENCES public.workforces (id) ON DELETE CASCADE,

  CONSTRAINT fk_workforce_members_role
    FOREIGN KEY (role_id) REFERENCES public.workforce_roles (id) ON DELETE SET NULL,

  CONSTRAINT fk_workforce_members_user
    FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE SET NULL,

  CONSTRAINT fk_workforce_members_agent
    FOREIGN KEY (agent_id) REFERENCES public.ai_agents (id) ON DELETE SET NULL,

  CONSTRAINT fk_workforce_members_created_by
    FOREIGN KEY (created_by) REFERENCES auth.users (id) ON DELETE CASCADE,

  CONSTRAINT chk_workforce_members_type
    CHECK (member_type IN ('human', 'ai_agent')),

  CONSTRAINT chk_workforce_members_status
    CHECK (status IN ('active', 'inactive', 'suspended'))
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workforce_members_workforce ON public.workforce_members (workforce_id);
CREATE INDEX idx_workforce_members_role      ON public.workforce_members (role_id);
CREATE INDEX idx_workforce_members_user      ON public.workforce_members (user_id);
CREATE INDEX idx_workforce_members_agent     ON public.workforce_members (agent_id);
CREATE INDEX idx_workforce_members_status    ON public.workforce_members (workforce_id, status);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.workforce_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_workforce_members_select ON public.workforce_members
  FOR SELECT USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_members_insert ON public.workforce_members
  FOR INSERT WITH CHECK (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_members_update ON public.workforce_members
  FOR UPDATE USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY rls_workforce_members_delete ON public.workforce_members
  FOR DELETE USING (
    workforce_id IN (
      SELECT id FROM public.workforces
      WHERE workspace_id IN (
        SELECT workspace_id FROM public.workspace_members
        WHERE user_id = auth.uid()
      )
    )
  );
