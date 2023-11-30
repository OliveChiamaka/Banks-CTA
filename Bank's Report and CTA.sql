--Create Database
CREATE DATABASE BankProject

--Create Schema
CREATE SCHEMA Bank

--Import Data

--View tables
SELECT * 
FROM [Bank].[Customer]

SELECT * 
FROM [Bank].[Transactions]

--Sum Transaction type
SELECT transaction_type, SUM(transaction_amount) AS Value
FROM [Bank].[Transactions]
GROUP BY transaction_type

--Total Transactions by month and year
SELECT FORMAT(CONVERT(datetime, transaction_date, 103), 'MMMM-yyyy') AS Date, SUM(transaction_amount) AS Value
FROM [Bank].[Transactions]
GROUP BY FORMAT(CONVERT(datetime, transaction_date, 103), 'MMMM-yyyy')

--Total transactions by month for most recent year 2023
SELECT FORMAT (CONVERT(datetime, transaction_date), 'MMMM') AS Date, SUM(transaction_amount) AS Value
FROM [Bank].[Transactions] 
WHERE transaction_date BETWEEN '01-JAN-2023' AND '31-DEC-2023'
GROUP BY FORMAT (CONVERT(datetime, transaction_date), 'MMMM')

--For a daily/monthly report
--the credit transactions for the last date

--View the last date (2023-08-29)
SELECT MAX(transaction_date) AS Date
FROM [Bank].[Transactions] 

--Transactions that happened on 2023-08-29
SELECT DISTINCT A.customer_id, B.customer_name, A.transaction_amount, A.transaction_type, B.products, A.transaction_date
FROM [Bank].[Transactions] A
JOIN [Bank].[Customer] B
ON A.customer_id = B. customer_id
WHERE A.transaction_date = '2023-08-29'
AND currency = 'Naira'

--Transaction count and transaction value for 2023-08-29
SELECT COUNT(DISTINCT customer_id) AS Customer_Count, SUM (transaction_amount) AS Value, transaction_date 
FROM(SELECT DISTINCT A.customer_id, B.customer_name, A.transaction_amount, A.transaction_type, B.products, A.transaction_date
FROM [Bank].[Transactions] A
JOIN [Bank].[Customer] B
ON A.customer_id = B. customer_id
WHERE A.transaction_date = '2023-08-29'
AND currency = 'Naira') AS Daily_Tran
GROUP BY transaction_date; 

--Transactions for a week or month
SELECT COUNT(DISTINCT customer_id) AS Customer_Count, SUM (transaction_amount) AS Value 
FROM(SELECT DISTINCT A.customer_id, B.customer_name, A.transaction_amount, A.transaction_type, B.products, A.transaction_date
FROM [Bank].[Transactions] A
JOIN [Bank].[Customer] B
ON A.customer_id = B. customer_id
WHERE A.transaction_date >= '2023-08-01' AND A.transaction_date <='2023-08-30'
AND currency = 'Naira') AS Daily_Tran;

--credit transaction for a month
SELECT COUNT(DISTINCT customer_id) AS Customer_Count, SUM (transaction_amount) AS Value
FROM(SELECT DISTINCT A.customer_id, B.customer_name, A.transaction_amount, A.transaction_type, B.products, A.transaction_date
FROM [Bank].[Transactions] A
JOIN [Bank].[Customer] B
ON A.customer_id = B. customer_id
WHERE A.transaction_date >= '2023-08-01' AND A.transaction_date <='2023-08-30'
AND currency = 'Naira') AS Daily_Tran
WHERE transaction_type = 'Credit'

--See both transaction types
SELECT COUNT(DISTINCT customer_id) AS Customer_Count, SUM (transaction_amount) AS Value, transaction_type
FROM(SELECT DISTINCT A.customer_id, B.customer_name, A.transaction_amount, A.transaction_type, B.products, A.transaction_date
FROM [Bank].[Transactions] A
JOIN [Bank].[Customer] B
ON A.customer_id = B. customer_id
WHERE A.transaction_date >= '2023-08-01' AND A.transaction_date <='2023-08-30'
AND currency = 'Naira') AS Daily_Tran
GROUP BY transaction_type;

--Top 5 customers for the month with positive influence on net value
--Querying a months data in real life is a lot, you can use hints such as [ /*+parallel(10)+*/] for oracle db or OPTION (MAXDOP 10) FOR SQL Server db
--This hints SQL Server to use a maximum of 10 processors for parallel execution.

SELECT DISTINCT TOP 5 A.customer_id, B.customer_name, A.transaction_date,
SUM(CASE WHEN A.transaction_type = 'Credit' THEN A.transaction_amount ELSE 0 END) Credit_Amt,
SUM(CASE WHEN A.transaction_type = 'Debit' THEN A.transaction_amount ELSE 0 END) Debit_Amt,
SUM(CASE WHEN A.transaction_type = 'Credit' THEN A.transaction_amount ELSE 0 END - CASE WHEN A.transaction_type = 'Debit' THEN A.transaction_amount ELSE 0 END) Net_Value
FROM [Bank].[Transactions]A
JOIN [Bank].[Customer] B 
ON A.customer_id = B.customer_id
WHERE A.transaction_date >= '2023-08-01' AND A.transaction_date <='2023-08-30'
GROUP BY A.customer_id, B.customer_name, A.transaction_date
ORDER BY Net_Profit DESC;

--Top 5 customers for the month with negative influence on net value
SELECT DISTINCT TOP 5 A.customer_id, B.customer_name, A.transaction_date,
SUM(CASE WHEN A.transaction_type = 'Credit' THEN A.transaction_amount ELSE 0 END) Credit_Amt,
SUM(CASE WHEN A.transaction_type = 'Debit' THEN A.transaction_amount ELSE 0 END) Debit_Amt,
SUM(CASE WHEN A.transaction_type = 'Credit' THEN A.transaction_amount ELSE 0 END - CASE WHEN A.transaction_type = 'Debit' THEN A.transaction_amount ELSE 0 END) Net_Value
FROM [Bank].[Transactions]A
JOIN [Bank].[Customer] B 
ON A.customer_id = B.customer_id
WHERE A.transaction_date >= '2023-08-01' AND A.transaction_date <='2023-08-30'
GROUP BY A.customer_id, B.customer_name, A.transaction_date
ORDER BY Net_Profit ASC;

--Highest Credit Value by Products (To know which product is performing better)
SELECT SUM(A.transaction_amount) AS Value, B.Products
FROM [Bank].[Transactions]A
JOIN [Bank].[Customer] B 
ON A.customer_id = B.customer_id
WHERE A.transaction_date >= '2023-08-01' AND A.transaction_date <='2023-08-30'
AND transaction_type = 'Credit'
GROUP BY B.Products
ORDER BY 1 DESC;


--Data Model: Customer Transaction Analysis (CTA)
--This analysis will be taking a look at customers transactions within a 12 month period. Here, we would see those that dropped in transacting.

SELECT
    customer_id,
    customer_name,
    PREVIOUS_MONTH,
    CURRENT_MONTH,
    PREVIOUS_MONTH_BAND,
    CURRENT_MONTH_BAND,
    CTA_Value
FROM
    (
        SELECT
            customer_id,
            customer_name,
            PREVIOUS_MONTH,
            CURRENT_MONTH,
            CASE 
                WHEN PREVIOUS_MONTH > 0 AND CURRENT_MONTH = 0 THEN 'Inactive'
                WHEN PREVIOUS_MONTH = 0 AND CURRENT_MONTH > 0 THEN 'New User'
                WHEN PREVIOUS_MONTH > CURRENT_MONTH AND CURRENT_MONTH > 0 THEN 'Churned'
                WHEN PREVIOUS_MONTH < CURRENT_MONTH AND CURRENT_MONTH > 0 THEN 'Grower'
                ELSE 'Unchanged'
            END AS CTA_Value,
            CASE 
                WHEN PREVIOUS_MONTH <= 10000 THEN '0 - 10K'
                WHEN PREVIOUS_MONTH BETWEEN 10001 AND 100000 THEN '>10K - 100K'
                WHEN PREVIOUS_MONTH BETWEEN 100001 AND 500000 THEN '>100K - 500K'
                WHEN PREVIOUS_MONTH BETWEEN 500001 AND 1000000 THEN '>500K - 1M'
                WHEN PREVIOUS_MONTH > 1000000 THEN '>1M' 
                ELSE 'No Transaction'
            END AS PREVIOUS_MONTH_BAND,
            CASE 
                WHEN CURRENT_MONTH <= 10000 THEN '0 - 10K'
                WHEN CURRENT_MONTH BETWEEN 10001 AND 100000 THEN '>10K - 100K'
                WHEN CURRENT_MONTH BETWEEN 100001 AND 500000 THEN '>100K - 500K'
                WHEN CURRENT_MONTH BETWEEN 500001 AND 1000000 THEN '>500K - 1M'
                WHEN CURRENT_MONTH > 1000000 THEN '>1M' 
                ELSE 'No Transaction'
            END AS CURRENT_MONTH_BAND
        FROM
            (
                SELECT
                    customer_id,
                    customer_name,
                    Value,
                    SUM(CASE WHEN Period = 'Previous_month' THEN Value/3 ELSE 0 END) AS PREVIOUS_MONTH,  ---Here , we are calculating the sum of value within our previous month which is 9 months ago (12 months ago - 4 months ago) and dividing it by 3, so that would be 9/3 = 3 .This division is important so it can stand as equal with the present 3 months
                    SUM(CASE WHEN Period = 'Current_month' THEN Value ELSE 0 END) AS CURRENT_MONTH
                FROM
                    (
                        SELECT
                            DISTINCT A.customer_id,
                            B.customer_name,
                            SUM(A.transaction_amount) AS Value,
                            A.transaction_type,
                            CASE 
                                WHEN A.transaction_date BETWEEN CONVERT(DATE, EOMONTH(DATEADD(MONTH, -12, GETDATE()), 0))
                                AND CONVERT(DATE, EOMONTH(DATEADD(MONTH, -4, GETDATE()),0)) THEN 'Previous_month'
                                ELSE 'Current_month'
                            END AS Period

--GETDATE(): Retrieves the current date and time.
--DATEADD(): Subtracts 12 months from the current date and time, giving you a date 12 months ago.
--EOMONTH (0): Finds the last day of the month. The 0 argument specifies the current date and time for the calculation.
--CONVERT: Converts the result obtained a DATE data type. This removes the time component, giving just the date.

                        FROM
                            [Bank].[Transactions] A
                        JOIN
                            [Bank].[Customer] B ON A.customer_id = B.customer_id
                        WHERE
                            A.transaction_date BETWEEN CONVERT(DATE, EOMONTH(DATEADD(MONTH, -12, GETDATE()), 0))
                            AND CONVERT(DATE, EOMONTH(DATEADD(MONTH, -1, GETDATE()),0))
                        GROUP BY
                            A.customer_id, B.customer_name, A.transaction_type,
                            CASE 
                                WHEN A.transaction_date BETWEEN CONVERT(DATE, EOMONTH(DATEADD(MONTH, -12, GETDATE()), 0))
                                AND CONVERT(DATE, EOMONTH(DATEADD(MONTH, -4, GETDATE()),0)) THEN 'Previous_month'
                                ELSE 'Current_month'
                            END
                    ) AS Month_Range
                GROUP BY
                    customer_id, customer_name, Value
            ) AS Value_Range
    ) AS Month_band
WHERE
    CTA_Value IN ('Churned');
