CREATE TABLE clinic_staff_profiles(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  branch_id uuid NOT NULL REFERENCES branches(id),
  user_id uuid NOT NULL UNIQUE REFERENCES users(id),
  staff_type varchar(20) NOT NULL CHECK(staff_type IN ('DOCTOR','RECEPTIONIST')),
  employee_code varchar(60),
  registration_number varchar(120),
  qualification varchar(300),
  specialization varchar(200),
  designation varchar(120),
  phone varchar(30),
  email varchar(200),
  profile_details jsonb NOT NULL DEFAULT '{}'::jsonb,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(clinic_id,employee_code)
);
INSERT INTO clinic_staff_profiles(clinic_id,branch_id,user_id,staff_type,phone,email,designation)
SELECT clinic_id,branch_id,id,CASE WHEN role='PRACTITIONER' THEN 'DOCTOR' ELSE 'RECEPTIONIST' END,phone,username,CASE WHEN role='PRACTITIONER' THEN 'Doctor' ELSE 'Receptionist' END
FROM users WHERE clinic_id IS NOT NULL AND branch_id IS NOT NULL AND role IN ('PRACTITIONER','RECEPTIONIST')
ON CONFLICT(user_id) DO NOTHING;

CREATE TABLE patient_certificates(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  branch_id uuid NOT NULL REFERENCES branches(id),
  customer_id uuid NOT NULL REFERENCES customers(id),
  queue_entry_id uuid REFERENCES queue_entries(id),
  certificate_number varchar(80),
  certificate_type varchar(60) NOT NULL,
  template_key varchar(100),
  title varchar(250) NOT NULL,
  body text NOT NULL,
  valid_from date,
  valid_until date,
  certificate_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  status varchar(20) NOT NULL DEFAULT 'DRAFT' CHECK(status IN ('DRAFT','ISSUED','VOID')),
  created_by uuid NOT NULL REFERENCES users(id),
  approved_by uuid REFERENCES users(id),
  issued_at timestamptz,
  voided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(clinic_id,certificate_number)
);
CREATE INDEX ix_patient_certificates ON patient_certificates(clinic_id,customer_id,created_at DESC);
