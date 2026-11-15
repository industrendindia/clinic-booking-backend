# Clinic Appointments API

Spring Boot and PostgreSQL backend for the CareNest multi-clinic appointment platform.

## Requirements

- Java 21
- Maven 3.9+
- PostgreSQL 16+

## Configuration

Supply these environment variables in production:

- `DB_URL`
- `DB_USER`
- `DB_PASSWORD`
- `JWT_SECRET`
- `DB_MAX_POOL_SIZE` (defaults to `15`)

All database objects are created in the `clinic_app` schema by Flyway.
For production, also set PostgreSQL's hard role limit with `ALTER ROLE clinic_app_user CONNECTION LIMIT 15;`.

## Build

```bash
mvn clean package
```

## Run

```bash
java -jar target/clinic-api-1.0.0.jar
```

