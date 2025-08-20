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

