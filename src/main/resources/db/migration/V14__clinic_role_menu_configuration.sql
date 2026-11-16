CREATE TABLE clinic_role_menu_configuration(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id uuid NOT NULL REFERENCES clinics(id),
  role varchar(30) NOT NULL CHECK(role IN ('RECEPTIONIST','PRACTITIONER')),
  menu_key varchar(50) NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(clinic_id,role,menu_key)
);

INSERT INTO clinic_role_menu_configuration(clinic_id,role,menu_key,enabled)
SELECT c.id,r.role,m.menu_key,true
FROM clinics c
CROSS JOIN (VALUES ('RECEPTIONIST'),('PRACTITIONER')) r(role)
CROSS JOIN (VALUES
 ('DASHBOARD'),('MANAGE_APPOINTMENTS'),('CUSTOMERS'),('PRACTITIONERS'),
 ('SERVICES'),('ROOMS'),('PAYMENTS'),('ATTENDANCE'),('CERTIFICATES'),('SETTINGS')
) m(menu_key);

CREATE INDEX ix_clinic_role_menu
  ON clinic_role_menu_configuration(clinic_id,role,enabled);
