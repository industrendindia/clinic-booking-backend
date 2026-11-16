ALTER TABLE users
  ADD COLUMN IF NOT EXISTS email varchar(200);

CREATE INDEX IF NOT EXISTS ix_users_email
  ON users(lower(email));
