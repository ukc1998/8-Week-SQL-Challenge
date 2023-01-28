### A. Pizza Metrics


-- 1. How many pizzas were ordered?

# Solution:

select count(pizza_id) as NOPO from customer_orders;

-- 2. How many unique customer orders were made?

# Solution:

select count(distinct order_id) as NOUO from customer_orders;

-- 3. How many successful orders were delivered by each runner?

# Solution:

select runner_id, count(order_id) as NOSO 
from runner_orders 
where cancellation is null 
group by runner_id;


-- 4. How many of each type of pizza was delivered?

# Solution:

with cte as (select c.pizza_id, r.cancellation
			from customer_orders c join runner_orders r on c.order_id = r.order_id)
	select pn.pizza_name, count(pn.pizza_name) as NOPTD 
    from cte join pizza_names pn on cte.pizza_id = pn.pizza_id 
    where cancellation is null 
    group by pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

with cte as (select c.customer_id, c.pizza_id, r.cancellation
			from customer_orders c join runner_orders r on c.order_id = r.order_id)
	select cte.customer_id, pn.pizza_name, count(pn.pizza_name) as NOPTOC 
    from cte join pizza_names pn on cte.pizza_id = pn.pizza_id 
    group by pn.pizza_id, cte.customer_id
    order by cte.customer_id, pn.pizza_name;


-- 6. What was the maximum number of pizzas delivered in a single order?

# Solution:

with cte as (select c.order_id, c.pizza_id, r.cancellation
			from customer_orders c join runner_orders r on c.order_id = r.order_id)
	select count(*) as MPD
    from cte
    where cancellation is null 
    group by order_id
    order by MPD desc
    limit 1;
    

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

# Solution:

with cte as (select c.customer_id, c.exclusions, c.extras
			from customer_orders c join runner_orders r on c.order_id = r.order_id
			where cancellation is null)
select customer_id,
		sum(case when exclusions is not null or extras is not null then 1 else 0 end) as atleast_1_change,
		sum(case when exclusions is null and extras is null then 1 else 0 end) as no_change
from cte
group by customer_id;



-- 8. How many pizzas were delivered that had both exclusions and extras?

# Solution:

with cte as (select c.customer_id, 
sum(case when exclusions is not null and extras is not null then 1 else 0 end )as both_change
from customer_orders c
inner join runner_orders r
on c.order_id = r.order_id
where cancellation is null
group by c.customer_id
having both_change != 0)
select count(*) as PDWBEE;
            


-- 9. What was the total volume of pizzas ordered for each hour of the day?

# Solution:

select extract(hour from order_time) as atHour, count(order_id) as TPO
from customer_orders
group by atHour
order by atHour;

-- 10. What was the volume of orders for each day of the week?

# Solution:

select dayname(order_time) as `Day`, count(order_id) as TPO
from customer_orders
group by `Day`
order by weekday(order_time);








### B. Runner and Customer Experience


-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

# Solution:

SELECT  WEEKOFYEAR(registration_date) AS registration_week,
COUNT(runner_id) AS runners_signed_up
FROM runners
GROUP BY registration_week;


-- 2. What was the average time in minutes it took for each runner to arrive 
--    at the Pizza Runner HQ to pickup the order?

# Solution:

select runner_id, round(avg(timestampdiff(minute, order_time, pickup_time))) as avg_pickup_time
from customer_orders c
inner join runner_orders r
on c.order_id = r.order_id
where cancellation is null
group by runner_id
order by runner_id;



-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

# Solution:

with cte as (select c.order_id, count(c.order_id) as pizza_count, timestampdiff(minute, order_time, pickup_time) as prep_time
from customer_orders c
inner join runner_orders r
on c.order_id = r.order_id
where cancellation is null
group by order_id)
select pizza_count, round(avg(prep_time),2) as avg_prep_time from cte group by pizza_count;



-- 4. What was the average distance travelled for each customer?

# Solution:

with cte1 as (select c.order_id, c.customer_id, distance
from customer_orders c
inner join runner_orders r
on c.order_id = r.order_id
where cancellation is null),
cte2 as (select distinct * from cte1)
select customer_id, round(avg(distance),1) as avg_dist from cte2
group by customer_id;


-- 5. What was the difference between the longest and shortest delivery times for all orders?

# Solution:

select max(delivery_time) - min(delivery_time) as difference 
from (select timestampdiff(minute, order_time, pickup_time) + duration as delivery_time
		from customer_orders c
		inner join runner_orders r
		on c.order_id = r.order_id
		where cancellation is null) alias;



-- 6. What was the average speed for each runner for each delivery and 
--    do you notice any trend for these values?

# Solution:

select order_id, runner_id, distance, duration, round(distance*60/duration, 2) as speed
from runner_orders
where cancellation is null;

# There is one record with speed 93.60 km/hr as a single extreme value
# Most of the records have speed ranging between 35 to 45


-- 7. What is the successful delivery percentage for each runner?

# Solution:

select runner_id, round((checks_delivered/checks_ordered)*100,1) as successful_deliveries_percent
					from (select runner_id, sum(case when cancellation is null then 1 else 0 end) as checks_delivered,
											sum(case when order_id is not null then 1 else 0 end) as checks_ordered
						from runner_orders
						group by runner_id) alias;








### C. Ingredient Optimisation

-- 1. What are the standard ingredients for each pizza?

# Solution:

-- Step_1 :

SELECT
  pr.pizza_id,
  SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ', ', pt.topping_id), ', ', -1) topping_id
FROM
  pizza_toppings pt INNER JOIN pizza_recipes pr
  ON CHAR_LENGTH(pr.toppings)
     -CHAR_LENGTH(REPLACE(pr.toppings, ',', ''))>=pt.topping_id-1
ORDER BY
  pizza_id;
  
  
  
  -- Step_1 Alternative :


SELECT
  pr.pizza_id,
  SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ', ', pt.topping_id), ', ', -1) topping_id
FROM
  pizza_toppings pt INNER JOIN pizza_recipes pr
  ON CHAR_LENGTH(pr.toppings)
     -CHAR_LENGTH(REPLACE(pr.toppings, ',', '')) + 1 >= pt.topping_id
ORDER BY
  pizza_id;
  
  
  
  
 
 
 -- Step_1 alternative:
 
 SELECT
  pr.pizza_id,
  SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ', ', pt.topping_id), ', ', -1) topping_id
FROM
  pizza_toppings pt INNER JOIN pizza_recipes pr
  ON CHAR_LENGTH(pr.toppings)
     -CHAR_LENGTH(REPLACE(pr.toppings, ',', ''))>pt.topping_id-2
ORDER BY
  pizza_id;
 
 
 
 
 -- Step_2:
 
SELECT pn.pizza_id, group_concat(topping_name) as list_of_ingredients
from (SELECT pr.pizza_id, pt.topping_name,
			 SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ', ', pt.topping_id), ', ', -1) topping_id
	  FROM pizza_toppings pt INNER JOIN pizza_recipes pr
	  ON CHAR_LENGTH(pr.toppings) -CHAR_LENGTH(REPLACE(pr.toppings, ',', ''))+1 >=pt.topping_id) alias 
INNER JOIN pizza_names pn on alias.pizza_id = pn.pizza_id
GROUP BY pizza_name;


-- 2. What was the most commonly added extra?

# Solution:

with cte1 as (
select extra_1 as topping_id_as_extra, count(extra_1) as count from 
(select order_id, pizza_id, substring_index(extras,', ',1) as extra_1 from customer_orders
union
select order_id, pizza_id, case when length(extras) > 1 then substring_index(extras,', ',-1) else null end as extra_2 from customer_orders) alias
where extra_1  is not null
group by extra_1),
cte2 as (
select topping_name, count from cte1 join pizza_toppings pt on cte1.topping_id_as_extra = pt.topping_id
order by count desc, pt.topping_id)
select * from cte2 where count = (select max(count) from cte2);



-- 3. What was the most common exclusion?

# Solution:

WITH cte as (
				SELECT topping_name, count(*) as count
				FROM (
					  SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(exclusions, ', ', pt.topping_id), ', ', -1) exclusions
					  FROM pizza_toppings pt INNER JOIN customer_orders c
					  ON CHAR_LENGTH(c.exclusions) -CHAR_LENGTH(REPLACE(c.exclusions, ',', ''))+1 >=pt.topping_id
					  ) alias
				JOIN pizza_toppings pt on alias.exclusions = pt.topping_id
				GROUP BY exclusions)
SELECT * FROM cte WHERE count = (SELECT max(count) FROM cte);
              




-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

# Solution:

with master_cte as (
select distinct * from (
with cte1 as (
select order_id, pizza_id, substring_index(extras,', ',1) as extra_1, substring_index(exclusions,', ',1) as exclusion_1 from customer_orders
union
select order_id, pizza_id, case when length(extras)>1 then substring_index(extras,', ',-1) else null end as extra_2,
						   case when length(exclusions) >1 then substring_index(exclusions,', ',-1) else null end as exclusion_2 from customer_orders),
cte2 as (
select order_id, pizza_id, extra_1, topping_name as extra_name, exclusion_1 from cte1 left join pizza_toppings pt on cte1.extra_1 = pt.topping_id),
cte3 as (
select order_id, pizza_id, extra_1, extra_name, exclusion_1, topping_name as exclusion_name  
from cte2 left join pizza_toppings pt on cte2.exclusion_1 = pt.topping_id),
cte4 as (
select order_id, cte3.pizza_id, pizza_name, extra_1,
		group_concat(extra_name SEPARATOR', ') AS extra_name, exclusion_1,
		group_concat(exclusion_name SEPARATOR', ') AS exclusion_name
from cte3 join pizza_names pn on cte3.pizza_id = pn.pizza_id
group by order_id, pizza_id)
select cte4.order_id, cte4.pizza_id, pizza_name, extras, extra_name, exclusions, exclusion_name
from cte4 join customer_orders c on cte4.order_id = c.order_id) alias1)
select order_id, pizza_id, extras, exclusions,
case when extras is not null and exclusions is not null then concat(pizza_name, " - Exclude ", exclusion_name, " - Extra ", extra_name)
	when extras is not null and exclusions is null then concat(pizza_name, " - Extra ", extra_name)
    when extras is null and exclusions is not null then concat(pizza_name, " - Exclude ", exclusion_name)
    else pizza_name end as output
from master_cte;





-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order 
--    from the customer_orders table and add a 2x in front of any relevant ingredients
--    For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

# Solution:

WITH master_cte AS (
SELECT DISTINCT * FROM (
WITH cte1 AS (
SELECT pn.pizza_id, group_concat(topping_name ORDER BY topping_name SEPARATOR', ') AS list_of_ingredients 
FROM (
	SELECT
	  pr.pizza_id, pt.topping_name,
	  SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ', ', pt.topping_id), ', ', -1) topping_id
	FROM
	  pizza_toppings pt INNER JOIN pizza_recipes pr
	  ON CHAR_LENGTH(pr.toppings) -CHAR_LENGTH(REPLACE(pr.toppings, ',', ''))>=pt.topping_id-1) alias 
INNER JOIN pizza_names pn on alias.pizza_id = pn.pizza_id
GROUP BY pizza_name),
cte2 AS (
SELECT order_id, c.pizza_id, extras, list_of_ingredients 
FROM 
	cte1 JOIN customer_orders c ON cte1.pizza_id = c.pizza_id),
cte3 AS (
SELECT order_id, cte2.pizza_id, extras, concat(pizza_name, ": ", list_of_ingredients) AS ingredient_list
FROM cte2 JOIN pizza_names pn ON cte2.pizza_id = pn.pizza_id),
cte4 AS (
SELECT order_id, pizza_id, extra_1 as extras_id, ingredient_list FROM 
(SELECT order_id, pizza_id, substring_index(extras,', ', 1) AS extra_1, ingredient_list FROM cte3
UNION
SELECT order_id, pizza_id, substring_index(extras,', ', -1) AS extra_2, ingredient_list FROM cte3) alias),
cte5 AS (
SELECT order_id, pizza_id, group_concat(extras_id SEPARATOR', ') AS extras_id,
							group_concat(topping_name SEPARATOR', ') AS extras_name, ingredient_list
FROM cte4 LEFT JOIN pizza_toppings pt ON cte4.extras_id = pt.topping_id
GROUP BY order_id, pizza_id)
SELECT cte5.order_id, cte5.pizza_id, extras, extras_name, ingredient_list
FROM cte5 JOIN customer_orders c ON cte5.order_id = c.order_id) alias2)
SELECT order_id, pizza_id, extras, 
CASE WHEN extras IS NOT NULL and length(extras) = 1
THEN REPLACE(ingredient_list, substring_index(extras_name,', ', 1), concat('2x',substring_index(extras_name,', ', 1)))
WHEN extras IS NOT NULL AND length(extras) > 2
THEN REPLACE(REPLACE(ingredient_list, substring_index(extras_name,', ', 1), concat('2x',substring_index(extras_name,', ', 1))), substring_index(extras_name,', ', -1), concat('2x',substring_index(extras_name,', ', -1)))
ELSE ingredient_list
END AS output
FROM master_cte;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas 
--    sorted by most frequent first?

# Solution:

with cte1 as (
select case when extras is null and exclusions is null then toppings
		    when extras is not null and exclusions is null 
				 then concat(toppings, ", ", extras)
		    when extras is null and length(exclusions) = 1 
				 then replace(toppings, concat(exclusions , ", ") , "")
		    when extras is null and length(exclusions) > 1 
				 then replace(replace(toppings, concat(substring_index(exclusions,', ', 1), ", "), ""), concat(substring_index(exclusions,', ', 1), ", "), "")
			when extras is not null and length(exclusions) = 1
				 then concat(replace(toppings, concat(exclusions , ", "), ""), ", ", extras)
		    else concat(replace(replace(toppings, concat(substring_index(exclusions,', ', 1), ", "), ""), concat(substring_index(exclusions,', ', -1), ", "), ""), ", ", extras)
            end as output
from customer_orders c join pizza_recipes pr on c.pizza_id = pr.pizza_id),
cte2 as (
select
  substring_index(substring_index(output, ', ', pt.topping_id), ', ', -1) as id,
  count(*) as count
from
  pizza_toppings pt join cte1
  on char_length(output) - char_length(replace(output, ',', '')) +1 >= pt.topping_id
group by id)
select pt.topping_name, count
from cte2 join pizza_toppings pt on cte2.id = pt.topping_id
order by count desc;

			    







#### D. Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
--    how much money has Pizza Runner made so far if there are no delivery fees?

# Solution:

with cte as (
select pizza_id, count(*) as count 
from customer_orders c join runner_orders r on c.order_id = r.order_id 
where cancellation is null 
group by pizza_id)
select pizza_name, case when cte.pizza_id = 1 then count*12 else count*10 end as price
from cte
join pizza_names pn on pn.pizza_id = cte.pizza_id;



-- 2. What if there was an additional $1 charge for any pizza extras?
--    Add cheese is $1 extra

# Solution:

with cte as (
select pizza_id, count(*) as count, sum(char_length(extras) - char_length(replace(extras, ',', '')) +1) as NOE
from customer_orders c join runner_orders r on c.order_id = r.order_id 
where cancellation is null
group by pizza_id)
select pizza_name, case when cte.pizza_id = 1 then (count*12) + (1*NOE) else (count*10) + (1*NOE) end as new_price
from cte join pizza_names pn on cte.pizza_id = pn.pizza_id;



-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner,
--    how would you design an additional table for this new dataset - generate a schema for this new table and 
--    insert your own data for ratings for each successful customer order between 1 to 5.

# Solution:

DROP TABLE IF EXISTS pizza_runner.ratings;
CREATE TABLE pizza_runner.ratings
(
	order_id	INT,
	rating		INT
);

SELECT order_id FROM runner_orders WHERE cancellation IS NULL;
INSERT INTO ratings (order_id, rating)
VALUES
  (1, 3),
  (2, 4),
  (3, 5),
  (4, 2),
  (5, 3),
  (7, 5),
  (8, 5),
  (10, 4);

SELECT * FROM ratings;



-- 4. Using your newly generated table - can you join all of the information together to form a table
--    which has the following information for successful deliveries?
--    customer_id
--    order_id
--    runner_id
--    rating
--    order_time
--    pickup_time
--    Time between order and pickup
--    Delivery duration
--    Average speed
--    Total number of pizzas

# Solution:

SELECT c.order_id,
       c.customer_id,
	   r.runner_id,
	   t.rating,
	   c.order_time,
	   r.pickup_time,
	   TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time) AS time_difference,
	   r.duration,
	   ROUND((distance * 1.0)/(duration *1.0 /60), 2) AS average_speed,
	   COUNT(c.pizza_id) AS total_pizzas

FROM customer_orders c
JOIN runner_orders r 
ON c.order_id = r.order_id
JOIN ratings t 
ON t.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY c.order_id,
	     c.order_time,
	     r.pickup_time
ORDER BY c.order_id, c.customer_id;



-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras
-- and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner 
-- have left over after these deliveries?

# Solution:

with cte as (
select pizza_id, count(*) as count, sum(distance) as total_distance 
from customer_orders c join runner_orders r on c.order_id = r.order_id 
where cancellation is null 
group by pizza_id)
select sum(case when cte.pizza_id = 1 then count*12 - (total_distance*0.3) else count*10 - (total_distance*0.3) end) as savings
from cte
join pizza_names pn on pn.pizza_id = cte.pizza_id;









### E. Bonus Questions

-- If Danny wants to expand his range of pizzas - how would this impact the existing data design?
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all 
-- the toppings was added to the Pizza Runner menu?

# Solution:

-- In this case, Dany will need to add modify tables pizza_names and pizza_recipes. 
-- In pizza_names, Dany should add an extra record with pizza_id as 3 and pizza_name as 'Flexiterian', and
-- in pizza_recipes, Dany should add an extra record with pizza_id as 3 and toppings as '1,2,3,4,5,6,7,8,9,10,11,12'
-- as demonstarted below:

# INSERT INTO pizza_names values (3,'Flexiterian');
# INSERT INTO pizza_recipes values (3, '1,2,3,4,5,6,7,8,9,10,11,12');