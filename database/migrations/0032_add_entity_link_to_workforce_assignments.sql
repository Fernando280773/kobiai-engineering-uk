-- =============================================================================
-- Migration: 0032_add_entity_link_to_workforce_assignments.sql
-- Sprint:    SP-011 (BK-014)
-- ADR:       ADR-0011
-- ES:        ES-010
-- Description: Interface D — adds polymorphic entity reference columns
--              (entity_type, entity_id) to workforce_assignments. Allows a
--              workforce assignment to be linked to a specific BOS entity
--              (customer, contact, organization, opportunity, or activity).
--              This is a non-destructive ALTER TABLE on an existing table.
--              All existing rows are unaffected (both columns are nullable).
--
--              Note on referential integrity:
--              Polymorphic FK to multiple tables cannot be enforced at the
--              database level simultaneously. Application layer is responsible
--              for validating that entity_id exists in the correct table for
--              the given entity_type before insert. The CHECK constraint
--              limits valid entity_type values and the consistency constraint
--              ensures both columns are either populated or both NULL.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Add entity_type and entity_id columns to workforce_assignments
-- ---------------------------------------------------------------------------
ALTER TABLE public.workforce_assignments
  ADD COLUMN entity_type TEXT,
  ADD COLUMN entity_id   UUID;

-- ---------------------------------------------------------------------------
-- Constraints
-- ---------------------------------------------------------------------------

-- Restrict entity_type to valid BOS entity names
ALTER TABLE public.workforce_assignments
  ADD CONSTRAINT chk_workforce_assignments_entity_type
    CHECK (
      entity_type IS NULL OR
      entity_type IN (
        'customer',
        'contact',
        'organization',
        'opportunity',
        'activity'
      )
    );

-- Enforce consistency: both columns set or both null
ALTER TABLE public.workforce_assignments
  ADD CONSTRAINT chk_workforce_assignments_entity_consistency
    CHECK (
      (entity_type IS NULL AND entity_id IS NULL) OR
      (entity_type IS NOT NULL AND entity_id IS NOT NULL)
    );

-- ---------------------------------------------------------------------------
-- Index
-- ---------------------------------------------------------------------------
CREATE INDEX idx_workforce_assignments_entity
  ON public.workforce_assignments (entity_type, entity_id)
  WHERE entity_type IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Column documentation
-- ---------------------------------------------------------------------------
COMMENT ON COLUMN public.workforce_assignments.entity_type IS
  'Interface D: polymorphic BOS entity type that this assignment relates to. '
  'Valid values: customer, contact, organization, opportunity, activity. '
  'Must be paired with entity_id (consistency enforced by constraint). '
  'Application layer must validate entity_id existence in the correct table.';

COMMENT ON COLUMN public.workforce_assignments.entity_id IS
  'Interface D: UUID of the BOS entity record referenced by entity_type. '
  'No database-level FK enforced (polymorphic reference across multiple tables). '
  'Application layer is responsible for referential integrity validation.';
