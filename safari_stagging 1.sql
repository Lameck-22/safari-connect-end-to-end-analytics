CREATE SCHEMA IF NOT EXISTS safari_connect;
SET search_path TO safari_connect;

-- Staging table: ALL columns TEXT - accepts dirty data without failing
CREATE TABLE IF NOT EXISTS bookings_staging (
    booking_id       TEXT,
    passenger_name    TEXT, 
    passenger_phone  TEXT,
    passenger_gender TEXT, 
    passenger_city    TEXT, 
    route_code       TEXT,
    route_from       TEXT, 
    route_to          TEXT, 
    vehicle_plate    TEXT,
    vehicle_type     TEXT, 
    driver_name       TEXT, 
    driver_rating    TEXT,
    departure_date   TEXT, 
    departure_time    TEXT, 
    seat_class       TEXT,
    seats_booked     TEXT, 
    fare_per_seat     TEXT, 
    total_fare       TEXT,
    payment_method   TEXT, 
    booking_status    TEXT, 
    trip_rating      TEXT
);
CREATE SCHEMA IF NOT EXISTS safari_connect;
SET search_path TO safari_connect;


select count(*) from safari_connect.bookings_staging;

 select distinct passenger_name from safari_connect.bookings_staging;
set search_path to safari_connect;

-- Checking name casing problems 

select distinct passenger_name from safari_connect.bookings_staging;

-- Gender variants- should be only male and female
select distinct passenger_gender from safari_connect.bookings_staging;

-- Seat_class variants
select distinct seat_class from bookings_staging;

-- Payment_method variants 
select distinct payment_method from bookings_staging;

-- booking status variants
select distinct booking_status from bookings_staging;

-- date format problems
select booking_id, departure_date from bookings_staging 
where departure_date not similar to '[0-9]{4}-[0-9]{2}-[0-9]{2}';

YYYY-MM-DD

-- phone format problems
select booking_id, passenger_phone from bookings_staging 
where passenger_phone like '+254%' or passenger_phone like '%-%';

-- fares stored as text
select booking_id, total_fare, fare_per_seat from bookings_staging 
where total_fare like 'KES%' or fare_per_seat like 'KES%';

-- inavlid trip ratings
select booking_id, trip_rating from bookings_staging 
where trip_rating not in ('1', '2', '3', '4', '5', '');

-- duplicate booking ids
select booking_id, count(*) from bookings_staging 
group by booking_id having count(*) > 1;

-- Negative seats_booked
select booking_id, seats_booked from bookings_staging 
where NULLIF(REGEXP_REPLACE(seats_booked, '[^0-9-]', '', 'g'), '')::INTEGER < 1;

-- Starting Data cleaning
--             ======= 1. passenger name casing and whitespace =================

select initcap(trim(passenger_name)) from bookings_staging;

update bookings_staging 
set passenger_name = initcap(trim(passenger_name))
where passenger_name != initcap(trim(passenger_name));

-- confirm passenger name has been cleaned
select distinct passenger_name from safari_connect.bookings_staging;

-- ============== 2. Passenger phone (+254, dashes, empty,7) ==========
-- =====================================================================

select regexp_replace(passenger_phone,'[^0-9]', '','g') 
from bookings_staging;

-- removing dashes
update bookings_staging
set passenger_phone = regexp_replace(passenger_phone,'[^0-9]', '','g') 
where passenger_phone like '%-%';

--output for the cleaned passenger phone that dashes have been removed
select distinct passenger_phone from bookings_staging;

--removing prefix +254
select passenger_phone from bookings_staging
where passenger_phone like '+254%';

SELECT REGEXP_REPLACE(passenger_phone, '^\+254', '0') AS formatted_number
FROM safari_connect.bookings_staging; 



update 	bookings_staging 
set passenger_phone = REGEXP_REPLACE(passenger_phone, '^254', '0') 
where passenger_phone like '254%';

update bookings_staging
set passenger_phone = regexp_replace(passenger_phone,'^7','07');

select passenger_phone from bookings_staging;

-- confirm if theres spaces remaining 
select trim(passenger_phone) 
from safari_connect.bookings_staging
where passenger_phone like' %';

update bookings_staging
set passenger_phone = trim(passenger_phone)
where passenger_phone like '%';


--set empty to null
update bookings_staging 
set passenger_phone = null 
where trim(passenger_phone) = '';

select passenger_phone from bookings_staging;

--Clean passenger gender
select distinct passenger_gender from bookings_staging;

update bookings_staging 
set passenger_gender =  case 
	when upper(trim(passenger_gender)) in ('MALE', 'M') then 
	'Male'
	when upper(trim(passenger_gender)) in ('FEMALE', 'F') then 
	'Female' else 
	passenger_gender 
end;

-- Clean Passenger city
select distinct passenger_city from bookings_staging;

update bookings_staging
set passenger_city = trim(initcap(passenger_city));

-- removing empty spaces
update bookings_staging 
set passenger_city = 'Unknown' 
where passenger_city = '' or passenger_city is null;

--Clean departure date
select departure_date from bookings_staging;
 -- fix dd/mm/yy
select departure_date, to_date(departure_date,'YYYY/MM/DD')::TEXT
from bookings_staging 
where departure_date like '%-%';

SELECT booking_id, departure_date
FROM bookings_staging
WHERE departure_date !~ '^\d{4}-\d{2}-\d{2}$';

yyyy-mm-dd

UPDATE bookings_staging
SET departure_date =
    TO_DATE(departure_date, 'DD/MM/YYYY')::TEXT
WHERE departure_date ~ '^\d{2}/\d{2}/\d{4}$';

dd-mm-yyyy

select departure_date from bookings_staging;

UPDATE bookings_staging
SET departure_date =
    TO_DATE(departure_date, 'DD-MM-YY')::TEXT
WHERE departure_date ~ '^\d{2}-\d{2}-\d{2}$';

dd-mm-yy


SELECT
    booking_id,
    departure_date AS original_date,
    CASE
        -- Already YYYY-MM-DD
        WHEN departure_date ~ '^\d{4}-\d{2}-\d{2}$'
            THEN departure_date::DATE
        -- DD/MM/YYYY
        WHEN departure_date ~ '^\d{2}/\d{2}/\d{4}$'
            THEN TO_DATE(departure_date, 'DD/MM/YYYY')
        -- DD-MM-YY
        WHEN departure_date ~ '^\d{2}-\d{2}-\d{2}$'
            THEN TO_DATE(departure_date, 'DD-MM-YY')
        -- MM-DD-YYYY
        WHEN departure_date ~ '^\d{2}-\d{2}-\d{4}$'
            THEN TO_DATE(departure_date, 'MM-DD-YYYY')
        ELSE NULL
    END AS cleaned_date
FROM bookings_staging;

update bookings_staging bs 
set departure_date = CASE
        -- Already YYYY-MM-DD
        WHEN departure_date ~ '^\d{4}-\d{2}-\d{2}$'
            THEN departure_date::DATE
        -- DD/MM/YYYY
        WHEN departure_date ~ '^\d{2}/\d{2}/\d{4}$'
            THEN TO_DATE(departure_date, 'DD/MM/YYYY')
        -- DD-MM-YY
        WHEN departure_date ~ '^\d{2}-\d{2}-\d{2}$'
            THEN TO_DATE(departure_date, 'DD-MM-YY')
        -- MM-DD-YYYY
        WHEN departure_date ~ '^\d{2}-\d{2}-\d{4}$'
            THEN TO_DATE(departure_date, 'MM-DD-YYYY')
        ELSE NULL
    end;

select departure_date from bookings_staging;

-- clean seat class
select distinct seat_class from bookings_staging;

update bookings_staging 
set seat_class = case
	when upper(trim(seat_class)) in ('ECONOMY', 'ECO', 'ECONOMY CLASS') then
'Economy'
	when upper(trim(seat_class)) in ('BUSINESS', 'BUS', 'BUSINESS CLASS') then 
	'Business'
	else seat_class
end;

-- payment method and booking status
select distinct payment_method from bookings_staging;

update bookings_staging 
set payment_method = case
	when upper(trim(payment_method)) in ('MPESA', 'M-PESA', 'M PESA') then
'M-Pesa'
	when upper(trim(payment_method)) = 'CASH' then 
	'Cash'
	when upper(trim(payment_method)) = 'CARD' then 
	'Card'
	else payment_method
end;

update bookings_staging
set booking_status = trim(initcap(booking_status));

select distinct booking_status from bookings_staging;

-- cleaning fare per seat and total fare
select total_fare from bookings_staging;

select total_fare, REGEXP_REPLACE(total_fare,'[^0-9.]','','g')
from bookings_staging;

update bookings_staging 
set total_fare =  REGEXP_REPLACE(total_fare,'[^0-9.]','','g');

-- cleaning fare per seat

select distinct fare_per_seat from bookings_staging;

update bookings_staging 
set fare_per_seat =  REGEXP_REPLACE(fare_per_seat,'[^0-9.]','','g')
where fare_per_seat similar to '%[^0-9.]%';

-- Driver name casing
select distinct driver_name from bookings_staging;

update bookings_staging
set driver_name = trim(initcap(driver_name));

-- clean vehicle type 
select vehicle_type from bookings_staging;

update bookings_staging
set vehicle_type = trim(initcap(vehicle_type));

-- trip rating invalid values 
select trip_rating from bookings_staging;

update bookings_staging bs 
set trip_rating = null 
where trim(trip_rating) not in ('1', '2', '3', '4', '5', '');

-- Clean remove negative seats 
DELETE FROM bookings_staging
WHERE NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9-]','','g'),'')::INTEGER < 1;

DELETE FROM bookings_staging
WHERE ctid NOT IN 
    (SELECT MIN(ctid) FROM bookings_staging GROUP BY booking_id);

select distinct seats_booked from bookings_staging;


select * from bookings_staging;


-- Step 5 - Create Production Table & Load Clean Data

CREATE TABLE IF NOT EXISTS bookings (
    booking_id        VARCHAR(10) PRIMARY KEY,
    passenger_name    VARCHAR(100),  passenger_phone  VARCHAR(15),
    passenger_gender  VARCHAR(10),   passenger_city   VARCHAR(60),
    route_code        VARCHAR(10),   route_from       VARCHAR(60),
    route_to          VARCHAR(60),   vehicle_plate    VARCHAR(15),
    vehicle_type      VARCHAR(20),   driver_name      VARCHAR(100),
    driver_rating     NUMERIC(3,1),  departure_date   DATE,
    departure_time    VARCHAR(10),   seat_class       VARCHAR(20),
    seats_booked      INTEGER,       fare_per_seat    NUMERIC(10,2),
    total_fare        NUMERIC(12,2), payment_method   VARCHAR(20),
    booking_status    VARCHAR(20),   trip_rating      INTEGER
);

INSERT INTO bookings
SELECT
    booking_id, TRIM(passenger_name),
    NULLIF(TRIM(passenger_phone),''),
    passenger_gender, COALESCE(NULLIF(TRIM(passenger_city),''),'Unknown'),
    route_code, route_from, route_to, vehicle_plate, INITCAP(TRIM(vehicle_type)),
    TRIM(driver_name),
    NULLIF(REGEXP_REPLACE(driver_rating,'[^0-9.]','','g'),'')::NUMERIC,
    departure_date::DATE,  departure_time, seat_class,
    NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9]','','g'),'')::INTEGER,
    NULLIF(REGEXP_REPLACE(fare_per_seat,'[^0-9.]','','g'),'')::NUMERIC,
    NULLIF(REGEXP_REPLACE(total_fare,'[^0-9.]','','g'),'')::NUMERIC,
    payment_method, booking_status,
    NULLIF(trip_rating,'')::INTEGER
FROM bookings_staging
WHERE departure_date SIMILAR TO '[0-9]{4}-[0-9]{2}-[0-9]{2}'
  AND NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9]','','g'),'')::INTEGER > 0;

-- Verify
SELECT COUNT(*) FROM bookings;  -- expect ~280+
SELECT DISTINCT booking_status FROM bookings; -- exactly: Completed, Cancelled, No Show
SELECT DISTINCT seat_class FROM bookings;     -- exactly: Economy, Business




-- Step 6 - Create v_clean_trips View

CREATE OR REPLACE VIEW v_clean_trips AS
SELECT *,
    TO_CHAR(departure_date, 'YYYY-MM')    AS travel_month,
    TO_CHAR(departure_date, 'Month YYYY') AS month_label,
    TO_CHAR(departure_date, 'Day')        AS day_name,
    EXTRACT(MONTH FROM departure_date)    AS month_num,
    EXTRACT(DOW FROM departure_date)      AS day_of_week,
    (fare_per_seat * seats_booked)           AS calculated_fare,
    CASE
        WHEN trip_rating BETWEEN 4 AND 5 THEN 'Satisfied'
        WHEN trip_rating = 3 THEN 'Neutral'
        WHEN trip_rating BETWEEN 1 AND 2 THEN 'Unsatisfied'
        ELSE 'No Rating'
    END AS satisfaction
FROM bookings
WHERE booking_status = 'Completed';

-- Test
SELECT * FROM v_clean_trips LIMIT 10;

-- Question 1 - Route Analysis

-- Business need: The Director wants to know which routes are the backbone of the business 
-- and which underperform.

-- 1A - Revenue and bookings by route
-- Show: route_code, route_from, route_to, total_bookings, total_seats, 
-- total_revenue, avg_fare, avg_trip_rating. Order by total_revenue descending.

select
    route_code,
    route_from,
    route_to,
    count(*) as total_bookings,
    sum(seats_booked) as total_seats,
    sum(total_fare) as total_revenue,
    round(avg(fare_per_seat), 2)as avg_fare,
    round(avg(trip_rating), 2)as avg_rating
from v_clean_trips
group by route_code, route_from, route_to
order by total_revenue desc;

-- 1B - Revenue per seat by route (efficiency metric)
-- Which route earns the most per seat sold? 
-- Show route, total_revenue, total_seats, and revenue_per_seat = total_revenue / total_seats

select 
	route_code,
	route_from,
	route_to,
	sum(total_fare) as total_revenue,
	sum(seats_booked) as total_seat,
	round(sum(total_fare)/sum(seats_booked),2) as revenue_per_seat
from v_clean_trips
group by route_from, route_to
order by total_revenue desc;




--1C - Route ranking with window function
-- Rank all routes by total revenue using RANK(). 
--Also show each route's percentage of total company revenue.

with route_rev as (
    select 
    		route_code, 
    		route_from,
    		route_to,
    		sum(total_fare) as revenue
    from v_clean_trips 
    group by route_code, route_from, route_to
)
select
    route, 
    revenue,
    rank() over (order by revenue desc) as revenue_rank,
    round(revenue * 100.0 / sum(revenue) over (), 1) as pct_of_total
from route_rev 
order by revenue_rank;

-- 1D - Vehicle type performance
-- Compare Bus vs Matatu vs Minibus - total bookings, revenue,
-- avg rating. Which vehicle type is most profitable?
select 
	vehicle_type, 
	count(*) as total_bookings, 
	sum(total_fare) as revenue, 
	round(avg(trip_rating),2) as avg_rating
from v_clean_trips
group by vehicle_type 
order by revenue desc;


--Question 2 - Driver Performance

--Business need: HR wants to know who to promote, who needs training, 
-- and whether driver rating affects passenger satisfaction.

--2A - Driver summary
--Show: driver_name, total_trips, total_seats_carried, 
--total_revenue, avg_trip_rating, driver_rating. Order by total_revenue descending

select 
	driver_name, 
	count(*) as total_trips, 
	sum(seats_booked) as total_seats_carried,
	sum(total_fare) as total_revenue, 
	round(avg(trip_rating),2) as avg_rating, 
	round(avg(driver_rating),2) as driver_rating
from v_clean_trips
group by driver_name 
order by total_revenue desc;


-- 2B - Driver ranking - overall + by vehicle type
--Using a CTE for driver totals, rank drivers overall 
--by revenue AND within their vehicle type using PARTITION BY vehicle_type
with driver_totals as (
    select
        driver_name,
        vehicle_type,
        count(*) as total_trips,
        sum(total_fare) as total_revenue,
        round(avg(trip_rating),2) as avg_passenger_rating
    from v_clean_trips
    group by driver_name, vehicle_type
)
select
    driver_name, 
    vehicle_type, 
    total_trips, 
    total_revenue, 
    avg_passenger_rating,
    rank() over (order by total_revenue desc) as overall_rank,
    rank() over (partition by vehicle_type order by total_revenue desc) as vehicle_rank
from driver_totals
order by overall_rank;

--2C - Does driver rating predict passenger satisfaction? 
--Group drivers into high-rated (≥ 4.5) and standard (< 4.5). 
--Compare average passenger trip_rating for each group. Does a higher driver rating lead to happier passengers?

select 
	driver_name, 
	driver_rating, 
	round(avg(trip_rating),2) as avg_trip_rating, 
	case 
		when driver_rating >= 4.5 then 'High rated'
		when  driver_rating < 4.5 then 'Standard'
	end as driver_grouping
from v_clean_trips
group by driver_name, driver_rating  
order by driver_rating desc;


--2C - Does driver rating predict passenger satisfaction? 
-- from our data yes

--Question 3 - Revenue Trends

--Business need: The Director wants to see if Safari Connect is growing and which months to focus on for expansion.

--3A - Monthly revenue with month-over-month change (CTE + LAG)

with monthly as(
	select 
		to_char(departure_date, 'YYYY-MM') as month,
		count(*) as bookings,
        sum(total_fare) as revenue
    from v_clean_trips
    group by to_char(departure_date, 'YYYY-MM')
)
select
    month, 
    bookings, 
    revenue,
    lag(revenue) over (order by month)as prev_month,
    revenue - lag(revenue) OVER (order by month) as change,
    round((revenue - lag(revenue) over (order by month))
        / nullif(lag(revenue) over (order by month),0) * 100, 1)as change_pct
from monthly 
order by month;

-- 3B - Running total of revenue
-- Show each month with its revenue and a cumulative running total from January onwards.

select 
	travel_month, 
	sum(total_fare) as revenue, 
	sum(sum(total_fare)) over(order by travel_month) as running_total
from v_clean_trips
group by travel_month 
order by travel_month asc;

-- 3C - Best and worst 3 months
-- Using a CTE for monthly revenue, show the top 
-- 3 months and the bottom 3 months by revenue. Use RANK().
 select 
 	travel_month, 
 	sum(total_fare) as revenue
 from v_clean_trips
 group by travel_month
 order by revenue desc;

with best_worst_month as(
	select 
		travel_month, 
		sum(total_fare) as revenue
	 from v_clean_trips
	 group by travel_month
	 order by revenue desc
),
 revenue_ranking as(
	 select 
	 	*, 
	 	rank() over(order by revenue) as rev_rank
	 from best_worst_month
)
select 
	* 
from revenue_ranking
where rev_rank <= 3 or rev_rank >= 11;
	
--3D - Revenue by route per month (pivot)
--Show one row per month with separate columns for the top 3 routes 
-- (RT001, RT002, RT003) using CASE WHEN + SUM.

select
    travel_month,
    sum(case 
    	when route_code ='RT001' then total_fare
    end
    ) as RT001_fare,
	sum(case
	when route_code = 'RT002' then total_fare
	end
	)as RT002_fare,
	sum(case 
	when route_code = 'RT003' then total_fare
	end
	)as RT003_fare
from v_clean_trips
group by travel_month;

-- Question 4 - Passenger Insights

-- Business need: Marketing wants to know who Safari Connect's typical traveller is.
-- 4A - Top passenger cities
-- Show: passenger_city, total_bookings, total_seats, 
-- total_revenue, avg_fare. Order by total_bookings descending. 
-- Only include cities with 3+ bookings.

select 
	passenger_city, 
	count(*) as total_bookings,
	sum(seats_booked) as total_seats,
	sum(total_fare) as total_revenue, 
	round(avg(fare_per_seat),2) as average_fare
from v_clean_trips
group by passenger_city 
having count(*) >= 3
order by total_bookings desc;

-- 4B - Gender split and seat class preference
-- Show bookings and revenue broken down by passenger_gender 
-- and seat_class. Use a CASE WHEN pivot to show Economy and Business as separate columns.

select 
	passenger_gender, 
	sum(seats_booked) as bookings, 
	sum(case 
	when seat_class = 'Economy' then 1
	else 0
	end
	) as economy_booking,
	sum(case 
		when seat_class = 'Business' then 1
		else 0
	end
	) as business_booking,
	sum(case 
		when seat_class = 'Business' then total_fare
		else 0
	end
	) as business_revenue,
	sum(case 
		when seat_class = 'Economy' then total_fare
		else 0
	end
	)as economy_revenue
from v_clean_trips
group by passenger_gender
order by passenger_gender;

-- 4C - Satisfaction breakdown (CTE)
-- Using a CTE, count how many trips fall into each 
-- satisfaction category (Satisfied / Neutral / Unsatisfied / No Rating). Show count and percentage of total completed trips.

with sat_counts as (
select 
	satisfaction, 
    	count(*) as cnt
from v_clean_trips
group by satisfaction
)
select 
    satisfaction,
    cnt,
    round(cnt * 100.0 / SUM(cnt) over (), 1) as pct
from sat_counts 
order by cnt desc;

--  4D - Passenger quartiles by spend (NTILE)
-- Using a CTE for total spend per passenger, 
-- divide passengers into 4 quartiles using NTILE(4). 
-- Show: passenger_name, total_spent, quartile. Label quartile 4 as 'Top Spender'.


with pass_spend as (
	select 
		passenger_name, 
		sum(total_fare) as total_spent
	from v_clean_trips
	group by passenger_name
),
passenger_quartile as (
	select 
		*, 
		ntile(4) over(order by total_spent) as quartile
	from pass_spend
)
select 
	*, 
	case 
	when quartile = '4' then 'Top Spender'
	else 'quartile'
	end as quartile
from passenger_quartile
order by total_spent desc;

-- Question 5 - Cancellations & Lost Revenue

-- 5A - Overall status breakdown

select 
	booking_status,
	count(*) as seats_booked
from bookings
group by booking_status ;


-- 5B - Cancellation rate by route
-- Show: route_code, route, total_bookings, completed, cancelled, no_show, cancellation_rate_pct.

select
    route_code,
    route_from,
    route_to,
    count(*) as total_bookings,
    sum(case when booking_status = 'Completed' then 1 else 0 end) as completed,
    sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled,
    sum(case when booking_status = 'No Show' then 1 else 0 end) as no_show,
    round(sum(case when booking_status in ('Cancelled')
             then 1 else 0 end) * 100.0 / count(*), 1) as cancel_rate_pct
from bookings
group by route_code, route_from, route_to
order by cancel_rate_pct desc;

-- 5C - Revenue lost from cancellations and no-shows
select 
	route_code,
	route_from,
	route_to,
	sum(total_fare) as total_revenue
from bookings
where booking_status in ('Cancelled','No Show')
group by route_code,route_from,route_to
order by sum(total_fare) desc;


-- Question 6 - Operational Patterns

-- Business need: Operations wants to schedule more vehicles during peak times and fewer during quiet times.

-- 6A - Revenue by day of week

select
    day_of_week as day_num,
    day_name as day_name,
    count(*) as total_bookings,
    sum(total_fare) as total_revenue,
    round(avg(total_fare), 2) as avg_booking_value
from v_clean_trips
group by day_of_week, day_name
order by day_num;

-- 6B - Busiest departure times
-- Group by departure_time. Show which time slots carry the most passengers and generate the most revenue.

select 
	departure_time,
	count(passenger_name) as passengers,
	sum(total_fare) as revenue
from v_clean_trips
group by departure_time 
order by revenue desc;


-- 6C - Seat utilisation by vehicle type
-- Compare how full each vehicle type typically runs. 
-- Show: vehicle_type, avg_seats_booked, and a label - 'High Load' if avg > 3,
-- 'Medium Load' if 2-3, 'Low Load' if below 2.

select 
	vehicle_type,
	round(avg(seats_booked),2) as avg_seats_booked,
	case 
		when round(avg(seats_booked),2) > 3 then 'High Load'
		when round(avg(seats_booked),2) between 2 and 3 then 'Medium Load'
		else 'Low Load'
	end as label
from v_clean_trips
group by vehicle_type
order by avg_seats_booked;

-- Create Your Views - Hand Off to BI Developer

-- View 1: Route performance
create or replace view v_route_performance as
select
    route_code,
    route_from || '->' || route_to as route,
    count(*) as total_bookings,
    sum(seats_booked) as total_seats,
    sum(total_fare) as total_revenue,
    round(avg(fare_per_seat), 2)as avg_fare,
    round(avg(trip_rating), 2)as avg_rating
from v_clean_trips
group by route_code, route_from, route_to
order by total_revenue desc;

-- View 2: Driver performance
create or replace view v_driver_performance as
select 
	driver_name, 
	count(*) as total_trips, 
	sum(seats_booked) as total_seats_carried,
	sum(total_fare) as total_revenue, 
	round(avg(trip_rating),2) as avg_rating, 
	round(avg(driver_rating),2) as driver_rating
from v_clean_trips
group by driver_name 
order by total_revenue desc;


-- View 3: Monthly revenue trend
create or replace view v_monthly_revenue as
with monthly as(
	select 
		to_char(departure_date, 'YYYY-MM') as month,
		count(*) as bookings,
        sum(total_fare) as revenue
    from v_clean_trips
    group by to_char(departure_date, 'YYYY-MM')
)
select
    month, 
    bookings, 
    revenue,
    lag(revenue) over (order by month)as prev_month,
    revenue - lag(revenue) OVER (order by month) as change,
    round((revenue - lag(revenue) over (order by month))
        / nullif(lag(revenue) over (order by month),0) * 100, 1)as change_pct
from monthly 
order by month;

-- View 4: Cancellation analysis
create or replace view v_cancellation_analysis as
select
    route_code,
    route_from || ' → ' || route_to as route,
    count(*) as total_bookings,
    sum(case when booking_status = 'Completed' then 1 else 0 end) as completed,
    sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled,
    sum(case when booking_status = 'No Show' then 1 else 0 end) as no_show,
    round(sum(case when booking_status in ('Cancelled')
             then 1 else 0 end) * 100.0 / count(*), 1) as cancel_rate_pct
from bookings
group by route_code, route_from, route_to
order by cancel_rate_pct desc;

-- View 5: Passenger city insights
create or replace view v_passenger_insights as
select 
	passenger_city, 
	count(*) as total_bookings,
	sum(seats_booked) as total_seats,
	sum(total_fare) as total_revenue, 
	round(avg(fare_per_seat),2) as average_fare
from v_clean_trips
group by passenger_city 
having count(*) >= 3
order by total_bookings desc;


-- Add Indexes

CREATE INDEX idx_bookings_depdate ON bookings (departure_date);
CREATE INDEX idx_bookings_route  ON bookings (route_code);
CREATE INDEX idx_bookings_driver ON bookings (driver_name);
CREATE INDEX idx_bookings_status  ON bookings (booking_status);
CREATE INDEX idx_bookings_payment  ON bookings (payment_method);
CREATE INDEX idx_bookings_vehicle  ON bookings (vehicle_type);
CREATE INDEX idx_bookings_passcity  ON bookings (passenger_city);

SELECT tablename, indexname FROM pg_indexes
WHERE schemaname = 'safari_connect';


	










