-- =============================================================================
-- Migration: 0031_add_workforce_link_to_agent_sessions.sql
-- Sprint:    SP-011 (BK-014)
-- ADR:       ADR-0011
-- ES:        ES-010
-- Description: Interface C — adds workforce_assignment_id FK column to
--              agent_sessions. Enables a Workforce assignment to invoke
--              and track a linked AI Runtime session.
--              This completes the traceable chain:
--                bos_event_routing
--                  → workflow_executions
--                    → workforce_assignments
--                      → agent_sessions
--                        → agent_execution_logs
--              This is a non-destructive ALTER TABLE on an existing table.
--              All existing rows are unaffected (column is nullable).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Add workforce_assignment_id column to agent_sessions
-- ---------------------------------------------------------------------------
ALTER TABLE public.agent_sessions
  ADD COLUMN workforce_assignment_id UUID REFERENCES public.workforce_assignments (id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------------
-- Index
-- ---------------------------------------------------------------------------
CREATE INDEX idx_agent_sessions_workforce_assignment
  ON public.agent_sessions (workforce_assignment_id)
  WHERE workforce_assignment_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Column documentation
-- ---------------------------------------------------------------------------
COMMENT ON COLUMN public.agent_sessions.workforce_assignment_id IS
  'Interface C: FK to the workforce_assignments record that invoked this session. '
  'NULL for sessions created outside a workforce context. '
  'ON DELETE SET NULL — the session is preserved if the assignment is deleted. '
  'Completes the traceable chain: bos_event_routing → workflow_executions → '
  'workforce_assignments → agent_sessions → agent_execution_logs.';
