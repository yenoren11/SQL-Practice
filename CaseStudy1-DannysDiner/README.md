# 🍜 Case Study #1 - Danny's Diner

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT CUSTOMER_ID, SUM(PRICE) AS TOTAL_AMOUNT
FROM SALES
JOIN MENU ON SALES.PRODUCT_ID = MENU.PRODUCT_ID
GROUP BY CUSTOMER_ID
```

| CUSTOMER_ID | TOTAL_AMOUNT |
|-------------|--------------|
| A           | 76           |
| B           | 74           |
| C           | 36           |

### 2. How many days has each customer visited the restaurant?

```sql
SELECT CUSTOMER_ID, COUNT(DISTINCT ORDER_DATE) AS NUMBER_OF_DAYS
FROM SALES
GROUP BY CUSTOMER_ID
```

| CUSTOMER_ID | NUMBER_OF_DAYS |
|-------------|----------------|
| A           | 4              |
| B           | 6              |
| C           | 2              |

### 3. What was the first item from the menu purchased by each customer?

```sql
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM (
    SELECT 
        S.CUSTOMER_ID,
        M.PRODUCT_NAME,
        ROW_NUMBER() OVER (
            PARTITION BY S.CUSTOMER_ID 
            ORDER BY S.ORDER_DATE, S.PRODUCT_ID
        ) AS RNK
    FROM SALES S
    JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
) T
WHERE RNK = 1
```

| CUSTOMER_ID | PRODUCT_NAME |
|-------------|--------------|
| A           | sushi        |
| B           | curry        |
| C           | ramen        |

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
SELECT TOP 1 S.PRODUCT_ID, PRODUCT_NAME, COUNT(S.PRODUCT_ID) AS TIMES
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY S.PRODUCT_ID, PRODUCT_NAME
ORDER BY TIMES DESC
```

| PRODUCT_ID | PRODUCT_NAME | TIMES  |
|------------|--------------|--------|
| 3          | ramen        | 8      |

### 5. Which item was the most popular for each customer?

```sql
WITH RANKED_ITEM AS (
	SELECT S.CUSTOMER_ID, M.PRODUCT_NAME, COUNT(*) AS ORDER_COUNT,
	ROW_NUMBER() OVER (
	PARTITION BY S.CUSTOMER_ID 
	ORDER BY COUNT(*) DESC) AS RNK
	FROM SALES S
	JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
	GROUP BY S.CUSTOMER_ID, M.PRODUCT_NAME)
SELECT CUSTOMER_ID, PRODUCT_NAME, ORDER_COUNT
FROM RANKED_ITEM
WHERE RNK = 1
```

| CUSTOMER_ID | PRODUCT_NAME | ORDER_COUNT |
|-------------|--------------|-------------|
| A           | ramen        | 3           |
| B           | sushi        | 2           |
| C           | ramen        | 3           |

### 6. Which item was purchased first by the customer after they became a member?

```sql
SELECT S.CUSTOMER_ID, M.PRODUCT_NAME
FROM SALES S
JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
WHERE S.ORDER_DATE = (
    SELECT MIN(ORDER_DATE)
    FROM SALES
    WHERE CUSTOMER_ID = S.CUSTOMER_ID
      AND ORDER_DATE >= MB.JOIN_DATE
)
```

| CUSTOMER_ID | PRODUCT_NAME |
|-------------|--------------|
| B           | sushi        |
| A           | curry        |

### 7. Which item was purchased just before the customer became a member?

```sql
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM (
    SELECT S.CUSTOMER_ID, M.PRODUCT_NAME,
           ROW_NUMBER() OVER (
               PARTITION BY S.CUSTOMER_ID
               ORDER BY S.PRODUCT_ID DESC
           ) AS RN
    FROM SALES S
    JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
    JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
    WHERE S.ORDER_DATE = (
        SELECT MAX(ORDER_DATE)
        FROM SALES
        WHERE CUSTOMER_ID = S.CUSTOMER_ID
          AND ORDER_DATE < MB.JOIN_DATE
    )
) AS X
WHERE RN = 1
```

| CUSTOMER_ID | PRODUCT_NAME |
|-------------|--------------|
| A           | curry        |
| B           | sushi        |

### 8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT S.CUSTOMER_ID, COUNT(S.PRODUCT_ID) AS TOTAL_ITEMS, SUM(M.PRICE) AS AMOUNT
FROM SALES S
JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
WHERE S.ORDER_DATE < MB.JOIN_DATE
GROUP BY S.CUSTOMER_ID
```

| CUSTOMER_ID | TOTAL_ITEMS | AMOUNT |
|-------------|-------------|--------|
| A           | 2           | 25     |
| B           | 3           | 40     |

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```sql
SELECT S.CUSTOMER_ID, SUM(CASE
								WHEN M.PRODUCT_NAME = 'sushi' THEN M.PRICE * 10 * 2
								ELSE M.PRICE * 10
						  END) AS TOTAL_POINTS
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
GROUP BY S.CUSTOMER_ID
```

| CUSTOMER_ID | TOTAL_POINTS |
|-------------|--------------|
| A           | 860          |
| B           | 940          |

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql
SELECT S.CUSTOMER_ID, SUM(CASE
								WHEN S.ORDER_DATE BETWEEN MB.JOIN_DATE AND DATEADD(DAY, 6, MB.JOIN_DATE) THEN M.PRICE * 10 * 2
								WHEN M.PRODUCT_NAME = 'sushi' THEN M.PRICE * 10 * 2
								ELSE M.PRICE * 10
						  END) AS TOTAL_POINTS
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
WHERE S.ORDER_DATE <= '2021-01-31'
GROUP BY S.CUSTOMER_ID
```

| CUSTOMER_ID | TOTAL_POINTS |
|-------------|--------------|
| A           | 1370         |
| B           | 820          |

### 🍀 Bonus questions 1: Join All The Things

The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

```sql
SELECT S.CUSTOMER_ID, S.ORDER_DATE, M.PRODUCT_NAME, 
	   M.PRICE, CASE 
					WHEN S.ORDER_DATE >= MB.JOIN_DATE THEN 'Y'
					ELSE 'N'
				END AS MEMBER
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
LEFT JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
```

| CUSTOMER_ID | ORDER_DATE | PRODUCT_NAME | PRICE | MEMBER |
|-------------|------------|--------------|-------|--------|
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

### 🍀 Bonus questions 2: Rank All The Things

Danny also requires further information about the `ranking` of customer products, but he purposely does not need the ranking for non-member purchases so he expects null `ranking` values for the records when customers are not yet part of the loyalty program.

```sql
WITH FILTERED_ORDERS AS (
	SELECT S.CUSTOMER_ID, S.ORDER_DATE, 
		   M.PRODUCT_NAME, M.PRICE, 
		   CASE 
				WHEN S.ORDER_DATE >= MB.JOIN_DATE THEN 'Y'
				ELSE 'N'
		   END AS MEMBER
	FROM SALES S
	JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
	LEFT JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
)
SELECT *,
	   CASE
			WHEN MEMBER = 'Y' THEN
				RANK() OVER (
					PARTITION BY CUSTOMER_ID,
					MEMBER ORDER BY ORDER_DATE)
			ELSE NULL
	   END AS RANKING
FROM FILTERED_ORDERS
```

| CUSTOMER_ID | ORDER_DATE | PRODUCT_NAME | PRICE | MEMBER | RANKING |
|-------------|------------|--------------|-------|--------|---------|
| A           | 2021-01-01 | curry        | 15    | N      | NULL    |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      | NULL    |
| B           | 2021-01-02 | curry        | 15    | N      | NULL    |
| B           | 2021-01-04 | sushi        | 10    | N      | NULL    |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-07 | ramen        | 12    | N      | NULL    |
