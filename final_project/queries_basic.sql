-- =========================================================
--  BASIC SQL QUERIES
-- =========================================================

-- 1. List all users with institutions
SELECT
    u.id,
    u.name,
    u.phone,
    i.name AS institution_name,
    i.city AS institution_city
FROM users u
LEFT JOIN institutions i ON u.institution_id = i.id
ORDER BY u.id;

-- 2. List all institutions with number of users
SELECT
    i.id,
    i.name,
    i.type,
    COUNT(u.id) AS user_count
FROM institutions i
LEFT JOIN users u ON u.institution_id = i.id
GROUP BY i.id, i.name, i.type
ORDER BY i.id;

-- 3. List all routes with creator, institution and basic info
SELECT
    r.id,
    r.route_type,
    r.from_location,
    r.to_location,
    r.departure_time,
    r.price_per_ride,
    r.seats,
    r.is_active,
    u.name AS creator_name,
    i.name AS institution_name
FROM routes r
JOIN users u ON r.creator_id = u.id
LEFT JOIN institutions i ON r.institution_id = i.id
ORDER BY r.id;

-- 4. Show route schedules (weekdays as array)
SELECT
    r.id AS route_id,
    r.from_location,
    r.to_location,
    ARRAY_AGG(rs.weekday ORDER BY rs.weekday) AS weekdays
FROM routes r
JOIN route_schedule_days rs ON rs.route_id = r.id
GROUP BY r.id, r.from_location, r.to_location
ORDER BY r.id;

-- 5. List members of each route with roles
SELECT
    r.id AS route_id,
    r.route_type,
    r.from_location,
    r.to_location,
    rm.user_id,
    u.name AS user_name,
    rm.role_in_route,
    rm.joined_at,
    rm.is_active
FROM routes r
JOIN route_members rm ON rm.route_id = r.id
JOIN users u ON u.id = rm.user_id
ORDER BY r.id, rm.role_in_route, u.name;

-- 6. Show trips with route details
SELECT
    t.id AS trip_id,
    t.trip_date,
    t.status,
    r.id AS route_id,
    r.route_type,
    r.from_location,
    r.to_location
FROM trips t
JOIN routes r ON t.route_id = r.id
ORDER BY t.trip_date, t.id;

-- 7. Show participants of trip_id = 1
SELECT
    t.id AS trip_id,
    t.trip_date,
    u.id AS user_id,
    u.name AS user_name,
    tp.status,
    tp.rating_for_driver,
    tp.rating_for_passenger,
    tp.comment
FROM trips t
JOIN trip_participants tp ON tp.trip_id = t.id
JOIN users u ON u.id = tp.user_id
WHERE t.id = 1
ORDER BY u.id;

-- 8. Find all routes where user_id = 2 is a member
SELECT
    u.id AS user_id,
    u.name AS user_name,
    r.id AS route_id,
    r.route_type,
    r.from_location,
    r.to_location,
    rm.role_in_route,
    rm.is_active
FROM users u
JOIN route_members rm ON rm.user_id = u.id
JOIN routes r ON r.id = rm.route_id
WHERE u.id = 2
ORDER BY r.id;

-- 9. List scheduled future trips for user_id = 2
SELECT
    u.id AS user_id,
    u.name AS user_name,
    t.id AS trip_id,
    t.trip_date,
    t.status,
    r.from_location,
    r.to_location
FROM users u
JOIN trip_participants tp ON tp.user_id = u.id
JOIN trips t ON t.id = tp.trip_id
JOIN routes r ON r.id = t.route_id
WHERE u.id = 2
  AND t.status = 'SCHEDULED'
ORDER BY t.trip_date;

-- 10. List vehicles and their owners
SELECT
    v.id AS vehicle_id,
    v.plate_number,
    v.color,
    v.year,
    v.seats,
    v.is_verified,
    u.name AS owner_name,
    vb.name AS brand_name,
    vm.name AS model_name
FROM vehicles v
JOIN users u ON v.owner_id = u.id
LEFT JOIN vehicle_models vm ON v.model_id = vm.id
LEFT JOIN vehicle_brands vb ON vm.brand_id = vb.id
ORDER BY v.id;
