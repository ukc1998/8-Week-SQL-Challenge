SET sql_safe_updates = 0;
UPDATE customer_orders SET exclusions = NULL WHERE exclusions = 'null' OR exclusions = '';
UPDATE customer_orders SET extras = NULL WHERE extras = 'null' OR extras = '';



UPDATE runner_orders SET pickup_time = NULL WHERE pickup_time = 'null';
UPDATE runner_orders SET distance = NULL WHERE distance = 'null';
UPDATE runner_orders SET duration = NULL WHERE duration = 'null';
UPDATE runner_orders SET cancellation = NULL WHERE cancellation = 'null' OR cancellation = '';

UPDATE runner_orders SET distance = SUBSTR(distance, 1, LENGTH(distance) - 2 ) WHERE distance LIKE "%km";
UPDATE runner_orders SET duration = TRIM('minute' FROM duration) WHERE duration LIKE "%minute";
UPDATE runner_orders SET duration = TRIM('minutes' FROM duration) WHERE duration LIKE "%minutes";
UPDATE runner_orders SET duration = TRIM('mins' FROM duration) WHERE duration LIKE "%mins";



ALTER TABLE runner_orders
MODIFY COLUMN pickup_time DATETIME NULL,
MODIFY COLUMN distance DECIMAL(5,1) NULL,
MODIFY COLUMN duration INT NULL;