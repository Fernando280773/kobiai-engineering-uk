-- =============================================================================
-- Migration: 0030_add_workflow_link_to_workforce_assignments.sql
-- Sprint:    SP-011 (BK-014)
-- ADR:       ADR-0011
-- ES:        ES-010
-- Description: Interface B — adds workflow_step_id FK column to
--              workforce_assignments. Enables a Workflow step of
--              step_type: agent to create a linked workforce assignment.
--              This is a non-destructive ALTER TABLE on an existing table.
--              All existing rows are unaffected (column is nullable).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Add workflow_step_id column to workforce_assignments
-- ---------------------------------------------------------------------------
ALTER TABLE public.workforce_assignments
  ADD COLUMN workflow_step_id UUID REFERENCES public.workflow_steps (id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------------
-- Index
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workforce_assignments_workflow_step
  ON public.workforce_assignments (workflow_step_id)
  WHERE workflow_step_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Column documentation
-- ---------------------------------------------------------------------------
COMMENT ON COLUMN public.workforce_assignments.workflow_step_id IS
  'Interface B: FK to the workflow_steps record that dispatched this assignment. '
  'NULL for assignments created outside a workflow context. '
  'ON DELETE SET NULL — the assignment is preserved if the step is deleted. '
  'Only step_type: agent steps create assignments with this column populated.';
