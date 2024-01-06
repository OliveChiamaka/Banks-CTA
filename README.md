# Customer Transacting Analytics Data Model

## Table of Content
- [Project Overview](#project-overview)
- [Aim of Project](#aim-of-project)
- [Data Source](#data-source)
- [Tools Used](#tools-used)
- [Data Import and Cleansing](#data-import-and-cleansing)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Building the Data Model](#building-the-data-model)
- [Findings](#findings)
- [Limitations](#limitations)

## Project Overview
This project explores and analyzes Customer Transactions within a banking environment. The development of this data model for Customer Transaction Analysis (CTA) tracks transactions for the past 12 months for the
sole purpose of having a data driven business decision and operational efficiency.


## Aim of Project
This data model is designed to categorize our customers into four segments: "Inactive," "New User," "Churned," and "Grower." Utilizing insights derived from this categorization, we can enhance our campaign targeting strategies for the future.   
Furthermore, this information will empower the business to proactively secure and retain our customers, thereby, informing strategic decision-making and enhancing overall operational efficiency.

## Data Source
I generated a dataset in python for the purpose of this project.   
The data includes Customers table with 20 rows and Transaction table with 500 rows and the date spanned for 12 months.

```python
import pandas as pd
import numpy as np
from faker import Faker
import random
import datetime

# Seed for reproducibility
np.random.seed(42)

# Create a Faker object to generate fake data
fake = Faker()
```

```python
# Generate unique account numbers for each customer
account_numbers = [str(random.randint(1000000000, 9999999999)) for _ in range(num_customers)]

# Generate 'account_type' with 90% savings and 10% current
account_types = ['Savings'] * int(0.9 * num_customers) + ['Current'] * int(0.1 * num_customers)
random.shuffle(account_types)
genders = [random.choice(['Male', 'Female']) for _ in range(num_customers)]

# Generate 'act_open_date' for customers within the specified date range
today = datetime.date(2023, 9, 25)
min_act_open_date = today - datetime.timedelta(days=540)  # 1.5 years ago
```

## Tools Used
Python - For generating the dataset  
SQL - For analysis and building the data model

## Data Import and Cleansing
Dataset was in csv format, and the tables were imported as a flat file into the database that was specifically created for the purpose of this project.  
The dataset came in clean.

## Exploratory Data Analysis (EDA)
In the course of this project, I explored the dataset on 
- Top 5 customers for the month with positive influence on net value  
- Top 5 customers for the month with negative influence on net value  
- Highest Credit Value by Products (To know which product is performing better)
- Transaction type by value
- Daily/Monthly Transaction Volume, Value (by transaction types) and Net Value

```sql
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
```

```sql
SELECT SUM(A.transaction_amount) AS Value, B.Products
FROM [Bank].[Transactions]A
JOIN [Bank].[Customer] B 
ON A.customer_id = B.customer_id
WHERE A.transaction_date >= '2023-08-01' AND A.transaction_date <='2023-08-30'
AND transaction_type = 'Credit'
GROUP BY B.Products
ORDER BY 1 DESC;
```

```sql
SELECT FORMAT(CONVERT(datetime, transaction_date, 103), 'MMMM-yyyy') AS Date, SUM(transaction_amount) AS Value
FROM [Bank].[Transactions]
GROUP BY FORMAT(CONVERT(datetime, transaction_date, 103), 'MMMM-yyyy')
--ORDER BY 2 DESC;
```

## Building the Data Model
The data model was built using subqueries and case when function. The query was written to get the previous month as (9 months past divided by 3) and the current month as the remaining 3 months.  
The case when functions were used to categorized the users. It was also used to create the previous month band and current month band.

```sql
 WHEN PREVIOUS_MONTH > 0 AND CURRENT_MONTH = 0 THEN 'Inactive'
                WHEN PREVIOUS_MONTH = 0 AND CURRENT_MONTH > 0 THEN 'New User'
                WHEN PREVIOUS_MONTH > CURRENT_MONTH AND CURRENT_MONTH > 0 THEN 'Churned'
                WHEN PREVIOUS_MONTH < CURRENT_MONTH AND CURRENT_MONTH > 0 THEN 'Grower'
                ELSE 'Unchanged'
```

## Findings
- From my analysis, the product ExtraInterest performed the best in terms of value.  
- Debit transaction was generated more than credit transaction during the course of the year
- The top 5 customers were seen by their positive and negative influence on net value

![SQL Result Image](https://github.com/OliveChiamaka/Banks-CTA/assets/122398374/2e51bd7a-e002-4d94-9e26-55f8f5081420)


## Limitations
The major challenge faced in the course of this project was dataset. The dataset size was quite small and as such could not derive insights as expected.
