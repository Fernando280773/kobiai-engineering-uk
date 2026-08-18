-- =============================================================================
-- Migration: 0029_add_bos_event_catalogue_constraints.sql
-- Sprint:    SP-011 (BK-014)
-- ADR:       ADR-0011
-- ES:        ES-010
-- Description: Formally promotes STD-BOS-005 (BOS Event Catalogue) from stub
--              to production standard. The CHECK constraint on bos_event_routing
--              was already applied in migration 0028. This migration is the
--              formal governance record of the catalogue's promotion and adds
--              a comment to the constraint for documentation purposes.
--
--              The 23 canonical BOS events (STD-BOS-005):
--
--              Organization:  organization.created, organization.updated,
--                             organization.archived
--              Customer:      customer.created, customer.updated,
--                             customer.status_changed, customer.archived
--              Contact:       contact.created, contact.updated,
--                             contact.archived
--              Opportunity:   opportunity.created, opportunity.stage_changed,
--                             opportunity.won, opportunity.lost,
--                             opportunity.archived
--              Activity:      activity.call_logged, activity.email_logged,
--                             activity.meeting_scheduled, activity.note_added,
--                             activity.task_created, activity.completed
--              Dashboard:     dashboard.created, dashboard.updated
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Governance comment on the event type constraint
-- ---------------------------------------------------------------------------
-- The canonical BOS event catalogue is formally defined in:
--   business/events/README.md   (human-readable catalogue)
--   business/STANDARDS.md       (STD-BOS-005)
--
-- Adding new event types requires:
--   1. An approved Architecture Change Request (ACR)
--   2. An update to the CHECK constraint in bos_event_routing
--   3. An update to business/events/README.md and business/STANDARDS.md
-- ---------------------------------------------------------------------------

COMMENT ON TABLE public.bos_event_routing IS
  'Interface A: maps canonical BOS event types (STD-BOS-005) to Workflow definitions. '
  'Queried when a BOS event fires to determine which workflow(s) to trigger. '
  'Canonical event catalogue: business/events/README.md';

COMMENT ON COLUMN public.bos_event_routing.event_type IS
  'Canonical BOS event name following STD-EVT-001 dot-notation (entity.action). '
  'Valid values are defined by chk_bos_event_routing_event_type and STD-BOS-005. '
  'Adding new event types requires an approved ACR.';

COMMENT ON COLUMN public.bos_event_routing.workflow_id IS
  'The workflow to trigger when event_type fires in this workspace. '
  'Only published workflows may be triggered (enforced at application layer).';

COMMENT ON COLUMN public.bos_event_routing.is_active IS
  'Allows a routing rule to be disabled without deletion. '
  'Disabled rules (is_active = false) are not evaluated at runtime.';
