ALTER TABLE branches
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS ix_branches_clinic_active_created
  ON branches(clinic_id, active, created_at);
