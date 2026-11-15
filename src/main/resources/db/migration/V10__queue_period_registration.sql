ALTER TABLE queue_entries
  ADD COLUMN queue_period varchar(12) NOT NULL DEFAULT 'MORNING'
  CHECK (queue_period IN ('MORNING','AFTERNOON','EVENING','NIGHT'));

ALTER TABLE queue_entries
  DROP CONSTRAINT queue_entries_branch_id_queue_date_mobile_key;

ALTER TABLE queue_entries
  ADD CONSTRAINT uq_queue_mobile_period
  UNIQUE(branch_id, queue_date, mobile, queue_period);

CREATE INDEX ix_queue_period
  ON queue_entries(clinic_id, branch_id, queue_date, queue_period, status, token_number);
