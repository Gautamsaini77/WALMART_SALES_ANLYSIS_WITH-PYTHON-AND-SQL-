SELECT * FROM WALMART 

--BUSINESS PROBLEMS

--1 What are the different payment methods, and how many transactions and items were sold with each method?
SELECT A.payment_method ,COUNT(*) AS TOTAL_TRANSACTIONS,
SUM(A.quantity)AS TOTAL_QTY_SOLD FROM WALMART AS A
GROUP BY A.payment_method 

--2 Which category received the highest average rating in each branch?
SELECT * FROM
          (
           SELECT A.Branch, A.category,AVG(A.rating) as AVG_RATING,
          RANK() OVER(PARTITION BY A.Branch ORDER BY AVG(A.rating)DESC) AS RANK_ 
		  FROM WALMART AS A
          GROUP BY A.Branch, A.category
		  ) AS B
WHERE B.RANK_ = 1

--3 What is the busiest day of the week for each branch based on transaction volume
SELECT T.Branch, T.WEEK_DAY, T.TRAN_COUNT
FROM (
    SELECT 
        Branch,
        DATENAME(WEEKDAY, TRY_CONVERT(DATE, A.date)) AS WEEK_DAY,
        COUNT(A.invoice_id) AS TRAN_COUNT,
        RANK() OVER (PARTITION BY A.Branch ORDER BY COUNT(A.invoice_id) DESC) AS RNK
    FROM WALMART as A
	WHERE TRY_CONVERT(DATE,A.date) IS NOT NULL
    GROUP BY A.Branch, DATENAME(WEEKDAY, TRY_CONVERT(DATE,A.date))
) as T
WHERE RNK = 1
ORDER BY T.Branch


--4.Calculate Total Quantity Sold by Payment Method
SELECT A.payment_method ,
SUM(A.quantity) AS TOTAL_QTY FROM WALMART AS A
GROUP BY A.payment_method

--5 What are the average, minimum, and maximum ratings for each category in each city?
SELECT A.City ,A.category,
 AVG(A.rating) AS AVG_RATING,
 MAX(A.rating) AS MAX_RATING,
 MIN(A.rating) AS MIN_RATING
FROM WALMART AS A
GROUP BY A.City,A.category

--6 What is the total profit for each category, ranked from highest to lowest?
SELECT A.category,SUM(A.Total * A.profit_margin) AS T_PROFIT,
DENSE_RANK() OVER( ORDER BY SUM(A.Total)DESC) AS RANK_
FROM WALMART AS A
GROUP BY A.category


--7 What is the most frequently used payment method in each branch?
SELECT * FROM 
           (SELECT  A.Branch, A.payment_method,COUNT(*) AS MOST_FREQ,
            RANK() OVER(PARTITION BY A.Branch ORDER BY COUNT(*)DESC) AS RANK_
            FROM WALMART AS A
            GROUP BY A.Branch,A.payment_method) AS T
WHERE T.RANK_ = 1

--8  How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
SELECT B.Branch, B.DAY_TIME,B.TOTAL_TRAN FROM
(SELECT A.Branch, 
    CASE 
        WHEN  DATEPART(HOUR , A.time)< 12 THEN 'MORNING'
	    WHEN  DATEPART(HOUR , A.time) BETWEEN 12 AND 17 THEN 'AFTERNOON'
	    ELSE 'EVENING'
    END DAY_TIME,COUNT(*) AS TOTAL_TRAN
 FROM WALMART AS A
 GROUP BY 
        A.Branch,
        CASE 
            WHEN DATEPART(HOUR,A.time)< 12 THEN 'MORNING'
            WHEN DATEPART(HOUR,A.time) BETWEEN 12 AND 17 THEN 'AFTERNOON'
            ELSE 'EVENING'
        END
 ) AS B
ORDER BY B.Branch,B.TOTAL_TRAN DESC


--9  In year 2023 Which branches experienced the largest decrease in revenue compared to the 2022 year?

SELECT *,  DATENAME(YEAR, TRY_CONVERT(DATE, A.date)) AS YEAR FROM WALMART AS A
WHERE  DATENAME(YEAR, TRY_CONVERT(DATE, A.date)) IS NOT NULL 

WITH REVENUE_2022
AS 
(
SELECT A.Branch,SUM(A.Total) AS R_2022
FROM WALMART AS A
WHERE  DATENAME(YEAR, TRY_CONVERT(DATE, A.date)) = 2022
GROUP BY A.Branch
),
REVENUE_2023
AS
(
SELECT B.Branch,SUM(B.TOTAL) AS R_2023
FROM WALMART AS B
WHERE  DATENAME(YEAR, TRY_CONVERT(DATE, B.date)) = 2023
GROUP BY B.Branch
)
SELECT TOP 5
PY.Branch,PY.R_2022 AS PY_REVENUE,
CY.Branch,CY.R_2023  AS CY_REVENUE,
ROUND((PY.R_2022-CY.R_2023 )/PY.R_2022*100,2) AS REV_DEC_RATIO
FROM REVENUE_2022 AS PY
JOIN
REVENUE_2023 AS CY
ON PY.BRANCH = CY.BRANCH
WHERE PY.R_2022>CY.R_2023 
ORDER BY REV_DEC_RATIO DESC
