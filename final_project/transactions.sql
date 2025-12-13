-- =========================================================
--  TRANSACTIONS EXAMPLES
-- =========================================================

-- 1. Book a user into a trip with seat availability check
--    Example: user 2 wants to join trip 3
-- ---------------------------------------------------------

BEGIN;

-- Lock route row for the trip to avoid race conditions
SELECT r.id, r.seats, r.route_type
FROM trips t
JOIN routes r ON r.id = t.route_id
WHERE t.id = 3
FOR UPDATE;

-- Check current number of GOING participants
SELECT
    COUNT(*) AS going_count
FROM trip_participants tp
WHERE tp.trip_id = 3
  AND tp.status = 'GOING';

-- If going_count < seats (handled by application logic),
-- then insert the new participant:
INSERT INTO trip_participants (trip_id, user_id, status, comment)
VALUES (3, 2, 'GOING', 'Joined via transaction example');

COMMIT;
-- If no seats are available:
-- ROLLBACK;


-- 2. Cancel a route and all its future trips in one transaction
--    Example: route_id = 1
-- ---------------------------------------------------------

BEGIN;

UPDATE routes
SET is_active = FALSE
WHERE id = 1;

UPDATE trips
SET status = 'CANCELED'
WHERE route_id = 1
  AND trip_date >= CURRENT_DATE;

COMMIT;
-- Or ROLLBACK; to undo.


-- 3. Bulk insert participants with SAVEPOINTs (trip_id = 6)
-- ---------------------------------------------------------

BEGIN;

SAVEPOINT before_bulk_insert;

-- First insert
INSERT INTO trip_participants (trip_id, user_id, status)
VALUES (6, 2, 'GOING');

-- Second insert with own savepoint (if duplicate, rollback only this part)
SAVEPOINT sp_user3;
INSERT INTO trip_participants (trip_id, user_id, status)
VALUES (6, 3, 'GOING');
-- If this fails:
-- ROLLBACK TO sp_user3;

-- Third insert
SAVEPOINT sp_user4;
INSERT INTO trip_participants (trip_id, user_id, status)
VALUES (6, 4, 'GOING');
-- If this fails:
-- ROLLBACK TO sp_user4;

COMMIT;
-- Or ROLLBACK TO before_bulk_insert; then ROLLBACK;


-- 4. Apply promo code and create payment atomically
-- ---------------------------------------------------------

-- Example: user 2 pays for trip 4 with promo 'WELCOME10'

BEGIN;

-- 4.1 Lock promo code row
SELECT *
FROM promo_codes
WHERE code = 'WELCOME10'
FOR UPDATE;

-- 4.2 Check if user already used this promo (logic usually in app code)
SELECT COUNT(*) AS times_used
FROM user_promo_codes upc
JOIN promo_codes pc ON pc.id = upc.promo_code_id
WHERE upc.user_id = 2
  AND pc.code = 'WELCOME10';

-- 4.3 Suppose promo is allowed. Insert into user_promo_codes
INSERT INTO user_promo_codes (user_id, promo_code_id, trip_id)
SELECT 2, pc.id, 4
FROM promo_codes pc
WHERE pc.code = 'WELCOME10';

-- 4.4 Create payment with discounted amount (e.g., 10% off 80 = 72)
INSERT INTO payments (trip_id, payer_id, method_id, amount, status)
VALUES (4, 2, 1, 72.00, 'PAID');

COMMIT;
-- If something fails:
-- ROLLBACK;
