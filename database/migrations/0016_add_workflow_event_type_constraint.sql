-- =============================================================================
-- Migration: 0016_add_workflow_event_type_constraint.sql
-- Sprint: SP-008 (Correction 3 — Canonical Event Catalogue)
-- Implements: ADR-0008 + workflow/ARCHITECTURE.md Appendix A
-- Description: Adds CHECK constraint to lock canonical event_type values for
--              workflow_events. Enforces the dot-notation naming convention.
--              Aligns the database with the official Canonical Event Catalogue.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- workflow_events.event_type — Canonical Event Types
-- Naming convention: {domain}.{action} — lowercase, dot-separated
--
-- Workflow lifecycle (4): workflow.started | workflow.completed |
--                         workflow.failed  | workflow.cancelled
--
-- Step lifecycle (7):     step.started           | step.completed  |
--                         step.failed            | step.skipped    |
--                         step.retry.scheduled   | step.retry.succeeded |
--                         step.retry.exhausted
--
-- Approval lifecycle (5): approval.requested | approval.granted  |
--                         approval.rejected  | approval.timeout  |
--                         approval.completed
--
-- Event wait (3):         event.wait.started | event.received | event.timeout
-- -----------------------------------------------------------------------------
ALTER TABLE public.workflow_events
  ADD CONSTRAINT chk_workflow_events_event_type
    CHECK (
      event_type IN (
        -- Workflow lifecycle
        'workflow.started',
        'workflow.completed',
        'workflow.failed',
        'workflow.cancelled',
        -- Step lifecycle
        'step.started',
        'step.completed',
        'step.failed',
        'step.skipped',
        'step.retry.scheduled',
        'step.retry.succeeded',
        'step.retry.exhausted',
        -- Approval lifecycle
        'approval.requested',
        'approval.granted',
        'approval.rejected',
        'approval.timeout',
        'approval.completed',
        -- Event wait lifecycle
        'event.wait.started',
        'event.received',
        'event.timeout'
      )
    );

-- -----------------------------------------------------------------------------
-- Notes
-- -----------------------------------------------------------------------------
-- 1. This constraint is additive — it does not modify existing rows.
-- 2. workflow_events remains immutable — trg_immutable_workflow_events blocks
--    all UPDATE and DELETE. This constraint adds a second layer of enforcement
--    ensuring only canonical event types can ever be inserted.
-- 3. Adding a new event_type value requires:
--    (a) a new ADR documenting its purpose and the emitting module
--    (b) updating workflow/ARCHITECTURE.md Appendix A
--    (c) a migration adding the new value to this CHECK constraint
--    (d) CSA approval
-- 4. The dot-notation naming convention ({domain}.{action}) must be maintained
--    for all future event types.
-- =============================================================================
