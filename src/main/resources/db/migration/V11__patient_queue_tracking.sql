ALTER TABLE queue_entries
  ADD COLUMN tracking_token uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE;

CREATE INDEX ix_queue_tracking
  ON queue_entries(clinic_id, tracking_token);
