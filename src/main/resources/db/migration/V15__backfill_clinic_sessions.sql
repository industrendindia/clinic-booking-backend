INSERT INTO clinic_sessions(clinic_id,branch_id,code,display_name,starts_at,ends_at,sort_order)
SELECT b.clinic_id,b.id,s.code,s.display_name,s.starts_at,s.ends_at,s.sort_order
FROM branches b
CROSS JOIN (VALUES
  ('MORNING','Morning',TIME '00:00',TIME '12:00',1),
  ('AFTERNOON','Afternoon',TIME '12:00',TIME '17:00',2),
  ('EVENING','Evening',TIME '17:00',TIME '21:00',3),
  ('NIGHT','Night',TIME '21:00',TIME '00:00',4)
) s(code,display_name,starts_at,ends_at,sort_order)
ON CONFLICT(branch_id,code) DO NOTHING;
