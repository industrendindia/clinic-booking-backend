-- Global values are fallbacks only. All clinic choices live in clinic-owned tables below.
CREATE TABLE platform_configuration(
  id smallint PRIMARY KEY DEFAULT 1 CHECK(id=1),
  default_sms_number varchar(30),
  default_whatsapp_number varchar(30),
  settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO platform_configuration(id) VALUES(1) ON CONFLICT DO NOTHING;

CREATE TABLE clinic_communication_settings(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  channel varchar(20) NOT NULL CHECK(channel IN ('SMS','WHATSAPP')),
  enabled boolean NOT NULL DEFAULT false,
  sender_source varchar(20) NOT NULL DEFAULT 'APP_DEFAULT' CHECK(sender_source IN ('APP_DEFAULT','CLINIC_NUMBER')),
  clinic_number varchar(30),
  provider_name varchar(80),
  provider_account_ref varchar(160),
  templates jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(clinic_id,channel)
);
INSERT INTO clinic_communication_settings(clinic_id,channel,enabled,sender_source,clinic_number)
SELECT id,'SMS',sms_enabled,CASE WHEN sms_sender IS NULL THEN 'APP_DEFAULT' ELSE 'CLINIC_NUMBER' END,sms_sender FROM clinics
UNION ALL
SELECT id,'WHATSAPP',whatsapp_enabled,CASE WHEN whatsapp_sender IS NULL THEN 'APP_DEFAULT' ELSE 'CLINIC_NUMBER' END,whatsapp_sender FROM clinics;

CREATE TABLE clinic_sessions(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  branch_id uuid NOT NULL REFERENCES branches(id),
  code varchar(20) NOT NULL CHECK(code IN ('MORNING','AFTERNOON','EVENING','NIGHT')),
  display_name varchar(80) NOT NULL,
  starts_at time NOT NULL,
  ends_at time NOT NULL,
  active boolean NOT NULL DEFAULT true,
  sort_order int NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(branch_id,code),
  UNIQUE(id,clinic_id)
);
INSERT INTO clinic_sessions(clinic_id,branch_id,code,display_name,starts_at,ends_at,sort_order)
SELECT clinic_id,id,'MORNING','Morning','00:00','12:00',1 FROM branches
UNION ALL SELECT clinic_id,id,'AFTERNOON','Afternoon','12:00','17:00',2 FROM branches
UNION ALL SELECT clinic_id,id,'EVENING','Evening','17:00','21:00',3 FROM branches
UNION ALL SELECT clinic_id,id,'NIGHT','Night','21:00','00:00',4 FROM branches;

CREATE TABLE clinic_qr_codes(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL UNIQUE REFERENCES clinics(id),
  public_code uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  purpose varchar(30) NOT NULL DEFAULT 'PATIENT_CHECKIN',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  rotated_at timestamptz
);
INSERT INTO clinic_qr_codes(clinic_id,active) SELECT id,public_checkin_enabled FROM clinics;

CREATE TABLE daily_queue_counters(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  branch_id uuid NOT NULL REFERENCES branches(id),
  counter_date date NOT NULL,
  last_issued_token int NOT NULL DEFAULT 0,
  current_token int NOT NULL DEFAULT 0,
  reset_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(branch_id,counter_date)
);

ALTER TABLE customers ADD COLUMN age int CHECK(age BETWEEN 0 AND 130);
ALTER TABLE queue_entries ADD COLUMN customer_id uuid REFERENCES customers(id);
ALTER TABLE queue_entries ADD COLUMN session_id uuid REFERENCES clinic_sessions(id);
CREATE INDEX ix_customers_phone ON customers(clinic_id,phone);

CREATE TABLE prescriptions(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  branch_id uuid NOT NULL REFERENCES branches(id),
  customer_id uuid NOT NULL REFERENCES customers(id),
  queue_entry_id uuid REFERENCES queue_entries(id),
  doctor_user_id uuid NOT NULL REFERENCES users(id),
  diagnosis text,
  clinical_notes text,
  advice text,
  follow_up_on date,
  status varchar(20) NOT NULL DEFAULT 'DRAFT' CHECK(status IN ('DRAFT','SIGNED','VOID')),
  signed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_prescriptions_patient ON prescriptions(clinic_id,customer_id,created_at DESC);

CREATE TABLE prescription_items(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  prescription_id uuid NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  medicine_name varchar(200) NOT NULL,
  dosage varchar(100),
  frequency varchar(100),
  duration varchar(100),
  instructions varchar(500),
  sort_order int NOT NULL DEFAULT 0
);

CREATE TABLE patient_history_events(
  id bigserial PRIMARY KEY,
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  branch_id uuid REFERENCES branches(id),
  customer_id uuid REFERENCES customers(id),
  queue_entry_id uuid REFERENCES queue_entries(id),
  event_type varchar(50) NOT NULL,
  event_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  actor_user_id uuid REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_patient_history ON patient_history_events(clinic_id,customer_id,created_at DESC);

CREATE TABLE message_delivery_events(
  id bigserial PRIMARY KEY,
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  outbox_id bigint NOT NULL REFERENCES message_outbox(id),
  channel varchar(20) NOT NULL,
  provider_message_id varchar(200),
  delivery_status varchar(30) NOT NULL,
  provider_response jsonb NOT NULL DEFAULT '{}'::jsonb,
  occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_message_delivery_clinic ON message_delivery_events(clinic_id,occurred_at DESC);

CREATE TABLE clinic_settings(
  clinic_id uuid PRIMARY KEY REFERENCES clinics(id),
  settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_by uuid REFERENCES users(id),
  updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO clinic_settings(clinic_id) SELECT id FROM clinics;

-- Existing payment rows already represent receipts; this index makes patient receipt history efficient.
CREATE INDEX IF NOT EXISTS ix_payments_patient_history ON payments(clinic_id,customer_id,created_at DESC);
