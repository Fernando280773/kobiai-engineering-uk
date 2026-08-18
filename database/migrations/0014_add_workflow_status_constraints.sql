-- =============================================================================
-- Migration: 0014_add_workflow_status_constraints.sql
-- Sprint: SP-008 (Correction 1 — Canonical Workflow Lifecycle State Machine)
-- Implements: ADR-0008 + ES-007 + workflow/ARCHITECTURE.md §3
-- Description: Adds CHECK constraints to lock canonical status values for
--              workflows.status and workflow_executions.execution_status.
--              Aligns the database with the official two-level state machine.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- workflows.status — Definition Lifecycle
-- Canonical values: draft | published | deprecated
-- -----------------------------------------------------------------------------
ALTER TABLE public.workflows
  ADD CONSTRAINT chk_workflows_status
    CHECK (status IN ('draft', 'published', 'deprecated'));

-- -----------------------------------------------------------------------------
-- workflow_executions.execution_status — Execution Lifecycle
-- Canonical values:
--   Active    : pending | running
--   Suspended : waiting_approval | waiting_event | retry
--   Terminal  : completed | cancelled | failed
-- -----------------------------------------------------------------------------
ALTER TABLE public.workflow_executions
  ADD CONSTRAINT chk_workflow_executions_status
    CHECK (
      execution_status IN (
        'pending',
        'running',
        'waiting_approval',
        'waiting_event',
        'retry',
        'completed',
        'cancelled',
        'failed'
      )
    );

-- -----------------------------------------------------------------------------
-- Notes
-- -----------------------------------------------------------------------------
-- 1. These constraints are additive — they do not modify existing rows.
-- 2. The value 'paused' is deprecated. The canonical suspended states are:
--    'waiting_approval', 'waiting_event', and 'retry'.
-- 3. Both tables remain under RLS. These constraints add a second enforcement
--    layer at the storage level — applications cannot persist invalid states.
-- 4. workflow_executions retains its immutability triggers:
--    trg_immutable_workflow_executions (UPDATE/DELETE blocked)
--    These constraints and the triggers are complementary.
-- =============================================================================
