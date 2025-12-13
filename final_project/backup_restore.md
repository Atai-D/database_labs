# Backup and Restore Strategy (PostgreSQL)

This document describes how to back up and restore the **Carpool & Group Taxi Management System** database.

## 1. Assumptions

- Database name: `carpool_db`
- PostgreSQL user: `postgres` (or another user with proper permissions)
- Schema is created from `schema.sql`
- Sample data is loaded from `sample_data.sql`

---

## 2. Creating a Backup

### 2.1. Plain SQL Backup

```bash
pg_dump -U postgres -d carpool_db -F p -f carpool_db_backup.sql
