-- =============================================================================
-- Migration: 0015_add_workflow_step_type_constraint.sql
-- Sprint: SP-008 (Correction 2 — Canonical Step Types Registry)
-- Implements: ADR-0008 §7 + workflow/ARCHITECTURE.md §4
-- Description: Adds CHECK constraint to lock canonical step_type values for
--              workflow_steps. Aligns the database with the official step types
--              registry. Reserves future types at the schema level.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- workflow_steps.step_type — Canonical Step Types
-- Foundation : agent | tool | approval | condition | event | delay
-- Reserved   : script | notification | parallel (require ADR before use)
-- -----------------------------------------------------------------------------
ALTER TABLE public.workflow_steps
  ADD CONSTRAINT chk_workflow_steps_step_type
    CHECK (
      step_type IN (
        'agent',
        'tool',
        'approval',
        'condition',
        'event',
        'delay',
        'script',
        'notification',
        'parallel'
      )
    );

-- -----------------------------------------------------------------------------
-- Notes
-- -----------------------------------------------------------------------------
-- 1. Foundation types (agent, tool, approval, condition, event, delay) are
--    available for use in workflow definitions as of SP-008.
-- 2. Reserved types (script, notification, parallel) are registered in the
--    constraint to prevent ad-hoc naming collisions. A dedicated ADR and CSA
--    approval are required before any reserved type may be used in production.
-- 3. Adding a new step_type value requires:
--    (a) a new ADR documenting its purpose and handler module
--    (b) updating workflow/ARCHITECTURE.md §4 (Canonical Step Types Registry)
--    (c) a migration adding the new value to this CHECK constraint
--    (d) CSA approval
-- =============================================================================
