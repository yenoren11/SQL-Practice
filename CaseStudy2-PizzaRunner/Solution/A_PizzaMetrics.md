# 🍕 Case Study #2 - Pizza Runner

## Step 1: Data Cleaning

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

## Step 2: Answer questions

