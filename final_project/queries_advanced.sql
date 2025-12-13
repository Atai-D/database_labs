-- =========================================================
--  ADVANCED SQL QUERIES
-- =========================================================

-- 1. Count trips per route and completed trips
SELECT
    r.id AS route_id,
    r.route_type,
    r.from_location,
    r.to_location,
    COUNT(t.id) AS total_trips,
    COUNT(*) FILTER (WHERE t.status = 'COMPLETED') AS completed_trips
FROM routes r
LEFT JOIN trips t ON t.route_id = r.id
GROUP BY r.id, r.route_type, r.from_location, r.to_location
ORDER BY r.id;

-- 2. Number of GOING participants per trip
SELECT
    t.id AS trip_id,
    t.trip_date,
    r.id AS route_id,
    r.from_location,
    r.to_location,
    COUNT(*) FILTER (WHERE tp.status = 'GOING') AS passenger_count
FROM trips t
JOIN routes r ON r.id = t.route_id
LEFT JOIN trip_participants tp ON tp.trip_id = t.id
GROUP BY t.id, t.trip_date, r.id, r.from_location, r.to_location
ORDER BY t.trip_date, t.id;

-- 3. Average passenger rating per user
SELECT
    u.id AS user_id,
    u.name,
    AVG(tp.rating_for_passenger) AS avg_passenger_rating,
    COUNT(tp.rating_for_passenger) AS rating_count
FROM users u
JOIN trip_participants tp ON tp.user_id = u.id
WHERE tp.rating_for_passenger IS NOT NULL
GROUP BY u.id, u.name
HAVING COUNT(tp.rating_for_passenger) >= 1
ORDER BY avg_passenger_rating DESC;

-- 4. Completed trips and revenue per route
SELECT
    r.id AS route_id,
    r.from_location,
    r.to_location,
    COUNT(DISTINCT t.id) FILTER (WHERE t.status = 'COMPLETED') AS completed_trips,
    COALESCE(SUM(p.amount) FILTER (WHERE p.status = 'PAID'), 0) AS total_revenue
FROM routes r
LEFT JOIN trips t ON t.route_id = r.id
LEFT JOIN payments p ON p.trip_id = t.id AND p.status = 'PAID'
GROUP BY r.id, r.from_location, r.to_location
ORDER BY total_revenue DESC NULLS LAST;

-- 5. Total participations and NO_SHOW count per user
SELECT
    u.id AS user_id,
    u.name,
    COUNT(tp.trip_id) AS total_participations,
    COUNT(*) FILTER (WHERE tp.status = 'NO_SHOW') AS no_show_count
FROM users u
LEFT JOIN trip_participants tp ON tp.user_id = u.id
GROUP BY u.id, u.name
ORDER BY total_participations DESC, no_show_count DESC;

-- 6. Statistics by institution: routes, trips, unique trip users
SELECT
    i.id,
    i.name,
    COUNT(DISTINCT r.id) AS route_count,
    COUNT(DISTINCT t.id) AS trip_count,
    COUNT(DISTINCT tp.user_id) AS unique_trip_users
FROM institutions i
LEFT JOIN routes r ON r.institution_id = i.id
LEFT JOIN trips t ON t.route_id = r.id
LEFT JOIN trip_participants tp ON tp.trip_id = t.id
GROUP BY i.id, i.name
ORDER BY i.id;

-- 7. Window function: rank routes by number of completed trips
WITH route_trip_stats AS (
    SELECT
        r.id AS route_id,
        r.from_location,
        r.to_location,
        COUNT(*) FILTER (WHERE t.status = 'COMPLETED') AS completed_trips
    FROM routes r
    LEFT JOIN trips t ON t.route_id = r.id
    GROUP BY r.id, r.from_location, r.to_location
)
SELECT
    route_id,
    from_location,
    to_location,
    completed_trips,
    RANK() OVER (ORDER BY completed_trips DESC) AS route_rank
FROM route_trip_stats
ORDER BY route_rank, route_id;

-- 8. Last completed trip date per user
SELECT
    u.id AS user_id,
    u.name,
    MAX(t.trip_date) FILTER (WHERE t.status = 'COMPLETED') AS last_completed_trip_date
FROM users u
LEFT JOIN trip_participants tp ON tp.user_id = u.id
LEFT JOIN trips t ON t.id = tp.trip_id
GROUP BY u.id, u.name
ORDER BY user_id;

-- 9. Trips where GOING participants exceed seat capacity (overbooking)
SELECT
    t.id AS trip_id,
    t.trip_date,
    r.id AS route_id,
    r.from_location,
    r.to_location,
    r.seats,
    COUNT(*) FILTER (WHERE tp.status = 'GOING') AS going_count
FROM trips t
JOIN routes r ON r.id = t.route_id
LEFT JOIN trip_participants tp ON tp.trip_id = t.id
WHERE r.route_type = 'DRIVER_ROUTE'
GROUP BY t.id, t.trip_date, r.id, r.from_location, r.to_location, r.seats
HAVING r.seats IS NOT NULL
   AND COUNT(*) FILTER (WHERE tp.status = 'GOING') > r.seats
ORDER BY t.trip_date, t.id;

-- 10. Promo code usage statistics
SELECT
    pc.code,
    pc.discount_percent,
    COUNT(upc.user_id) AS total_usages,
    COUNT(DISTINCT upc.user_id) AS distinct_users
FROM promo_codes pc
LEFT JOIN user_promo_codes upc ON upc.promo_code_id = pc.id
GROUP BY pc.id, pc.code, pc.discount_percent
ORDER BY total_usages DESC NULLS LAST;
