
--What is the total amount each customer spent at the restaurant?
SELECT CUSTOMER_ID, SUM(PRICE) AS TOTAL_AMOUNT
FROM SALES
JOIN MENU ON SALES.PRODUCT_ID = MENU.PRODUCT_ID
GROUP BY CUSTOMER_ID
GO

--How many days has each customer visited the restaurant?
SELECT CUSTOMER_ID, COUNT(DISTINCT ORDER_DATE) AS NUMBER_OF_DAYS
FROM SALES
GROUP BY CUSTOMER_ID
GO

--What was the first item from the menu purchased by each customer?
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM SALES
JOIN MENU ON SALES.PRODUCT_ID = MENU.PRODUCT_ID
WHERE SALES.ORDER_DATE = (SELECT MIN(ORDER_DATE)
						  FROM SALES
						  WHERE CUSTOMER_ID = SALES.CUSTOMER_ID)
GO

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
GO

--What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 S.PRODUCT_ID, PRODUCT_NAME, COUNT(S.PRODUCT_ID) AS TIMES
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY S.PRODUCT_ID, PRODUCT_NAME
ORDER BY TIMES DESC
GO

--Which item was the most popular for each customer?
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
GO

--Which item was purchased first by the customer after they became a member?
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
GO

--Which item was purchased just before the customer became a member?
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
GO

--What is the total items and amount spent for each member before they became a member?
SELECT S.CUSTOMER_ID, COUNT(S.PRODUCT_ID) AS TOTAL_ITEMS, SUM(M.PRICE) AS AMOUNT
FROM SALES S
JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
WHERE S.ORDER_DATE < MB.JOIN_DATE
GROUP BY S.CUSTOMER_ID
GO

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT S.CUSTOMER_ID, SUM(CASE
								WHEN M.PRODUCT_NAME = 'sushi' THEN M.PRICE * 10 * 2
								ELSE M.PRICE * 10
						  END) AS TOTAL_POINTS
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
GROUP BY S.CUSTOMER_ID
GO

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
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
GO

--Bonus questions 1: Join All The Things
--Recreate the following table output using the available data
SELECT S.CUSTOMER_ID, S.ORDER_DATE, M.PRODUCT_NAME, 
	   M.PRICE, CASE 
					WHEN S.ORDER_DATE >= MB.JOIN_DATE THEN 'Y'
					ELSE 'N'
				END AS MEMBER
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
LEFT JOIN MEMBERS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
GO

--Bonus questions 2: Rank All The Things
/*Danny also requires further information about the ranking of customer products,
but he purposely does not need the ranking for non-member purchases 
so he expects null ranking values for the records when customers are not yet part of the loyalty program.*/
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
GO
