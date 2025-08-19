# 🍕 Case Study #2 - Pizza Runner

## 🔹 Step 1: Data Cleaning

### 1. Create temporary table 'CUSTOMER_ORDERS_TEMP' after cleaning data of table 'CUSTOMER_ORDERS'

```sql
DROP TABLE IF EXISTS #CUSTOMER_ORDERS_TEMP

SELECT ORDER_ID, CUSTOMER_ID, PIZZA_ID,
	 (CASE
			WHEN EXCLUSIONS IN ('null', 'NaN', '') THEN NULL
			ELSE EXCLUSIONS 
	  END) AS EXCLUSIONS,
	 (CASE
			WHEN EXTRAS IN ('null', 'NaN', '') THEN NULL
			ELSE EXTRAS
	  END) AS EXTRAS, ORDER_DATE
INTO #CUSTOMER_ORDERS_TEMP
FROM CUSTOMER_ORDERS

SELECT * FROM #CUSTOMER_ORDERS_TEMP
```

| ORDER_ID | CUSTOMER_ID | PIZZA_ID | EXCLUSIONS | EXTRAS | ORDER_DATE              |
|----------|-------------|----------|------------|--------|-------------------------|
| 1        | 101         | 1        | NULL       | NULL   | 2020-01-01 18:05:02.000 |
| 2        | 101         | 1        | NULL       | NULL   | 2020-01-01 19:00:52.000 |
| 3        | 102         | 1        | NULL       | NULL   | 2020-01-02 23:51:23.000 |
| 3        | 102         | 2        | NULL       | NULL   | 2020-01-02 23:51:23.000 |
| 4        | 103         | 1        | 4          | NULL   | 2020-01-04 13:23:46.000 |
| 4        | 103         | 1        | 4          | NULL   | 2020-01-04 13:23:46.000 |
| 4        | 103         | 2        | 4          | NULL   | 2020-01-04 13:23:46.000 |
| 5        | 104         | 1        | NULL       | 1      | 2020-01-08 21:00:29.000 |
| 6        | 101         | 2        | NULL       | NULL   | 2020-01-08 21:20:29.000 |
| 7        | 105         | 2        | NULL       | 1      | 2020-01-08 21:20:29.000 |
| 8        | 102         | 1        | NULL       | NULL   | 2020-01-09 23:54:33.000 |
| 9        | 103         | 1        | 4          | 1, 5   | 2020-01-10 11:22:59.000 |
| 10       | 104         | 1        | NULL       | NULL   | 2020-01-11 18:34:49.000 |
| 10       | 104         | 2, 6     | 1, 4       | NULL   | 2020-01-11 18:34:49.000 |

### 2. Create temporary table 'RUNNER_ORDERS_TEMP' after cleaning data of table 'RUNNER_ORDERS'

```sql
DROP TABLE IF EXISTS #RUNNER_ORDERS_TEMP

SELECT ORDER_ID, RUNNER_ID,
	 (CASE
			WHEN PICKUP_TIME = 'null' THEN NULL
			ELSE PICKUP_TIME 
	  END) AS PICKUP_TIME,
	 TRY_CAST(CASE
			WHEN DISTANCE = 'null' THEN NULL
			WHEN DISTANCE LIKE '%km' THEN REPLACE(LTRIM(RTRIM(DISTANCE)), 'km', '')
			ELSE DISTANCE
	  END AS FLOAT) AS DISTANCE,
	  TRY_CAST(CASE
			WHEN DURATION = 'null' THEN NULL
			WHEN DURATION LIKE '%minutes' THEN REPLACE(LTRIM(RTRIM(DURATION)), 'minutes', '')
			WHEN DURATION LIKE '%minute' THEN REPLACE(LTRIM(RTRIM(DURATION)), 'minute', '')
			WHEN DURATION LIKE '%mins' THEN REPLACE(LTRIM(RTRIM(DURATION)), 'mins', '')
			ELSE DURATION
	  END AS FLOAT) AS DURATION,
	  (CASE
			WHEN CANCELLATION IN ('null', 'NaN', '') THEN NULL
			ELSE CANCELLATION
	  END) AS CANCELLATION
INTO #RUNNER_ORDERS_TEMP
FROM RUNNER_ORDERS

SELECT * FROM #RUNNER_ORDERS_TEMP
```

| ORDER_ID | RUNNER_ID | PICKUP_TIME          | DISTANCE | DURATION | CANCELLATION             |
|----------|-----------|----------------------|----------|----------|--------------------------|
| 1        | 1         | 2020-01-01 18:15:34  | 20       | 32       | NULL                     |
| 2        | 1         | 2020-01-01 19:10:54  | 20       | 27       | NULL                     |
| 3        | 1         | 2020-01-03 00:12:37  | 13.4     | 20       | NULL                     |
| 4        | 2         | 2020-01-04 13:53:03  | 23.4     | 40       | NULL                     |
| 5        | 3         | 2020-01-08 21:10:57  | 10       | 15       | NULL                     |
| 6        | 3         | NULL                 | NULL     | NULL     | Restaurant Cancellation  |
| 7        | 2         | 2020-01-08 21:30:45  | 25       | 25       | NULL                     |
| 8        | 2         | 2020-01-10 00:15:02  | 23.4     | 15       | NULL                     |
| 9        | 2         | NULL                 | NULL     | NULL     | Customer Cancellation    |
| 10       | 1         | 2020-01-11 18:50:20  | 10       | 10       | NULL                     |

## 🔹 Step 2: Answer questions

### 1. How many pizzas were ordered?

```sql
SELECT COUNT(*) AS COUNT_PIZZAS_ORDERED
FROM #CUSTOMER_ORDERS_TEMP
```

| COUNT_PIZZAS_ORDERED |
|----------------------|
| 14                   |

### 2. How many unique customer orders were made?

```sql
SELECT COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS
FROM CUSTOMER_ORDERS
```

| TOTAL_ORDERS |
|--------------|
| 10           |

### 3. How many successful orders were delivered by each runner?

```sql
SELECT RUNNER_ID, COUNT(ORDER_ID) AS TOTAL_SUCCESSFUL_ORDERS
FROM #RUNNER_ORDERS_TEMP
WHERE CANCELLATION IS NULL
GROUP BY RUNNER_ID
```

| RUNNER_ID | TOTAL_SUCCESSFUL_ORDERS |
|-----------|-------------------------|
| 1         | 4                       |
| 2         | 3                       |
| 3         | 1                       |

### 4. How many of each type of pizza was delivered?

```sql
SELECT CO.PIZZA_ID, PIZZA_NAME ,COUNT(CO.ORDER_ID) AS TOTAL_PIZZA_DELIVERED
FROM #CUSTOMER_ORDERS_TEMP CO
JOIN #RUNNER_ORDERS_TEMP RO ON CO.ORDER_ID = RO.ORDER_ID
JOIN PIZZA_NAMES PN ON PN.PIZZA_ID = CO.PIZZA_ID
WHERE CANCELLATION IS NULL
GROUP BY CO.PIZZA_ID, PIZZA_NAME
```

| PIZZA_ID | PIZZA_NAME | TOTAL_PIZZA_DELIVERED |
|----------|------------|-----------------------|
| 1        | Meatlovers | 9                     |
| 2        | Vegetarian | 3                     |

### 5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT CUSTOMER_ID,
	   SUM(CASE
				WHEN PIZZA_ID = 1 THEN 1
				ELSE 0
		   END) AS Meatlovers,
	   SUM(CASE
				WHEN PIZZA_ID = 2 THEN 1
				ELSE 0
		   END) AS Vegetarian
FROM #CUSTOMER_ORDERS_TEMP
GROUP BY CUSTOMER_ID
```

| CUSTOMER_ID | Meatlovers | Vegetarian |
|-------------|------------|------------|
| 101         | 2          | 1          |
| 102         | 2          | 1          |
| 103         | 3          | 1          |
| 104         | 3          | 0          |
| 105         | 0          | 1          |

### 6. What was the maximum number of pizzas delivered in a single order?

```sql
SELECT TOP 1 CO.ORDER_ID, COUNT(CO.PIZZA_ID) AS TOTAL_PIZZAS
FROM #CUSTOMER_ORDERS_TEMP CO
JOIN #RUNNER_ORDERS_TEMP RO ON CO.ORDER_ID = RO.ORDER_ID
WHERE CANCELLATION IS NULL
GROUP BY CO.ORDER_ID
ORDER BY TOTAL_PIZZAS DESC
```

| ORDER_ID | TOTAL_PIZZAS |
|----------|--------------|
| 4        | 3            |

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```sql
SELECT CO.CUSTOMER_ID,
	   SUM(CASE
				WHEN EXCLUSIONS IS NULL AND EXTRAS IS NULL THEN 1
				ELSE 0
			 END) AS TOTAL_PIZZA_NO_CHANGES,
	   SUM(CASE
				WHEN EXCLUSIONS IS NOT NULL OR EXTRAS IS NOT NULL THEN 1
				ELSE 0
			 END) AS TOTAL_PIZZA_CHANGES
FROM #CUSTOMER_ORDERS_TEMP CO
JOIN #RUNNER_ORDERS_TEMP RO ON CO.ORDER_ID = RO.ORDER_ID
WHERE CANCELLATION IS NULL
GROUP BY CO.CUSTOMER_ID
```

| CUSTOMER_ID | TOTAL_PIZZA_NO_CHANGES | TOTAL_PIZZA_CHANGES |
|-------------|------------------------|---------------------|
| 101         | 2                      | 0                   |
| 102         | 3                      | 0                   |
| 103         | 0                      | 3                   |
| 104         | 1                      | 2     			     |
| 105         | 0          			   | 1     			     |

### 8. How many pizzas were delivered that had both exclusions and extras?

```sql
SELECT SUM(CASE
				WHEN EXCLUSIONS IS NOT NULL AND EXTRAS IS NOT NULL THEN 1
				ELSE 0
		   END) AS TOTAL_CHANGE_BOTH
FROM #CUSTOMER_ORDERS_TEMP CO
JOIN #RUNNER_ORDERS_TEMP RO ON CO.ORDER_ID = RO.ORDER_ID
WHERE CANCELLATION IS NULL
```

| TOTAL_CHANGE_BOTH |
|-------------------|
| 1                 |

### 9. What was the total volume of pizzas ordered for each hour of the day?

```sql
SELECT DATEPART(HOUR, ORDER_DATE) AS HOUR_OF_DAY,
	   COUNT(PIZZA_ID) AS PIZZA_VOLUME
FROM #CUSTOMER_ORDERS_TEMP
GROUP BY DATEPART(HOUR, ORDER_DATE)
ORDER BY HOUR_OF_DAY
```

| HOUR_OF_DAY | PIZZA_VOLUME |
|-------------|--------------|
| 11          | 1            |
| 13          | 3            |
| 18          | 3            |
| 19          | 1            |
| 21          | 3            |
| 23          | 3            |

### 10. What was the volume of orders for each day of the week?

```sql
SELECT DATENAME(WEEKDAY, ORDER_DATE) AS DAY_OF_WEEK,
	   COUNT(DISTINCT ORDER_ID) AS ORDER_VOLUME
FROM #CUSTOMER_ORDERS_TEMP
GROUP BY DATENAME(WEEKDAY, ORDER_DATE)
ORDER BY DAY_OF_WEEK
```

| DAY_OF_WEEK | ORDER_VOLUME |
|-------------|--------------|
| Friday      | 1            |
| Saturday    | 2            |
| Thursday    | 2            |
| Wednesday   | 5            |
