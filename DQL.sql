--BASIC OPERATIONS

--Registering a New Guest
INSERT INTO "user" (first_name, middle_name, last_name, email, phone_number)
VALUES ('Ann', 'Maggie', 'Doe', 'ann.doe@gmail.com', '091123456');

--Leaving Feedback After a Completed Stay
INSERT INTO feedback (reservation_id, feedback_response, rating, created_at)
VALUES (51, 'Everything was excellent!', 5, '2024-08-15 14:30:00');

--Placing a Food Order During a Stay
INSERT INTO food_order (reservation_id, amount, created_at) VALUES (51, 59.99, '2024-08-15 13:15:00');

--Making a room reservation
INSERT INTO reservation (user_id, check_in_date, check_out_date, total_cost, guest_count) VALUES (11, '2025-08-15 13:15:00', '2025-08-17 13:15:00', 450, 2);

INSERT INTO overnight_room_reservation (SELECT count(*) FROM reservation, 45);

-- Room popularity by branch(Most and Least Booked Overnight Rooms)
WITH room_bookings AS (
    SELECT 
        h.name AS hotel_name,
        o.room_number,
        COUNT(overnight_room_reservation.reservation_id) AS times_booked
    FROM 
        overnight_room o
    LEFT JOIN overnight_room_reservation 
        ON o.room_id = overnight_room_reservation.room_id
    JOIN hotel h 
        ON o.hotel_id = h.hotel_id
    GROUP BY 
        h.name, o.room_number, o.room_id
)
SELECT * 
FROM room_bookings
WHERE times_booked = (SELECT MAX(times_booked) FROM room_bookings)
   OR times_booked = (SELECT MIN(times_booked) FROM room_bookings)
ORDER BY times_booked DESC;

--Most and Least Booked Meeting Rooms
WITH meeting_bookings AS (
    SELECT 
        h.name AS hotel_name,
        m.room_number,
        COUNT(meeting_room_reservation.reservation_id) AS times_booked
    FROM 
        meeting_room m
    LEFT JOIN meeting_room_reservation 
        ON m.room_id = meeting_room_reservation.room_id
    JOIN hotel h 
        ON m.hotel_id = h.hotel_id
    GROUP BY 
        h.name, m.room_number, m.room_id
)
SELECT * 
FROM meeting_bookings
WHERE times_booked = (SELECT MAX(times_booked) FROM meeting_bookings)
   OR times_booked = (SELECT MIN(times_booked) FROM meeting_bookings)
ORDER BY times_booked DESC;

-- Generate a bill for a guest’s food consumption.

SELECT 
    fo.reservation_id,
    SUM(fo.amount) AS total_food_bill
FROM 
    food_order fo
GROUP BY 
    fo.reservation_id
ORDER BY 
    total_food_bill DESC;


--Visitor-Focused Queries

-- View stay history, payments, and feedback

SELECT 
    r.reservation_id,
    r.check_in_date,
    r.check_out_date,
    r.total_cost,
    p.amount AS payment_amount,
    f.feedback_response,
    f.rating
FROM 
    reservation r
LEFT JOIN payment p ON r.reservation_id = p.reservation_id
LEFT JOIN feedback f ON r.reservation_id = f.reservation_id
WHERE 
    r.user_id = 1;


-- Check available rooms in a city and date range

SELECT 
    o.room_id,
    o.room_number,
    o.price_per_night,
    h.name AS hotel_name,
    (h.hotel_address).city AS city
FROM 
    overnight_room o
JOIN hotel h ON o.hotel_id = h.hotel_id
WHERE 
    (h.hotel_address).city = 'Dilijan'
    AND o.room_id NOT IN (
        SELECT orr.room_id
        FROM overnight_room_reservation orr
        JOIN reservation r ON orr.reservation_id = r.reservation_id
        WHERE 
            r.check_in_date <= '2024-08-10'
            AND 
            r.check_out_date >= '2024-08-01'
    );


-- What food orders did the user make during their last stay?

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    fo.order_id,
    fo.order_details,
    fo.amount
FROM "user" u
JOIN reservation r on u.user_id = r.user_id
JOIN food_order fo on r.reservation_id = fo.reservation_id
WHERE r.check_in_date = (
    SELECT MAX(r2.check_in_date)
    FROM reservation r2
    WHERE r2.user_id = u.user_id
)
ORDER BY u.user_id, fo.order_id;

-- What rooms are currently occupied or reserved today?

SELECT DISTINCT orr.room_id, ovr.room_number, 'overnight' AS room_category
FROM overnight_room_reservation orr
JOIN reservation r ON orr.reservation_id = r.reservation_id
JOIN overnight_room ovr ON orr.room_id = ovr.room_id
WHERE current_date BETWEEN r.check_in_date::date AND r.check_out_date::date

UNION

SELECT DISTINCT mrr.room_id, mr.room_number, 'meeting' AS room_category
FROM meeting_room_reservation mrr
JOIN reservation r ON mrr.reservation_id = r.reservation_id
JOIN meeting_room mr ON mrr.room_id = mr.room_id
WHERE current_date BETWEEN r.check_in_date::date AND r.check_out_date::date;

-- Get all active room service food orders.

SELECT fo.*
FROM food_order fo
JOIN reservation r ON fo.reservation_id = r.reservation_id
WHERE current_date BETWEEN r.check_in_date::date AND r.check_out_date::date;

-- Show top 5 most ordered food items this month.
SELECT order_details, COUNT(*) AS times_ordered
FROM food_order
WHERE date_trunc('month', created_at) = date_trunc('month', now())
GROUP BY order_details
ORDER BY times_ordered DESC
limit 5;

-- List all rooms in a branch and their availability.

SELECT 
    ovr.room_number, 
    ovr.hotel_id,
    h.name AS hotel_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM overnight_room_reservation orr
            JOIN reservation r ON orr.reservation_id = r.reservation_id
            WHERE orr.room_id = ovr.room_id
              AND CURRENT_DATE BETWEEN r.check_in_date::date AND r.check_out_date::date
              AND r.status = 'reserved'
        ) THEN 'RESERVED'
        ELSE 'AVAILABLE'
    END AS status
FROM 
    overnight_room ovr
JOIN 
    hotel h ON ovr.hotel_id = h.hotel_id
WHERE 
    h.hotel_id IN (1, 2, 3, 4, 5)
ORDER BY 
    h.hotel_id;

-- Get a reservation’s full details, including user and payment info

SELECT r.*, u.first_name, u.last_name, u.email, p.amount as payment_amount, p.payment_method
FROM reservation r
JOIN "user" u ON r.user_id = u.user_id
LEFT JOIN payment p ON r.reservation_id = p.reservation_id
LIMIT 5;

-- View all reservations for a specific date range.
SELECT *
FROM reservation
WHERE check_in_date::date BETWEEN '2024-01-01'::date AND '2024-01-31'::date
OR check_out_date::date BETWEEN '2024-06-01'::date AND '2024-07-31'::date;


-- Show all reservations made for a branch within a given time period
SELECT r.*
FROM reservation r
JOIN overnight_room_reservation orr ON r.reservation_id = orr.reservation_id
JOIN overnight_room ovr ON orr.room_id = ovr.room_id
WHERE ovr.hotel_id IN (1, 2, 3, 4, 5)
  AND (r. check_in_date::date BETWEEN '2024-01-01'::date AND '2024-01-31'::date
OR r.check_out_date::date BETWEEN '2024-06-01'::date AND '2024-07-31'::date);

-- Show all employees and their assigned branches

SELECT e.user_id, u.first_name, u.last_name, e.role, h.name AS hotel_name
FROM employee_details e
JOIN "user" u ON e.user_id = u.user_id
JOIN hotel h ON e.hotel_id = h.hotel_id;

-- Monthly revenue report (rooms and food)

SELECT
    date_trunc('month', p.created_at) AS month,
    'room' AS service_type,
    SUM(p.amount) AS total_amount
FROM payment p
GROUP BY month

UNION ALL

SELECT
    date_trunc('month', fo.created_at) AS month,
    'food' AS service_type,
    SUM(fo.amount) AS total_amount
FROM food_order fo
GROUP BY month
ORDER BY month;

-- Revenue by room type per month (last year)

SELECT
    date_trunc('month', r.created_at) AS month,
    ovr.room_type,
    SUM(r.total_cost) AS total_revenue
FROM reservation r
JOIN overnight_room_reservation orr ON r.reservation_id = orr.reservation_id
JOIN overnight_room ovr ON orr.room_id = ovr.room_id
WHERE r.created_at >= date_trunc('year', now()) - interval '1 year'
GROUP BY month, ovr.room_type
order by month, ovr.room_type;

--Users with high cancellation rates
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(r.reservation_id) AS total_bookings,
    SUM(CASE WHEN r.status = 'canceled' THEN 1 ELSE 0 END) AS canceled_bookings
FROM 
    "user" u
JOIN reservation r ON u.user_id = r.user_id
GROUP BY 
    u.user_id, u.first_name, u.last_name
HAVING 
    (SUM(CASE WHEN r.status = 'canceled' THEN 1 ELSE 0 END) * 1.0) / COUNT(r.reservation_id) > 0.5
ORDER BY 
    canceled_bookings DESC;

-- Top 10 guests by total spending

SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    SUM(p.amount) + SUM(f.amount) AS total_expenditure
FROM 
    "user" u
JOIN reservation r ON u.user_id = r.user_id
LEFT JOIN payment p ON r.reservation_id = p.reservation_id
LEFT JOIN food_order f ON r.reservation_id = f.reservation_id
WHERE 
    (p.created_at >= NOW() - INTERVAL '12 months' OR p.created_at IS NULL)
    OR 
    (f.created_at >= NOW() - INTERVAL '12 months' OR f.created_at IS NULL)
GROUP BY 
    u.user_id, u.first_name, u.last_name
HAVING 
    SUM(p.amount) + SUM(f.amount) IS NOT NULL
ORDER BY 
    total_expenditure DESC
LIMIT 10;


--Most active users by bookings and spending
SELECT 
    u.user_id,
    u.first_name,
    u.last_name,
    COUNT(DISTINCT r.reservation_id) AS total_bookings,
    SUM(p.amount) + SUM(f.amount) AS total_spent
FROM 
    "user" u
JOIN reservation r ON u.user_id = r.user_id
LEFT JOIN payment p ON r.reservation_id = p.reservation_id
LEFT JOIN food_order f ON r.reservation_id = f.reservation_id
WHERE 
    (p.created_at >= NOW() - INTERVAL '12 months' OR p.created_at IS NULL)
    OR 
    (f.created_at >= NOW() - INTERVAL '12 months' OR f.created_at IS NULL)
GROUP BY 
    u.user_id, u.first_name, u.last_name
ORDER BY 
    total_bookings DESC,
    total_spent DESC
LIMIT 10;

-- Average room price per type and branch
SELECT 
    h.name AS branch_name,
    'overnight' AS room_type,
    ROUND(AVG(o.price_per_night), 2) AS average_price
FROM 
    overnight_room o
JOIN hotel h ON o.hotel_id = h.hotel_id
GROUP BY 
    h.name

UNION ALL

SELECT 
    h.name AS branch_name,
    'meeting' AS room_type,
    ROUND(AVG(m.hourly_rate), 2) AS average_price
FROM 
    meeting_room m
JOIN hotel h ON m.hotel_id = h.hotel_id
GROUP BY 
    h.name
ORDER BY 
    branch_name, room_type;

-- Room Satisfaction Trends
select all_time.room_id, all_time.avg_rating as all_time_rating, this_month.avg_rating as this_month_rating,
	case
        when this_month.avg_rating - all_time.avg_rating > 0 then 'improved'
        when this_month.avg_rating - all_time.avg_rating < 0 then 'worsened'
        else 'no change'
    end as change
from
(
	select ovroom.*, avg(rating) as avg_rating
	from overnight_room ovroom
		inner join overnight_room_reservation orr on ovroom.room_id = orr.room_id
		left join reservation res on orr.reservation_id = res.reservation_id
		inner join feedback fb on res.reservation_id = fb.reservation_id
	where res.status = 'completed'
	group by ovroom.room_id
) as all_time
inner join (
	select ovroom.*, avg(rating) as avg_rating
	from overnight_room ovroom
		inner join overnight_room_reservation orr on ovroom.room_id = orr.room_id
		left join reservation res on orr.reservation_id = res.reservation_id
		inner join feedback fb on res.reservation_id = fb.reservation_id
	where res.status = 'completed' and check_out_date >= NOW() - INTERVAL '1 month'
	group by ovroom.room_id
) as this_month
on all_time.room_id = this_month.room_id;


-- Categorization of rooms by price ranges
select room_id, price_per_night, room_type,
	case
		when price_per_night < 160 then 'affordable'
		when price_per_night between 160 and 300 then 'standard'
		else 'premium'
	end as price_range 
from overnight_room
order by price_per_night;


-- Most profitable hotels (both room payments and food payments)
with reservation_to_room as (
		select distinct res.reservation_id, room_id
		from reservation res inner join overnight_room_reservation orr on res.reservation_id = orr.reservation_id
		where status = 'completed'
	),
	food_spending as (
		select res.reservation_id, sum(food_order.amount) as amount
		from reservation_to_room res
			inner join overnight_room ovroom on res.room_id = ovroom.room_id
			right join food_order on res.reservation_id = food_order.reservation_id
		group by res.reservation_id
	)


select hotel.hotel_id, hotel.name, sum(payment_per_reservation.total_payment) as revenue
from hotel inner join 
(
	select ovroom.hotel_id, coalesce(sum(food_spending.amount), 0) + sum(payment.amount) as total_payment 
	from reservation_to_room res
		inner join overnight_room ovroom on res.room_id = ovroom.room_id
		left join food_spending on res.reservation_id = food_spending.reservation_id
		left join payment on res.reservation_id = payment.reservation_id
	group by res.reservation_id, ovroom.hotel_id
) as payment_per_reservation on hotel.hotel_id = payment_per_reservation.hotel_id
group by hotel.hotel_id
order by revenue desc;
