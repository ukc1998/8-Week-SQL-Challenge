### A. Pizza Metrics


-- 1. How many pizzas were ordered?

# Solution:

SELECT 
    COUNT(pizza_id) AS NOPO
FROM
    customer_orders;



-- 2. How many unique customer orders were made?

# Solution:

SELECT 
    COUNT(DISTINCT order_id) AS NOUO
FROM
    customer_orders;



-- 3. How many successful orders were delivered by each runner?

# Solution:

SELECT 
    runner_id,
    COUNT(order_id) AS NOSO
FROM
    runner_orders
WHERE
    cancellation IS NULL
GROUP BY runner_id;



-- 4. How many of each type of pizza was delivered?

# Solution:

WITH cte AS (
			SELECT 
				c.pizza_id, r.cancellation
			FROM
				customer_orders c
					JOIN
				runner_orders r
					ON c.order_id = r.order_id
			)
SELECT 
    pn.pizza_name, COUNT(pn.pizza_name) AS NOPTD
FROM
    cte
        JOIN
    pizza_names pn ON cte.pizza_id = pn.pizza_id
WHERE
    cancellation IS NULL
GROUP BY pn.pizza_name;



-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

WITH cte AS (
			SELECT 
				c.customer_id, c.pizza_id, r.cancellation
			FROM
				customer_orders c
					JOIN
				runner_orders r ON c.order_id = r.order_id
			)
SELECT 
    cte.customer_id,
    pn.pizza_name,
    COUNT(pn.pizza_name) AS NOPTOC
FROM
    cte
        JOIN
    pizza_names pn ON cte.pizza_id = pn.pizza_id
GROUP BY pn.pizza_id , cte.customer_id
ORDER BY cte.customer_id , pn.pizza_name;


-- 6. What was the maximum number of pizzas delivered in a single order?

# Solution:

WITH cte AS (
			SELECT 
				c.order_id,
				c.pizza_id,
				r.cancellation
			FROM
				customer_orders c
					JOIN
				runner_orders r ON c.order_id = r.order_id
			)
SELECT 
    COUNT(*) AS MPD
FROM
    cte
WHERE
    cancellation IS NULL
GROUP BY order_id
ORDER BY MPD DESC
LIMIT 1;
    

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

# Solution:

WITH cte AS (
			SELECT 
				c.customer_id,
				c.exclusions,
				c.extras
			FROM
				customer_orders c
					JOIN
				runner_orders r ON c.order_id = r.order_id
			WHERE
				cancellation IS NULL
			)
SELECT customer_id,
		SUM(CASE
			WHEN
				exclusions IS NOT NULL OR extras IS NOT NULL 
            THEN 1 
            ELSE 0 
		END) AS atleast_1_change,
		SUM(CASE 
			WHEN
				exclusions IS NULL AND extras IS NULL
			THEN 1
            ELSE 0
		END) AS no_change
FROM cte
GROUP BY customer_id;



-- 8. How many pizzas were delivered that had both exclusions and extras?

# Solution:

WITH cte AS (
			SELECT 
				c.customer_id,
				SUM(CASE
					WHEN
						exclusions IS NOT NULL AND extras IS NOT NULL
					THEN 1
					ELSE 0
				END) AS both_change
			FROM
				customer_orders c
					INNER JOIN
				runner_orders r ON c.order_id = r.order_id
			WHERE
				cancellation IS NULL
			GROUP BY c.customer_id
			HAVING both_change != 0
            )
SELECT
	count(*) AS PDWBEE;
            


-- 9. What was the total volume of pizzas ordered for each hour of the day?

# Solution:

SELECT 
    EXTRACT(HOUR FROM order_time) AS atHour,
    COUNT(order_id) AS TPO
FROM
    customer_orders
GROUP BY atHour
ORDER BY atHour;

-- 10. What was the volume of orders for each day of the week?

# Solution:

SELECT 
    DAYNAME(order_time) AS `Day`, COUNT(order_id) AS TPO
FROM
    customer_orders
GROUP BY `Day`
ORDER BY WEEKDAY(order_time);








### B. Runner and Customer Experience


-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

# Solution:

SELECT 
    WEEKOFYEAR(registration_date) AS registration_week,
    COUNT(runner_id) AS runners_signed_up
FROM
    runners
GROUP BY registration_week;


-- 2. What was the average time in minutes it took for each runner to arrive 
--    at the Pizza Runner HQ to pickup the order?

# Solution:

SELECT 
    runner_id,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE,
                order_time,
                pickup_time))) AS avg_pickup_time
FROM
    customer_orders c
        INNER JOIN
    runner_orders r ON c.order_id = r.order_id
WHERE
    cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;



-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

# Solution:

WITH cte AS (
			SELECT 
				c.order_id,
				COUNT(c.order_id) AS pizza_count,
				TIMESTAMPDIFF(MINUTE, order_time, pickup_time) AS prep_time
			FROM
				customer_orders c
					INNER JOIN
				runner_orders r ON c.order_id = r.order_id
			WHERE
				cancellation IS NULL
			GROUP BY order_id)
SELECT 
    pizza_count,
    ROUND(AVG(prep_time), 2) AS avg_prep_time
FROM
    cte
GROUP BY pizza_count;



-- 4. What was the average distance travelled for each customer?

# Solution:

WITH cte1 AS (
			SELECT 
				c.order_id, c.customer_id, distance
			FROM
				customer_orders c
					INNER JOIN
				runner_orders r ON c.order_id = r.order_id
			WHERE
				cancellation IS NULL
			),
cte2 AS (
		SELECT
			DISTINCT *
		FROM
			cte1
		)
SELECT 
    customer_id,
    ROUND(AVG(distance), 1) AS avg_dist
FROM
    cte2
GROUP BY customer_id;


-- 5. What was the difference between the longest and shortest delivery times for all orders?

# Solution:

SELECT 
    MAX(delivery_time) - MIN(delivery_time) AS difference
FROM
    (
    SELECT 
        TIMESTAMPDIFF(MINUTE, order_time, pickup_time) + duration AS delivery_time
    FROM
        customer_orders c
    INNER JOIN runner_orders r ON c.order_id = r.order_id
    WHERE
        cancellation IS NULL
	) alias;



-- 6. What was the average speed for each runner for each delivery and 
--    do you notice any trend for these values?

# Solution:

SELECT 
    order_id,
    runner_id,
    distance,
    duration,
    ROUND(distance * 60 / duration, 2) AS speed
FROM
    runner_orders
WHERE
    cancellation IS NULL;

# There is one record with speed 93.60 km/hr as a single extreme value
# Most of the records have speed ranging between 35 to 45


-- 7. What is the successful delivery percentage for each runner?

# Solution:

SELECT 
    runner_id,
    ROUND((checks_delivered / checks_ordered) * 100,1) AS successful_deliveries_percent
FROM
    (
    SELECT 
        runner_id,
		SUM(CASE
			WHEN cancellation IS NULL THEN 1
			ELSE 0
		END) AS checks_delivered,
		SUM(CASE
			WHEN order_id IS NOT NULL THEN 1
			ELSE 0
		END) AS checks_ordered
    FROM
        runner_orders
    GROUP BY runner_id) alias;








### C. Ingredient Optimisation

-- 1. What are the standard ingredients for each pizza?

# Solution:

-- Step_1 :

SELECT 
    pr.pizza_id,
    SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ', ', pt.topping_id), ', ', - 1) topping_id
FROM
    pizza_toppings pt
        INNER JOIN
    pizza_recipes pr ON CHAR_LENGTH(pr.toppings) - CHAR_LENGTH(REPLACE(pr.toppings, ',', '')) >= pt.topping_id - 1
ORDER BY pizza_id;
  
  
  
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
  ON CHAR_LENGTH(pr.toppings)- CHAR_LENGTH(REPLACE(pr.toppings, ',', ''))>pt.topping_id-2
ORDER BY
  pizza_id;
 
 
 
 
 -- Step_2:
 
SELECT 
    pn.pizza_id,
    GROUP_CONCAT(topping_name) AS list_of_ingredients
FROM
    (
    SELECT 
        pr.pizza_id,
            pt.topping_name,
            SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ', ', pt.topping_id), ', ', - 1) topping_id
    FROM
        pizza_toppings pt
    INNER JOIN pizza_recipes pr ON CHAR_LENGTH(pr.toppings) - CHAR_LENGTH(REPLACE(pr.toppings, ',', '')) + 1 >= pt.topping_id
    ) alias
        INNER JOIN
    pizza_names pn ON alias.pizza_id = pn.pizza_id
GROUP BY pizza_name;




-- 2. What was the most commonly added extra?

# Solution:

WITH cte1 AS (
			SELECT 
				extra_1 AS topping_id_as_extra,
                COUNT(extra_1) AS count
			FROM
				(SELECT 
					order_id,
					pizza_id,
					SUBSTRING_INDEX(extras, ', ', 1) AS extra_1
				FROM
					customer_orders UNION
                    SELECT 
						order_id,
						pizza_id,
						CASE
							WHEN LENGTH(extras) > 1 THEN SUBSTRING_INDEX(extras, ', ', - 1)
							ELSE NULL
						END AS extra_2
					FROM
						customer_orders
			) alias
			WHERE
				extra_1 IS NOT NULL
			GROUP BY extra_1),
cte2 AS (
		SELECT 
			topping_name, count
		FROM
			cte1
				JOIN
			pizza_toppings pt ON cte1.topping_id_as_extra = pt.topping_id
		ORDER BY count DESC , pt.topping_id)
SELECT 
    *
FROM
    cte2
WHERE
    count = (SELECT MAX(count)FROM cte2);



-- 3. What was the most common exclusion?

# Solution:

WITH cte AS (
				SELECT
					topping_name, count(*) as count
				FROM (
					  SELECT 
						SUBSTRING_INDEX(SUBSTRING_INDEX(exclusions, ', ', pt.topping_id), ', ', -1) exclusions
					  FROM pizza_toppings pt
								INNER JOIN customer_orders c
								ON CHAR_LENGTH(c.exclusions) -CHAR_LENGTH(REPLACE(c.exclusions, ',', ''))+1 >=pt.topping_id
					  ) alias
				JOIN pizza_toppings pt ON alias.exclusions = pt.topping_id
				GROUP BY exclusions)
SELECT 
    *
FROM
    cte
WHERE
    count = (SELECT MAX(count) FROM cte);
              




-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

# Solution:

WITH master_cte AS (
SELECT DISTINCT * FROM (
WITH cte1 AS (
			SELECT 
				order_id,
				pizza_id,
				SUBSTRING_INDEX(extras, ', ', 1) AS extra_1,
				SUBSTRING_INDEX(exclusions, ', ', 1) AS exclusion_1
			FROM
				customer_orders UNION
			SELECT 
				order_id,
				pizza_id,
				CASE
					WHEN LENGTH(extras) > 1 
						THEN SUBSTRING_INDEX(extras, ', ', - 1) ELSE NULL END AS extra_2,
				CASE
					WHEN LENGTH(exclusions) > 1 
						THEN SUBSTRING_INDEX(exclusions, ', ', - 1) ELSE NULL END AS exclusion_2
			FROM
				customer_orders
			),
cte2 AS (
SELECT 
    order_id,
    pizza_id,
    extra_1,
    topping_name AS extra_name,
    exclusion_1
FROM
    cte1
        LEFT JOIN
    pizza_toppings pt ON cte1.extra_1 = pt.topping_id
		),
cte3 AS (
SELECT 
    order_id,
    pizza_id,
    extra_1,
    extra_name,
    exclusion_1,
    topping_name AS exclusion_name
FROM
    cte2
        LEFT JOIN
    pizza_toppings pt ON cte2.exclusion_1 = pt.topping_id
		),
cte4 AS (
		SELECT 
			order_id,
			cte3.pizza_id,
			pizza_name,
			extra_1,
			GROUP_CONCAT(extra_name SEPARATOR ', ') AS extra_name, exclusion_1,
			GROUP_CONCAT(exclusion_name SEPARATOR ', ') AS exclusion_name
		FROM
			cte3
				JOIN
			pizza_names pn ON cte3.pizza_id = pn.pizza_id
		GROUP BY order_id , pizza_id
        )
SELECT 
    cte4.order_id,
    cte4.pizza_id,
    pizza_name,
    extras,
    extra_name,
    exclusions,
    exclusion_name
FROM
    cte4
        JOIN
    customer_orders c ON cte4.order_id = c.order_id) alias1
		)
SELECT 
    order_id, pizza_id, extras, exclusions,
    CASE
        WHEN extras IS NOT NULL AND exclusions IS NOT NULL
			THEN CONCAT(pizza_name, ' - Exclude ', exclusion_name, ' - Extra ', extra_name)
        WHEN extras IS NOT NULL AND exclusions IS NULL
			THEN CONCAT(pizza_name, ' - Extra ', extra_name)
        WHEN extras IS NULL AND exclusions IS NOT NULL
			THEN CONCAT(pizza_name, ' - Exclude ', exclusion_name)
        ELSE pizza_name
    END AS output
FROM
    master_cte;





-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order 
--    from the customer_orders table and add a 2x in front of any relevant ingredients
--    For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

# Solution:

WITH master_cte AS (
SELECT DISTINCT * FROM (
WITH cte1 AS (
SELECT 
	pn.pizza_id, group_concat(topping_name ORDER BY topping_name SEPARATOR', ') AS list_of_ingredients 
FROM (
	SELECT
	  pr.pizza_id, pt.topping_name,
	  SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ', ', pt.topping_id), ', ', -1) topping_id
	FROM
	  pizza_toppings pt INNER JOIN pizza_recipes pr
	  ON CHAR_LENGTH(pr.toppings) -CHAR_LENGTH(REPLACE(pr.toppings, ',', ''))>=pt.topping_id-1) alias 
INNER JOIN pizza_names pn on alias.pizza_id = pn.pizza_id
GROUP BY pizza_name
			),
cte2 AS (
		SELECT order_id, c.pizza_id, extras, list_of_ingredients 
		FROM 
			cte1 JOIN customer_orders c ON cte1.pizza_id = c.pizza_id
		),
cte3 AS (
		SELECT 
			order_id, cte2.pizza_id, extras, CONCAT(pizza_name, ': ', list_of_ingredients) AS ingredient_list
		FROM
			cte2
				JOIN
			pizza_names pn ON cte2.pizza_id = pn.pizza_id
		),
cte4 AS (
		SELECT 
			order_id, pizza_id, extra_1 AS extras_id, ingredient_list
		FROM
			(SELECT 
				order_id, pizza_id, SUBSTRING_INDEX(extras, ', ', 1) AS extra_1, ingredient_list
			FROM
				cte3 UNION
			SELECT 
				order_id, pizza_id,
                CASE WHEN LENGTH(extras)>1 THEN SUBSTRING_INDEX(extras, ', ', - 1) ELSE NULL END AS extra_2,
                ingredient_list
		
			FROM
				cte3
			) alias
		),
cte5 AS (
SELECT order_id, pizza_id, GROUP_CONCAT(extras_id SEPARATOR', ') AS extras_id,
							GROUP_CONCAT(topping_name SEPARATOR', ') AS extras_name, ingredient_list
FROM cte4 LEFT JOIN pizza_toppings pt ON cte4.extras_id = pt.topping_id
GROUP BY order_id, pizza_id
		)
SELECT cte5.order_id, cte5.pizza_id, extras, extras_name, ingredient_list
FROM cte5 JOIN customer_orders c ON cte5.order_id = c.order_id) alias2
		)
SELECT 
    order_id, pizza_id, extras,
    CASE
        WHEN extras IS NOT NULL AND LENGTH(extras) = 1
			THEN REPLACE(ingredient_list, SUBSTRING_INDEX(extras_name, ', ', 1),
						 CONCAT('2x', SUBSTRING_INDEX(extras_name, ', ', 1)))
        WHEN extras IS NOT NULL AND LENGTH(extras) > 2
			THEN REPLACE(REPLACE(ingredient_list, SUBSTRING_INDEX(extras_name, ', ', 1),
								 CONCAT('2x', SUBSTRING_INDEX(extras_name, ', ', 1))),
						 SUBSTRING_INDEX(extras_name, ', ', - 1),
						 CONCAT('2x', SUBSTRING_INDEX(extras_name, ', ', - 1)))
        ELSE ingredient_list
    END AS output
FROM
    master_cte;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas 
--    sorted by most frequent first?

# Solution:

with cte1 as (
			SELECT 
				CASE
					WHEN extras IS NULL AND exclusions IS NULL
						THEN toppings
					WHEN extras IS NOT NULL AND exclusions IS NULL
						THEN CONCAT(toppings, ', ', extras)
					WHEN extras IS NULL AND LENGTH(exclusions) = 1
						THEN REPLACE(toppings, CONCAT(exclusions, ', '), '')
					WHEN extras IS NULL AND LENGTH(exclusions) > 1
						THEN REPLACE(REPLACE(toppings, CONCAT(SUBSTRING_INDEX(exclusions, ', ', 1), ', '), ''),
									 CONCAT(SUBSTRING_INDEX(exclusions, ', ', 1), ', '), '')
					WHEN extras IS NOT NULL AND LENGTH(exclusions) = 1
						THEN CONCAT(REPLACE(toppings, CONCAT(exclusions, ', '), ''), ', ', extras)
					ELSE CONCAT(REPLACE(REPLACE(toppings, CONCAT(SUBSTRING_INDEX(exclusions, ', ', 1), ', '), ''),
								CONCAT(SUBSTRING_INDEX(exclusions, ', ', - 1), ', '), ''), ', ', extras)
				END AS output
			FROM
				customer_orders c
					JOIN
				pizza_recipes pr ON c.pizza_id = pr.pizza_id
			),
cte2 AS (
		SELECT 
			SUBSTRING_INDEX(SUBSTRING_INDEX(output, ', ', pt.topping_id),
					', ',
					- 1) AS id,
			COUNT(*) AS count
		FROM
			pizza_toppings pt
				JOIN
			cte1 ON CHAR_LENGTH(output) - CHAR_LENGTH(REPLACE(output, ',', '')) + 1 >= pt.topping_id
		GROUP BY id
        )
SELECT 
    pt.topping_name, count
FROM
    cte2
        JOIN
    pizza_toppings pt ON cte2.id = pt.topping_id
ORDER BY count DESC;

			    







#### D. Pricing and Ratings

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
--    how much money has Pizza Runner made so far if there are no delivery fees?

# Solution:

WITH cte AS (
			SELECT 
				pizza_id, COUNT(*) AS count
			FROM
				customer_orders c
					JOIN
				runner_orders r ON c.order_id = r.order_id
			WHERE
				cancellation IS NULL
			GROUP BY pizza_id)
SELECT 
    pizza_name,
    CASE
        WHEN cte.pizza_id = 1 THEN count * 12
        ELSE count * 10
    END AS price
FROM
    cte
        JOIN
    pizza_names pn ON pn.pizza_id = cte.pizza_id;



-- 2. What if there was an additional $1 charge for any pizza extras?
--    Add cheese is $1 extra

# Solution:

WITH cte AS (
			SELECT 
				pizza_id,
				COUNT(*) AS count,
				SUM(CHAR_LENGTH(extras) - CHAR_LENGTH(REPLACE(extras, ',', '')) + 1) AS NOE
			FROM
				customer_orders c
					JOIN
				runner_orders r ON c.order_id = r.order_id
			WHERE
				cancellation IS NULL
			GROUP BY pizza_id)
SELECT 
    pizza_name,
    CASE
        WHEN cte.pizza_id = 1 THEN (count * 12) + (1 * NOE)
        ELSE (count * 10) + (1 * NOE)
    END AS new_price
FROM
    cte
        JOIN
    pizza_names pn ON cte.pizza_id = pn.pizza_id;



-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner,
--    how would you design an additional table for this new dataset - generate a schema for this new table and 
--    insert your own data for ratings for each successful customer order between 1 to 5.

# Solution:

DROP TABLE IF EXISTS pizza_runner.ratings;
CREATE TABLE pizza_runner.ratings (
    order_id INT,
    rating INT
);

SELECT 
    order_id
FROM
    runner_orders
WHERE
    cancellation IS NULL;
    
    
    
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



SELECT 
    *
FROM
    ratings;



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

SELECT 
    c.order_id,
    c.customer_id,
    r.runner_id,
    t.rating,
    c.order_time,
    r.pickup_time,
    TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time) AS time_difference,
    r.duration,
    ROUND((distance * 1.0) / (duration * 1.0 / 60), 2) AS average_speed,
    COUNT(c.pizza_id) AS total_pizzas
FROM
    customer_orders c
        JOIN
    runner_orders r ON c.order_id = r.order_id
        JOIN
    ratings t ON t.order_id = c.order_id
WHERE
    cancellation IS NULL
GROUP BY c.order_id , c.order_time , r.pickup_time
ORDER BY c.order_id , c.customer_id;



-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras
-- and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner 
-- have left over after these deliveries?

# Solution:

WITH cte AS (
			SELECT 
				pizza_id, COUNT(*) AS count, SUM(distance) AS total_distance
			FROM
				customer_orders c
					JOIN
				runner_orders r ON c.order_id = r.order_id
			WHERE
				cancellation IS NULL
			GROUP BY pizza_id
            )
SELECT 
    SUM(CASE
        WHEN cte.pizza_id = 1 THEN count * 12 - (total_distance * 0.3)
        ELSE count * 10 - (total_distance * 0.3)
    END) AS savings
FROM
    cte
        JOIN
    pizza_names pn ON pn.pizza_id = cte.pizza_id;









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