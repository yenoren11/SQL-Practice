# 🍕 Case Study #2 - Pizza Runner

## B. Runner and Customer Experience

Use temporary tables 'CUSTOMER_ORDERS_TEMP' and 'RUNNER_ORDERS_TEMP' created in part A.

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```sql
SELECT DATEDIFF(DAY, '2021-01-01', REGISTRATION_DATE)/7 + 1 AS SIGNUP_WEEK,
	   COUNT(DISTINCT RUNNER_ID) AS COUNT_RUNNERS
FROM RUNNERS
GROUP BY DATEDIFF(DAY, '2021-01-01', REGISTRATION_DATE)/7 + 1
ORDER BY SIGNUP_WEEK
```

| SIGNUP_WEEK | COUNT_RUNNERS |
|-------------|---------------|
| 1           | 2             |
| 2           | 1             |
| 3           | 1             |

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```sql
SELECT RUNNER_ID, ROUND(AVG(DATEDIFF(MINUTE, ORDER_DATE, PICKUP_TIME)), 0) AS AVG_TIME
FROM #RUNNER_ORDERS_TEMP RO
JOIN #CUSTOMER_ORDERS_TEMP CO ON RO.ORDER_ID = CO.ORDER_ID
WHERE CANCELLATION IS NULL
GROUP BY RUNNER_ID
```

| RUNNER_ID | AVG_TIME |
|-----------|----------|
| 1         | 15       |
| 2         | 24       |
| 3         | 10       |

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
SELECT CO.ORDER_ID, 
       COUNT(PIZZA_ID) AS NUMBER_OF_PIZZAS,
       DATEDIFF(MINUTE, ORDER_DATE, PICKUP_TIME) AS TIME_PREPARE
FROM #RUNNER_ORDERS_TEMP RO
JOIN #CUSTOMER_ORDERS_TEMP CO ON RO.ORDER_ID = CO.ORDER_ID
WHERE CANCELLATION IS NULL
GROUP BY CO.ORDER_ID, ORDER_DATE, PICKUP_TIME
ORDER BY COUNT(PIZZA_ID)
```

| ORDER_ID | NUMBER_OF_PIZZAS | TIME_PREPARE |
|----------|------------------|--------------|
| 1        | 1                | 10           |
| 2        | 1                | 10           |
| 5        | 1                | 10           |
| 7        | 1                | 10           |
| 8        | 1                | 21           |
| 10       | 2                | 16           |
| 3        | 2                | 21           |
| 4        | 3                | 30           |

```sql
SELECT NUMBER_OF_PIZZAS,
       ROUND(AVG(TIME_PREPARE), 0) AS AVG_TIME_PREPARE
FROM (SELECT CO.ORDER_ID, 
      COUNT(PIZZA_ID) AS NUMBER_OF_PIZZAS,
      DATEDIFF(MINUTE, ORDER_DATE, PICKUP_TIME) AS TIME_PREPARE
      FROM #RUNNER_ORDERS_TEMP RO
      JOIN #CUSTOMER_ORDERS_TEMP CO ON RO.ORDER_ID = CO.ORDER_ID
      WHERE CANCELLATION IS NULL
      GROUP BY CO.ORDER_ID, ORDER_DATE, PICKUP_TIME) AS T
GROUP BY NUMBER_OF_PIZZAS
ORDER BY NUMBER_OF_PIZZAS
```

| NUMBER_OF_PIZZAS | AVG_TIME_PREPARE |
|------------------|------------------|
| 1                | 12               |
| 2                | 18               |
| 3                | 30               |

> **Conclusion:**
- Orders with 1 pizza usually take 10 minutes, with one exception at 21 minutes.

- Orders with 2 pizzas take between 16–21 minutes.

- The order with 3 pizzas takes 30 minutes.

👉 Prep time increases with pizza quantity.

### 4. What was the average distance travelled for each customer?

```sql
SELECT CUSTOMER_ID, ROUND(AVG(DISTANCE), 2) AS AVG_DISTANCE
FROM #CUSTOMER_ORDERS_TEMP CO
JOIN #RUNNER_ORDERS_TEMP RO ON CO.ORDER_ID = RO.ORDER_ID
WHERE CANCELLATION IS NULL
GROUP BY CUSTOMER_ID
```

| CUSTOMER_ID | AVG_DISTANCE |
|-------------|--------------|
| 101         | 20           |
| 102         | 16.73        |
| 103         | 23.4         |
| 104         | 10           |
| 105         | 25           |

### 5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT MAX(DURATION) - MIN(DURATION) AS DELIVERY_TIME_DIFF
FROM #RUNNER_ORDERS_TEMP
```

|  DELIVERY_TIME_DIFF |
|---------------------|
| 30                  |

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```sql
SELECT RUNNER_ID, ORDER_ID, DISTANCE, ROUND(DISTANCE * 60 / DURATION, 2) AS AVG_SPEED
FROM #RUNNER_ORDERS_TEMP RO 
WHERE CANCELLATION IS NULL
ORDER BY RUNNER_ID
```

| RUNNER_ID | ORDER_ID | DISTANCE | AVG_SPEED |
|-----------|----------|----------|-----------|
| 1         | 1        | 20       | 37.5      |
| 1         | 2        | 20       | 44.44     |
| 1         | 3        | 13.4     | 40.2      |
| 1         | 10       | 10       | 60        |
| 2         | 7        | 25       | 60        |
| 2         | 8        | 23.4     | 93.6      |
| 2         | 4        | 23.4     | 35.1      |
| 3         | 5        | 10       | 40        |

### 7. What is the successful delivery percentage for each runner?

```sql
SELECT RUNNER_ID, ROUND(COUNT(DISTANCE) * 100 / COUNT(ORDER_ID), 2) AS SUCCESS_PERCENTAGE
FROM #RUNNER_ORDERS_TEMP
GROUP BY RUNNER_ID
```

| RUNNER_ID | SUCCESS_PERCENTAGE |
|-----------|--------------------|
| 1         | 100                |
| 2         | 75                 |
| 3         | 50                 |

