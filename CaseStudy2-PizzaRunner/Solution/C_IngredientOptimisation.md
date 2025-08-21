# 🍕 Case Study #2 - Pizza Runner

## C. Ingredient Optimisation

Use temporary tables 'CUSTOMER_ORDERS_TEMP' and 'RUNNER_ORDERS_TEMP' created in part A.

## 🔹 Step 1: Data cleaning

### 1. Create temporary table 'PIZZA_RECIPES_TEMP'

```sql
DROP TABLE IF EXISTS #PIZZA_RECIPES_TEMP

SELECT PIZZA_ID,
	   CAST(VALUE AS INT) AS TOPPING_ID
INTO #PIZZA_RECIPES_TEMP
FROM PIZZA_RECIPES PR
CROSS APPLY STRING_SPLIT(PR.TOPPINGS, ',')

SELECT * FROM #PIZZA_RECIPES_TEMP
```

| PIZZA_ID | TOPPING_ID |
|----------|------------|
| 1        | 1          |
| 1        | 2          |
| 1        | 3          |
| 1        | 4          |
| 1        | 5          |
| 1        | 6          |
| 1        | 8          |
| 1        | 10         |
| 2        | 4          |
| 2        | 6          |
| 2        | 7          |
| 2        | 9          |
| 2        | 11         |
| 2        | 12         |

### 2. Create temporary table 'TOPPING_SPLIT'

```sql
DROP TABLE IF EXISTS #TOPPING_SPLIT

SELECT PIZZA_ID, PT.TOPPING_ID, TOPPING_NAME
INTO #TOPPING_SPLIT
FROM #PIZZA_RECIPES_TEMP PR
JOIN PIZZA_TOPPINGS PT ON PR.TOPPING_ID = PT.TOPPING_ID

SELECT * FROM #TOPPING_SPLIT
```

| PIZZA_ID | TOPPING_ID | TOPPING_NAME  |
|----------|------------|---------------|
| 1        | 1          | Bacon         |
| 1        | 2          | BBQ Sauce     |
| 1        | 3          | Beef          |
| 1        | 4          | Cheese        |
| 2        | 4          | Cheese        |
| 1        | 5          | Chicken       |
| 1        | 6          | Mushrooms     |
| 2        | 6          | Mushrooms     |
| 2        | 7          | Onions        |
| 1        | 8          | Pepperoni     |
| 2        | 9          | Peppers       |
| 1        | 10         | Salami        |
| 2        | 11         | Tomatoes      |
| 2        | 12         | Tomato Sauce  |

### 3. Add an identity column named RECORD_ID to the 'CUSTOMER_ORDERS_TEMP' table to uniquely identify and select each individual pizza order more easily.

```sql
ALTER TABLE #CUSTOMER_ORDERS_TEMP
ADD RECORD_ID INT IDENTITY(1,1) PRIMARY KEY
```

### 4. Create two new temporary tables, 'EXTRAS_SPLIT' and 'EXCLUSIONS_SPLIT', to break down the toppings into separate rows.

```sql
DROP TABLE IF EXISTS #EXTRAS_SPLIT

SELECT RECORD_ID, LTRIM(RTRIM(VALUE)) AS EXTRA_ID
INTO #EXTRAS_SPLIT
FROM #CUSTOMER_ORDERS_TEMP
CROSS APPLY STRING_SPLIT(EXTRAS, ',')

SELECT * FROM #EXTRAS_SPLIT
```

| RECORD_ID | EXTRA_ID |
|-----------|----------|
| 8         | 1        |
| 10        | 1        |
| 12        | 1        |
| 12        | 5        |
| 14        | 1        |
| 14        | 4        |

```sql
DROP TABLE IF EXISTS #EXCLUSIONS_SPLIT

SELECT RECORD_ID, LTRIM(RTRIM(VALUE)) AS EXCLUSION_ID
INTO #EXCLUSIONS_SPLIT
FROM #CUSTOMER_ORDERS_TEMP
CROSS APPLY STRING_SPLIT(EXCLUSIONS, ',')

SELECT * FROM #EXCLUSIONS_SPLIT
```

| RECORD_ID | EXCLUSION_ID |
|-----------|--------------|
| 5         | 4            |
| 6         | 4            |
| 7         | 4            |
| 12        | 4            |
| 14        | 2            |
| 14        | 6            |

## 🔹 Step 2: Answer questions

### 1. What are the standard ingredients for each pizza?

```sql
SELECT PN.PIZZA_ID, PN.PIZZA_NAME,
	   STRING_AGG(PT.TOPPING_NAME, ', ') AS INGREDIENTS
FROM PIZZA_NAMES PN
JOIN #TOPPING_SPLIT TS ON TS.PIZZA_ID = PN.PIZZA_ID
JOIN PIZZA_TOPPINGS PT ON PT.TOPPING_ID = TS.TOPPING_ID
GROUP BY PN.PIZZA_ID, PN.PIZZA_NAME
```

| PIZZA_ID | PIZZA_NAME  | INGREDIENTS                                                                 |
|----------|-------------|-----------------------------------------------------------------------------|
| 1        | Meatlovers  | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami       |
| 2        | Vegetarian  | Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                  |

### 2. What was the most commonly added extra?

```sql
SELECT TOP 1 EXTRA_ID, TOPPING_NAME, COUNT(EXTRA_ID) AS MOST_EXTRA
FROM #EXTRAS_SPLIT ES
JOIN PIZZA_TOPPINGS PT ON ES.EXTRA_ID = PT.TOPPING_ID
GROUP BY EXTRA_ID, TOPPING_NAME
ORDER BY MOST_EXTRA DESC
```

| EXTRA_ID | TOPPING_NAME | MOST_EXTRA |
|----------|--------------|------------|
| 1        | Bacon        | 4          |

### 3. What was the most common exclusion?

```sql
SELECT TOP 1 EXCLUSION_ID, TOPPING_NAME, COUNT(EXCLUSION_ID) AS MOST_EXCLUSION
FROM #EXCLUSIONS_SPLIT ES
JOIN PIZZA_TOPPINGS PT ON ES.EXCLUSION_ID = PT.TOPPING_ID
GROUP BY EXCLUSION_ID, TOPPING_NAME
ORDER BY MOST_EXCLUSION DESC
```

| EXCLUSION_ID | TOPPING_NAME | MOST_EXCLUSION |
|--------------|--------------|----------------|
| 4            | Cheese       | 4              |

### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

```sql
SELECT CO.RECORD_ID, CO.ORDER_ID, CO.CUSTOMER_ID, 
	   CO.PIZZA_ID, CO.EXCLUSIONS, CO.EXTRAS, 
	   CO.ORDER_DATE, PN.PIZZA_NAME
	   + CASE
			WHEN EXCLUSIONS IS NOT NULL THEN ' - Exclude ' + EXCLUSIONS_LIST
			ELSE ''
	     END
	   + CASE
			WHEN EXTRAS IS NOT NULL THEN ' - Extra ' + EXTRAS_LIST
			ELSE ''
	     END AS ORDER_ITEM
FROM #CUSTOMER_ORDERS_TEMP CO
JOIN PIZZA_NAMES PN ON CO.PIZZA_ID = PN.PIZZA_ID
LEFT JOIN (SELECT ES.RECORD_ID,
				  STRING_AGG(PT.TOPPING_NAME, ', ') AS EXCLUSIONS_LIST
		   FROM #EXCLUSIONS_SPLIT ES
		   JOIN PIZZA_TOPPINGS PT ON PT.TOPPING_ID = ES.EXCLUSION_ID
		   GROUP BY ES.RECORD_ID) E ON CO.RECORD_ID = E.RECORD_ID
LEFT JOIN (SELECT ES.RECORD_ID,
				  STRING_AGG(PT.TOPPING_NAME, ', ') AS EXTRAS_LIST
		   FROM #EXTRAS_SPLIT ES
		   JOIN PIZZA_TOPPINGS PT ON PT.TOPPING_ID = ES.EXTRA_ID
		   GROUP BY ES.RECORD_ID) ET ON CO.RECORD_ID = ET.RECORD_ID
ORDER BY CO.RECORD_ID
```

| RECORD_ID | ORDER_ID | CUSTOMER_ID | PIZZA_ID | EXCLUSIONS | EXTRAS |        ORDER_DATE       |                          ORDER_ITEM                            |
|-----------|----------|-------------|----------|------------|--------|-------------------------|----------------------------------------------------------------|
| 1         | 1		   | 101		 | 1		| NULL		 | NULL	  | 2020-01-01 18:05:02.000	| Meatlovers                                                     |
| 2			| 2  	   | 101		 | 1 		| NULL		 | NULL	  | 2020-01-01 19:00:52.000	| Meatlovers                                                     |
| 3         | 3		   | 102		 | 1		| NULL		 | NULL	  | 2020-01-02 23:51:23.000	| Meatlovers                                                     |
| 4			| 3  	   | 102		 | 2 		| NULL		 | NULL	  | 2020-01-02 23:51:23.000	| Vegetarian                                                     |
| 5         | 4		   | 103		 | 1		| 4  		 | NULL	  | 2020-01-04 13:23:46.000	| Meatlovers - Exclude Cheese                                    |
| 6			| 4  	   | 103		 | 1 		| 4 		 | NULL	  | 2020-01-04 13:23:46.000	| Meatlovers - Exclude Cheese                                    |
| 7         | 4		   | 103		 | 2		| 4 		 | NULL	  | 2020-01-04 13:23:46.000	| Vegetarian - Exclude Cheese                                    |
| 8			| 5  	   | 104		 | 1 		| NULL		 | 1	  | 2020-01-08 21:00:29.000	| Meatlovers - Extra Bacon                                       |
| 9         | 6		   | 101		 | 2		| NULL		 | NULL	  | 2020-01-08 21:03:13.000	| Vegetarian                                                     |
| 10		| 7  	   | 105		 | 2 		| NULL		 | 1	  | 2020-01-08 21:20:29.000	| Vegetarian - Extra Bacon                                       |
| 11        | 8		   | 102		 | 1		| NULL		 | NULL	  | 2020-01-09 23:54:33.000	| Meatlovers                                                     |
| 12		| 9  	   | 103		 | 1 		| 4 		 | 1, 5	  | 2020-01-10 11:22:59.000	| Meatlovers - Exclude Cheese - Extra Bacon, Chicken             |
| 13		| 10  	   | 104		 | 1 		| NULL		 | NULL	  | 2020-01-11 18:34:49.000	| Meatlovers                                                     |
| 14		| 10 	   | 104		 | 1 		| 2, 6		 | 1, 4	  | 2020-01-11 18:34:49.000 | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese|

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients

For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

```sql
WITH STANDARDTOPPINGS AS (
    SELECT CO.RECORD_ID, t.TOPPING_NAME
    FROM #CUSTOMER_ORDERS_TEMP CO
    JOIN #TOPPING_SPLIT TS 
         ON CO.PIZZA_ID = TS.PIZZA_ID
    JOIN PIZZA_TOPPINGS t 
         ON ts.TOPPING_ID = t.TOPPING_ID
),
EXCLUSIONS AS (
    SELECT E.RECORD_ID, PT.TOPPING_NAME
    FROM #EXCLUSIONS_SPLIT E
    JOIN PIZZA_TOPPINGS PT
         ON E.EXCLUSION_ID = PT.TOPPING_ID
),
EXTRAS AS (
    SELECT E.RECORD_ID, PT.TOPPING_NAME
    FROM #EXTRAS_SPLIT E
    JOIN PIZZA_TOPPINGS PT 
         ON E.EXTRA_ID = PT.TOPPING_ID
),
FINALTOPPINGS AS (
    -- Take the standard topping minus the exclusions
    SELECT S.RECORD_ID, S.TOPPING_NAME
    FROM STANDARDTOPPINGS S
    LEFT JOIN EXCLUSIONS EX
           ON S.RECORD_ID = EX.RECORD_ID 
          AND S.TOPPING_NAME = EX.TOPPING_NAME
    WHERE EX.TOPPING_NAME IS NULL

    UNION ALL

    -- Add extras
    SELECT RECORD_ID, TOPPING_NAME
    FROM EXTRAS
),
TOPPINGCOUNT AS (
    SELECT 
        RECORD_ID,
        TOPPING_NAME,
        COUNT(*) AS CNT
    FROM FINALTOPPINGS
    GROUP BY RECORD_ID, TOPPING_NAME
)
SELECT 
    CO.RECORD_ID, CO.ORDER_ID, CO.CUSTOMER_ID, 
	CO.PIZZA_ID, CO.EXCLUSIONS, CO.EXTRAS, CO.ORDER_DATE,
    PN.PIZZA_NAME + ': ' +
    STRING_AGG(
        CASE WHEN TC.CNT = 2 
             THEN '2x' + TC.TOPPING_NAME 
             ELSE TC.TOPPING_NAME END,
        ', '
    ) WITHIN GROUP (ORDER BY TC.TOPPING_NAME) AS INGREDIENT_LIST
FROM TOPPINGCOUNT TC
JOIN #CUSTOMER_ORDERS_TEMP CO
     ON TC.RECORD_ID = CO.RECORD_ID
JOIN PIZZA_NAMES PN
     ON CO.PIZZA_ID = PN.PIZZA_ID
GROUP BY CO.RECORD_ID, CO.ORDER_ID, CO.CUSTOMER_ID, CO.PIZZA_ID, CO.EXCLUSIONS, CO.EXTRAS, CO.ORDER_DATE, PN.PIZZA_NAME
ORDER BY CO.RECORD_ID
```

| RECORD_ID | ORDER_ID | CUSTOMER_ID | PIZZA_ID | EXCLUSIONS | EXTRAS |        ORDER_DATE       |                         INGREDIENT_LIST                        |
|-----------|----------|-------------|----------|------------|--------|-------------------------|----------------------------------------------------------------|
| 1         | 1		   | 101		 | 1		| NULL		 | NULL	  | 2020-01-01 18:05:02.000	| Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami|
| 2			| 2  	   | 101		 | 1 		| NULL		 | NULL	  | 2020-01-01 19:00:52.000	| Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami|
| 3         | 3		   | 102		 | 1		| NULL		 | NULL	  | 2020-01-02 23:51:23.000	| Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami|
| 4			| 3  	   | 102		 | 2 		| NULL		 | NULL	  | 2020-01-02 23:51:23.000	| Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes|
| 5         | 4		   | 103		 | 1		| 4  		 | NULL	  | 2020-01-04 13:23:46.000	| Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami|
| 6			| 4  	   | 103		 | 1 		| 4 		 | NULL	  | 2020-01-04 13:23:46.000	| Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami|
| 7         | 4		   | 103		 | 2		| 4 		 | NULL	  | 2020-01-04 13:23:46.000	| Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 8			| 5  	   | 104		 | 1 		| NULL		 | 1	  | 2020-01-08 21:00:29.000	| Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami|
| 9         | 6		   | 101		 | 2		| NULL		 | NULL	  | 2020-01-08 21:03:13.000	| Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes|
| 10		| 7  	   | 105		 | 2 		| NULL		 | 1	  | 2020-01-08 21:20:29.000	| Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes|
| 11        | 8		   | 102		 | 1		| NULL		 | NULL	  | 2020-01-09 23:54:33.000	| Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami|
| 12		| 9  	   | 103		 | 1 		| 4 		 | 1, 5	  | 2020-01-10 11:22:59.000	| Meatlovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami|
| 13		| 10  	   | 104		 | 1 		| NULL		 | NULL	  | 2020-01-11 18:34:49.000	| Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami|
| 14		| 10 	   | 104		 | 1 		| 2, 6		 | 1, 4	  | 2020-01-11 18:34:49.000 | Meatlovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami |

### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

```sql
WITH FREQUENCY AS (
	SELECT CO.RECORD_ID, PT.TOPPING_NAME,
		   CASE
				WHEN PT.TOPPING_ID IN (SELECT EXTRA_ID FROM #EXTRAS_SPLIT E WHERE E.RECORD_ID = CO.RECORD_ID) THEN 2
				WHEN PT.TOPPING_ID IN (SELECT EXCLUSION_ID FROM #EXCLUSIONS_SPLIT EX WHERE EX.RECORD_ID = CO.RECORD_ID) THEN 0
				ELSE 1
		   END AS TIMES
	FROM #CUSTOMER_ORDERS_TEMP CO
	JOIN #TOPPING_SPLIT TS ON CO.PIZZA_ID = TS.PIZZA_ID
	JOIN PIZZA_TOPPINGS PT ON PT.TOPPING_ID = TS.TOPPING_ID)
SELECT TOPPING_NAME, SUM(TIMES) AS TOTAL_TIMES
FROM FREQUENCY
GROUP BY TOPPING_NAME
ORDER BY TOTAL_TIMES DESC
```

| TOPPING_NAME | TOTAL_TIMES |
|--------------|-------------|
| Bacon	       | 13          |
| Mushrooms	   | 13          |
| Cheese	   | 11          |
| Chicken	   | 11          |
| Pepperoni	   | 10          |
| Salami	   | 10          |
| Beef	       | 10          |
| BBQ Sauce	   | 9           |
| Peppers	   | 4           |
| Onions	   | 4           |
| Tomato Sauce | 4           |
| Tomatoes	   | 4           |



