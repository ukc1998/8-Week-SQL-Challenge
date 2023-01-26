set sql_safe_updates = 0;
UPDATE customer_orders SET exclusions = null WHERE exclusions = 'null' or exclusions = '';
UPDATE customer_orders SET extras = null WHERE extras = 'null' or extras = '';

CREATE TABLE temp LIKE customer_orders;
INSERT INTO temp SELECT DISTINCT * FROM customer_orders;
DROP TABLE customer_orders;
RENAME TABLE temp TO customer_orders;




UPDATE runner_orders SET pickup_time = null WHERE pickup_time = 'null';
UPDATE runner_orders SET distance = null WHERE distance = 'null';
UPDATE runner_orders SET duration = null WHERE duration = 'null';
UPDATE runner_orders SET cancellation = null WHERE cancellation = 'null' or cancellation = '';

UPDATE runner_orders SET distance = substr(distance, 1, length(distance) - 2 ) WHERE distance like "%km";
UPDATE runner_orders SET duration = TRIM('minute' from duration) WHERE duration like "%minute";
UPDATE runner_orders SET duration = TRIM('minutes' from duration) WHERE duration like "%minutes";
UPDATE runner_orders SET duration = TRIM('mins' from duration) WHERE duration like "%mins";


alter table runner_orders
modify column pickup_time datetime null,
modify column distance decimal(5,1) null,
modify column duration int null;