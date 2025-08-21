# 🍕 Case Study #2 - Pizza Runner

## D. Pricing and Ratings

Use temporary tables 'CUSTOMER_ORDERS_TEMP', 'RUNNER_ORDERS_TEMP', 'PIZZA_RECIPES_TEMP', 'TOPPING_SPLIT', 'EXTRAS_SPLIT' and 'EXCLUSIONS_SPLIT' created in part A and part C.

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

```sql
SELECT SUM(CASE
				WHEN PIZZA_NAME = 'Meatlovers' THEN 12
				ELSE 10
		   END) AS TOTAL_SALES
FROM #CUSTOMER_ORDERS_TEMP CO
JOIN PIZZA_NAMES PN ON CO.PIZZA_ID = PN.PIZZA_ID
JOIN #RUNNER_ORDERS_TEMP RO ON CO.ORDER_ID = RO.ORDER_ID
WHERE CANCELLATION IS NULL
```

| TOTAL_SALES |
| ------------|
| 138         |

### 2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra

```sql
WITH DELIVERED AS(
	SELECT DISTINCT CO.RECORD_ID, CO.PIZZA_ID
	FROM #CUSTOMER_ORDERS_TEMP CO
	JOIN #RUNNER_ORDERS_TEMP RO ON CO.ORDER_ID = RO.ORDER_ID
	WHERE CANCELLATION IS NULL),
BASE_PRICE AS(
	SELECT D.RECORD_ID,
		   CASE
				WHEN PIZZA_NAME = 'Meatlovers' THEN 12
				ELSE 10
		   END AS PRICE				
	FROM DELIVERED D
	JOIN PIZZA_NAMES PN ON D.PIZZA_ID = PN.PIZZA_ID),
EXTRA_CHANGE AS(
	SELECT D.RECORD_ID,
		   SUM(
		   CASE
				WHEN TOPPING_NAME IS NULL THEN 0
				ELSE 1
		   END) AS EXTRA_FEE
	FROM DELIVERED D
	LEFT JOIN #EXTRAS_SPLIT EX ON D.RECORD_ID = EX. RECORD_ID
	LEFT JOIN PIZZA_TOPPINGS PT ON EX.EXTRA_ID = PT.TOPPING_ID
	GROUP BY D.RECORD_ID)
SELECT SUM(B.PRICE + ISNULL(EC.EXTRA_FEE, 0)) AS TOTAL_SALES_UPDATE
FROM BASE_PRICE B
LEFT JOIN EXTRA_CHANGE EC ON B.RECORD_ID = EC.RECORD_ID
GO
```

| TOTAL_SALES_UPDATE |
| -------------------|
| 142                |

### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

```sql
DROP TABLE IF EXISTS RATING

CREATE TABLE RATING 
(
	RATING_ID INT IDENTITY(1, 1),
	ORDER_ID INT NOT NULL,
	RUNNER_ID INT NOT NULL,
	CUSTOMER_ID INT NOT NULL,
	RATING TINYINT CHECK (RATING BETWEEN 1 AND 5),
    COMMENTS VARCHAR(255) NULL
)

INSERT INTO RATING (ORDER_ID, RUNNER_ID, CUSTOMER_ID, RATING, COMMENTS)
VALUES (1, 1, 101, 5, 'Fast delivery!')
INSERT INTO RATING VALUES (2, 1, 101, 4, 'On time, good service.')
INSERT INTO RATING VALUES (3, 1, 102, 5, 'Very quick, thanks.')
INSERT INTO RATING VALUES (4, 2, 103, 3, 'A bit late, but okay.')
INSERT INTO RATING VALUES (5, 3, 104, 4, 'Perfect timing.')
INSERT INTO RATING VALUES (7, 2, 105, 5, 'Friendly runner.')
INSERT INTO RATING VALUES (8, 2, 102, 4, 'Super fast!')
INSERT INTO RATING VALUES (10, 1, 104, 5, 'Excellent service.')

SELECT * FROM RATING
```

| RATING_ID | ORDER_ID | RUNNER_ID | CUSTOMER_ID | RATING | COMMENTS              |
|-----------|----------|-----------|-------------|--------|-----------------------|
| 1         | 1        | 1         | 101         | 5      | Fast delivery!        |
| 2         | 2        | 1         | 101         | 4      | On time, good service.|
| 3         | 3        | 1         | 102         | 5      | Very quick, thanks.   |
| 4         | 4        | 2         | 103         | 3      | A bit late, but okay. |
| 5         | 5        | 3         | 104         | 4      | Perfect timing.       |
| 6         | 7        | 2         | 105         | 5      | Friendly runner.      |
| 7         | 8        | 2         | 102         | 4      | Super fast!           |
| 8         | 10       | 1         | 104         | 5      | Excellent service.    |

### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas

```sql
SELECT R.CUSTOMER_ID, R.ORDER_ID,
	   R.RUNNER_ID, R.RATING, 
	   CO.ORDER_DATE, RO.PICKUP_TIME,
	   DATEDIFF(MINUTE, ORDER_DATE, PICKUP_TIME) AS TIME_BETWEEN_ORDER_PICKUP,
	   RO.DURATION,
	   ROUND(DISTANCE * 60 / DURATION, 2) AS AVG_SPEED,
	   COUNT(CO.PIZZA_ID) AS TOTAL_PIZZAS
FROM RATING R
JOIN #CUSTOMER_ORDERS_TEMP CO ON R.ORDER_ID = CO.ORDER_ID
JOIN #RUNNER_ORDERS_TEMP RO ON RO.ORDER_ID = R.ORDER_ID
GROUP BY R.CUSTOMER_ID, R.ORDER_ID,
		 R.RUNNER_ID, R.RATING, 
	     CO.ORDER_DATE, RO.PICKUP_TIME,
		 RO.DURATION, RO.DISTANCE
ORDER BY R.ORDER_ID
```

| CUSTOMER_ID | ORDER_ID | RUNNER_ID | RATING | ORDER_DATE           | PICKUP_TIME          | TIME_BETWEEN_ORDER_PICKUP | DURATION | AVG_SPEED | TOTAL_PIZZAS |
|-------------|----------|-----------|--------|----------------------|----------------------|---------------------------|----------|-----------|--------------|
| 101         | 1        | 1         | 5      | 2020-01-01 18:05:02  | 2020-01-01 18:15:34  | 10                        | 32       | 37.5      | 1            |
| 101         | 2        | 1         | 4      | 2020-01-01 19:00:52  | 2020-01-01 19:10:54  | 10                        | 27       | 44.44     | 1            |
| 102         | 3        | 1         | 5      | 2020-01-02 23:51:23  | 2020-01-03 00:12:37  | 21                        | 20       | 40.2      | 2            |
| 103         | 4        | 2         | 3      | 2020-01-04 13:23:46  | 2020-01-04 13:53:03  | 30                        | 40       | 35.1      | 3            |
| 104         | 5        | 3         | 4      | 2020-01-08 21:00:29  | 2020-01-08 21:10:57  | 10                        | 15       | 40        | 1            |
| 105         | 7        | 2         | 5      | 2020-01-08 21:20:29  | 2020-01-08 21:30:45  | 10                        | 25       | 60        | 1            |
| 102         | 8        | 2         | 4      | 2020-01-09 23:54:33  | 2020-01-10 00:15:02  | 21                        | 15       | 93.6      | 1            |
| 104         | 10       | 1         | 5      | 2020-01-11 18:34:49  | 2020-01-11 18:50:20  | 16                        | 10       | 60        | 2            |

### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

```sql
WITH DELIVERED AS(
	SELECT CO.RECORD_ID, CO.PIZZA_ID
	FROM #CUSTOMER_ORDERS_TEMP CO
	JOIN #RUNNER_ORDERS_TEMP RO ON CO.ORDER_ID = RO.ORDER_ID
	WHERE CANCELLATION IS NULL),
REVENUE AS(
	SELECT SUM(
			CASE
				WHEN PIZZA_NAME = 'Meatlovers' THEN 12
				ELSE 10
			END) AS TOTAL_REVENUE				
	FROM DELIVERED D
	JOIN PIZZA_NAMES PN ON D.PIZZA_ID = PN.PIZZA_ID),
KM AS(
	SELECT SUM(RO.DISTANCE) AS TOTAL_KM
	FROM #RUNNER_ORDERS_TEMP RO
	WHERE CANCELLATION IS NULL)
SELECT TOTAL_REVENUE, ROUND(TOTAL_KM * 0.3, 2) AS RUNNER_COST, 
	   TOTAL_REVENUE - ROUND(TOTAL_KM * 0.3, 2) AS LEFT_OVER
FROM REVENUE
CROSS JOIN KM
```

| TOTAL_REVENUE | RUNNER_COST | LEFT_OVER |
|---------------|-------------|-----------|
| 138	          | 43,56	      | 94,44     |
