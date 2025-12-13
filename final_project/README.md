# Carpool & Group Taxi Management System

**Final Project – Database Systems (PostgreSQL Implementation)**

## 1. Project Overview

This project implements a full-featured relational database system for managing **regular shared rides** and **group taxi** services for students and employees of institutions (e.g., AUCA, IT Park, offices).

The system supports:

- Institutions and users
- Vehicles and vehicle catalog (brands & models)
- Locations and route stops
- Routes and weekly schedules
- Trips and trip participants
- Payments and payment methods
- Promo codes and their usage
- Route invitations
- Notifications
- Support tickets
- Audit logs

The project is designed to satisfy the final project requirements:

- ER-diagram and normalized database schema
- PostgreSQL implementation
- Basic and advanced SQL queries
- Demonstration of transactions and indexing
- Backup and restore strategy

---

## 2. Functional Scope

### Core Carpool Features

- **Institutions**

  - Universities, companies, tech parks.
  - Users and routes may be associated with an institution.

- **Users**

  - Drivers and passengers.
  - Linked to institutions (optional).
  - Can create routes, participate in trips, own vehicles, receive notifications, open support tickets.

- **Routes**

  - Type: `DRIVER_ROUTE` or `GROUP_TAXI`.
  - From/To locations (as text and/or references to `locations`).
  - Departure time (daily).
  - Weekly schedule (`route_schedule_days`).
  - Seat capacity (for driver routes).
  - Pricing: per ride and/or per week.
  - Route stops (`route_stops`) with ordered positions and optional time offsets.

- **Membership & Trips**
  - `route_members`: who belongs to which route and with what role (`DRIVER` / `PASSENGER`).
  - `trips`: concrete rides on specific dates with status.
  - `trip_participants`: user participation with status (`GOING`, `NOT_GOING`, `NO_SHOW`) and ratings.

### Extended Features

- **Vehicles & Catalog**

  - `vehicle_brands` and `vehicle_models`: normalized catalog of car brands and models.
  - `vehicles`: user-owned cars, with plate number, color, year, seat count, verification flag.

- **Locations & Stops**

  - `locations`: named locations or areas with optional coordinates.
  - `route_stops`: ordered list of stops per route (with offset in minutes from departure).

- **Invitations**

  - `route_invites`: invitation tokens to join a route; tracks invited users, status, expiration.

- **Payments**

  - `payment_methods`: user’s payment methods (`CASH`, `CARD`, `E_WALLET`).
  - `payments`: payments for trips (payer, method, amount, status).

- **Promo Codes**

  - `promo_codes`: promo codes with discount percent, validity period, and usage limits.
  - `user_promo_codes`: track which user used which promo code and for which trip.

- **Notifications**

  - `notifications`: notification queue for users with a JSON payload and read timestamp.

- **Support & Audit**
  - `support_tickets`: user support requests with status workflow.
  - `audit_logs`: generic log of important actions with JSON metadata.

This extended schema makes the project look like a realistic backend for a mobility/carpool application.

---

## 3. ER Model – Main Entities and Relationships

### Core Entities

- **Institution**

  - 1 – N with `users`
  - 1 – N with `routes`

- **User**

  - Optional FK to `institutions`.
  - 1 – N as `creator` of `routes`.
  - M – N with `routes` via `route_members`.
  - M – N with `trips` via `trip_participants`.
  - 1 – N with `vehicles`.
  - 1 – N with `payment_methods`.
  - 1 – N with `notifications`, `support_tickets`, `audit_logs`.

- **Route**

  - FK to `users` (creator).
  - Optional FK to `institutions`.
  - Optional FK to `locations` as from/to.
  - 1 – N with `route_schedule_days`.
  - 1 – N with `route_members`.
  - 1 – N with `route_stops`.
  - 1 – N with `trips`.
  - 1 – N with `route_invites`.

- **Trip**
  - FK to `routes`.
  - 1 – N with `trip_participants`.
  - 1 – N with `payments`.
  - Optional FK from `user_promo_codes`.

---

## 4. Normalization

- All reference data is placed into separate tables (`vehicle_brands`, `vehicle_models`, `locations`, `promo_codes`).
- Many-to-many relationships are resolved through link tables (`route_members`, `trip_participants`, `user_promo_codes`).
- Non-key attributes depend only on the (full) primary key and not on each other (3NF).

---

## 5. Implementation

The full PostgreSQL DDL is in:

- `schema.sql`

Sample data for testing:

- `sample_data.sql`

Queries:

- `queries_basic.sql` – simple SELECTs and joins.
- `queries_advanced.sql` – analytics and window functions.

Transactions:

- `transactions.sql` – example transactional scenarios.

Backup strategy:

- `backup_restore.md`

---

## 6. Project Structure

Recommended repository layout:

```text
course_project/
  README.md
  schema.sql
  sample_data.sql
  queries_basic.sql
  queries_advanced.sql
  transactions.sql
  backup_restore.md
  er_diagram_dbdiagram.txt   -- ER diagram text for dbdiagram.io
```

## 7. Presentation

The project presentation is available at the following link:

https://www.canva.com/design/DAG7be77CiU/LtbVevDKqS-JCaQJsokVuw/edit?utm_content=DAG7be77CiU&utm_campaign=designshare&utm_medium=link2&utm_source=sharebutton

## 8. Academic Pledge

I pledge that I will meet all project deadlines as required by the course.
I understand that failure to meet deadlines or course requirements may result in disciplinary action, and I accept full responsibility for this.
