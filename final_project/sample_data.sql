BEGIN;

-- Institutions
INSERT INTO institutions (id, name, type, city) VALUES
  (1, 'American University of Central Asia', 'university', 'Bishkek'),
  (2, 'Bishkek IT Park', 'company', 'Bishkek');

SELECT setval('institutions_id_seq', 2, true);

-- Users
INSERT INTO users (id, phone, name, institution_id, bio) VALUES
  (1, '+996500000001', 'Aziret', 1, 'Student and occasional driver.'),
  (2, '+996500000002', 'Aizada', 1, 'Student, prefers group taxi.'),
  (3, '+996500000003', 'Nurlan', 2, 'Developer at IT Park.'),
  (4, '+996500000004', 'Dana', 1, 'Frequent passenger.');

SELECT setval('users_id_seq', 4, true);

-- Vehicle brands
INSERT INTO vehicle_brands (id, name, country) VALUES
  (1, 'Toyota', 'Japan'),
  (2, 'Honda', 'Japan');

SELECT setval('vehicle_brands_id_seq', 2, true);

-- Vehicle models
INSERT INTO vehicle_models (id, brand_id, name, body_type, default_seats) VALUES
  (1, 1, 'Corolla', 'sedan', 4),
  (2, 2, 'Civic', 'sedan', 4);

SELECT setval('vehicle_models_id_seq', 2, true);

-- Locations
INSERT INTO locations (id, name, type, latitude, longitude, description) VALUES
  (1, 'Dordoi Plaza Parking', 'POINT', NULL, NULL, 'Popular pickup point'),
  (2, 'AUCA Main Entrance', 'POINT', NULL, NULL, 'Main gate of AUCA'),
  (3, 'Bishkek IT Park', 'POINT', NULL, NULL, 'IT Park office center');

SELECT setval('locations_id_seq', 3, true);

-- Vehicles
INSERT INTO vehicles (id, owner_id, model_id, plate_number, color, year, seats, is_verified) VALUES
  (1, 1, 1, '01KG777AAA', 'white', 2015, 4, TRUE);

SELECT setval('vehicles_id_seq', 1, true);

-- Routes
INSERT INTO routes (
    id, creator_id, institution_id, route_type,
    from_location, to_location, from_location_id, to_location_id,
    departure_time, price_per_ride, price_per_week, seats, notes
) VALUES
  (
    1,
    1,
    1,
    'DRIVER_ROUTE',
    'Dordoi Plaza Parking',
    'AUCA Main Entrance',
    1,
    2,
    '08:30',
    70.00,
    350.00,
    3,
    'Morning commute to AUCA, Mon-Fri.'
  ),
  (
    2,
    2,
    1,
    'GROUP_TAXI',
    'AUCA Main Entrance',
    'Dordoi Plaza Parking',
    2,
    1,
    '18:30',
    80.00,
    NULL,
    NULL,
    'Evening shared taxi to city center.'
  );

SELECT setval('routes_id_seq', 2, true);

-- Route schedule days
-- Route 1: Mon–Fri (1–5)
INSERT INTO route_schedule_days (route_id, weekday) VALUES
  (1,1),(1,2),(1,3),(1,4),(1,5);

-- Route 2: Mon, Wed, Fri
INSERT INTO route_schedule_days (route_id, weekday) VALUES
  (2,1),(2,3),(2,5);

-- Route members
-- Route 1: Aziret driver, Aizada & Dana passengers
INSERT INTO route_members (route_id, user_id, role_in_route, joined_at, is_active) VALUES
  (1,1,'DRIVER',    NOW() - INTERVAL '30 days', TRUE),
  (1,2,'PASSENGER', NOW() - INTERVAL '20 days', TRUE),
  (1,4,'PASSENGER', NOW() - INTERVAL '15 days', TRUE);

-- Route 2: all passengers
INSERT INTO route_members (route_id, user_id, role_in_route, joined_at, is_active) VALUES
  (2,2,'PASSENGER', NOW() - INTERVAL '10 days', TRUE),
  (2,3,'PASSENGER', NOW() - INTERVAL '10 days', TRUE),
  (2,4,'PASSENGER', NOW() - INTERVAL '7 days', TRUE);

-- Route stops
INSERT INTO route_stops (id, route_id, position_in_route, location_id, name, arrival_offset_minutes) VALUES
  (1, 1, 1, 1, 'Pickup at Dordoi Plaza', 0),
  (2, 1, 2, 2, 'Drop at AUCA', 25),
  (3, 2, 1, 2, 'Pickup at AUCA', 0),
  (4, 2, 2, 1, 'Drop at Dordoi Plaza', 25);

SELECT setval('route_stops_id_seq', 4, true);

-- Trips
INSERT INTO trips (id, route_id, trip_date, status, created_at) VALUES
  (1, 1, DATE '2025-12-01', 'COMPLETED', NOW() - INTERVAL '8 days'),
  (2, 1, DATE '2025-12-02', 'COMPLETED', NOW() - INTERVAL '7 days'),
  (3, 1, DATE '2025-12-03', 'SCHEDULED', NOW() - INTERVAL '1 days'),
  (4, 2, DATE '2025-12-01', 'COMPLETED', NOW() - INTERVAL '8 days'),
  (5, 2, DATE '2025-12-03', 'COMPLETED', NOW() - INTERVAL '6 days'),
  (6, 2, DATE '2025-12-04', 'SCHEDULED', NOW() - INTERVAL '1 days');

SELECT setval('trips_id_seq', 6, true);

-- Trip participants
INSERT INTO trip_participants (trip_id, user_id, status, rating_for_driver, rating_for_passenger, comment) VALUES
  (1,1,'GOING', NULL, NULL, 'Driver of the route.'),
  (1,2,'GOING', 5,    5,    'On time, polite.'),
  (1,4,'GOING', 5,    4,    'Slightly late.'),

  (2,1,'GOING', NULL, NULL, 'Driver.'),
  (2,2,'GOING', 5,    5,    'All good.'),
  (2,4,'NO_SHOW', NULL, NULL, 'Did not show up.'),

  (4,2,'GOING', NULL, 5,     'Shared taxi, no fixed driver.'),
  (4,3,'GOING', NULL, 4,     'Quiet passenger.'),
  (4,4,'GOING', NULL, 5,     'Very positive.'),

  (5,2,'GOING', NULL, 5,     'Regular passenger.'),
  (5,3,'GOING', NULL, 4,     'Regular passenger.'),
  (5,4,'NOT_GOING', NULL, NULL, 'Cancelled.');

-- Payment methods
INSERT INTO payment_methods (id, user_id, method_type, details_masked, is_default) VALUES
  (1, 2, 'CARD', '**** **** **** 1234', TRUE),
  (2, 3, 'CASH', NULL, TRUE);

SELECT setval('payment_methods_id_seq', 2, true);

-- Payments
INSERT INTO payments (id, trip_id, payer_id, method_id, amount, status, created_at) VALUES
  (1, 4, 2, 1, 80.00, 'PAID', NOW() - INTERVAL '6 days'),
  (2, 5, 2, 1, 80.00, 'PAID', NOW() - INTERVAL '4 days'),
  (3, 5, 3, 2, 80.00, 'PAID', NOW() - INTERVAL '4 days');

SELECT setval('payments_id_seq', 3, true);

-- Promo codes
INSERT INTO promo_codes (id, code, description, discount_percent, active_from, active_until, max_uses_total, max_uses_per_user, is_active) VALUES
  (1, 'WELCOME10', 'Welcome promo for new users', 10, DATE '2025-11-01', DATE '2025-12-31', 100, 1, TRUE);

SELECT setval('promo_codes_id_seq', 1, true);

-- User promo usage
INSERT INTO user_promo_codes (user_id, promo_code_id, used_at, trip_id) VALUES
  (2, 1, NOW() - INTERVAL '6 days', 4);

-- Notifications
INSERT INTO notifications (user_id, type, payload, created_at) VALUES
  (2, 'TRIP_REMINDER', '{"trip_id": 6, "text": "Don''t forget your evening trip!"}', NOW() - INTERVAL '1 day'),
  (4, 'NEW_ROUTE_MEMBER', '{"route_id": 1, "text": "New passenger joined your route."}', NOW() - INTERVAL '2 days');

-- Support tickets
INSERT INTO support_tickets (id, user_id, subject, description, status, created_at, updated_at) VALUES
  (1, 4, 'Driver was late', 'Driver arrived 15 minutes late today.', 'OPEN', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

SELECT setval('support_tickets_id_seq', 1, true);

-- Audit logs
INSERT INTO audit_logs (user_id, action, entity_type, entity_id, created_at, meta) VALUES
  (1, 'CREATE_ROUTE', 'route', 1, NOW() - INTERVAL '30 days', '{"notes": "Morning route created"}'),
  (2, 'JOIN_ROUTE', 'route', 1, NOW() - INTERVAL '20 days', '{"role": "PASSENGER"}');

COMMIT;
