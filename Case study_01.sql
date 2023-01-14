CREATE database dannys_dinner;
use dannys_dinner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  
select * from sales;
select * from menu;
select * from members;
    
    
    
  -- 1. What is the total amount each customer spent at the restaurant?
  
  # Solution:
 select s.customer_id, sum(m.price) as expense
 from sales s 
 join menu m 
 on s.product_id = m.product_id 
 group by customer_id;
 
 
 
 -- 2. How many days has each customer visited the restaurant?

# Solution:
select customer_id, count(distinct order_date) as days_visited
from sales
group by customer_id;




-- 3. What was the first item from the menu purchased by each customer?

# Solution:
with cte as (select customer_id, product_name, order_date, dense_rank() over(partition by customer_id order by order_date) as rn 
					from sales s
					join menu m
                    on s.product_id = m.product_id)
select customer_id, product_name
from cte
where rn = 1
GROUP BY customer_id, product_name;



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

# Solution:

SELECT  COUNT(product_name) AS count, product_name
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY product_name 
ORDER BY count DESC 
LIMIT 1;



SELECT  customer_id, COUNT(product_name) AS count_ramen
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
where product_name = "ramen"
group by customer_id;


-- 5. Which item was the most popular for each customer?

# Solution:

WITH cte AS (select *, dense_rank() over(partition by customer_id order by cnt desc) as rn 
				from (SELECT  customer_id, product_name, COUNT(product_name) AS cnt
					FROM sales s 
					JOIN menu m 
					ON s.product_id = m.product_id
					GROUP BY product_name, customer_id) subquey)
select customer_id, product_name, cnt
from cte
where  rn =1;


-- 6. Which item was purchased first by the customer after they became a member?

# Solution:

SELECT customer_id, product_name FROM (SELECT  s.customer_id, s.order_date, m.product_name, me.join_date,
												dense_rank() over(partition by customer_id order by order_date) as rn
										FROM sales s 
										JOIN menu m ON s.product_id = m.product_id 
                                        JOIN members me on s.customer_id = me.customer_id
                                        WHERE join_date <= order_date) subquery
								WHERE rn = 1;
                                
                                

-- 7. Which item was purchased just before the customer became a member?

# SOlution:

SELECT customer_id, product_name FROM (SELECT  s.customer_id, s.order_date, m.product_name, me.join_date,
												dense_rank() over(partition by customer_id order by order_date desc) as rn
										FROM sales s 
										JOIN menu m ON s.product_id = m.product_id 
                                        JOIN members me on s.customer_id = me.customer_id
                                        WHERE join_date > order_date) subquery
								WHERE rn = 1;


-- 8. What is the total items and amount spent for each member before they became a member?

# Solution:

SELECT  s.customer_id, count(s.product_id) AS total_items, sum(m.price) AS amount_spent
FROM sales s 
JOIN menu m ON s.product_id = m.product_id 
JOIN members me on s.customer_id = me.customer_id
WHERE join_date > order_date
GROUP BY s.customer_id;



-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?

SELECT customer_id, sum(CASE 
    WHEN product_name = 'sushi' THEN price * 20
    WHEN product_name != 'sushi' THEN price * 10
    END) AS points  FROM sales s JOIN menu m ON s.product_id = m.product_id GROUP BY customer_id;
    
    

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

SELECT s.customer_id, sum(CASE 
	WHEN order_date < join_date AND product_name = "sushi" THEN price * 20
    WHEN order_date < join_date AND product_name != "sushi" THEN price * 10
    WHEN order_date <= adddate(join_date, 6) THEN price * 20
    WHEN order_date > adddate(join_date, 6) AND product_name = "sushi" THEN price * 20
    ELSE price * 10
    END) AS points  FROM sales s JOIN menu m ON s.product_id = m.product_id
								JOIN members me on s.customer_id = me.customer_id
                                WHERE monthname(order_date) = "January"
                                GROUP BY customer_id;