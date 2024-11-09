CREATE DATABASE clients_purchases;
USE clients_purchases;
SET SESSION sql_mode = '';

CREATE TABLE clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id VARCHAR(36),
    gender VARCHAR(10),
    age INT,
    total_amount INT,
    count_city INT,
    response_communcation INT,
    communication_3month INT,
    tenure INT
);

LOAD DATA INFILE 'D:\\Files\\AITY\\3 course\\1 trimester\\Data Visualization\\final project\\customer_info.csv'
INTO TABLE clients
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(client_id, total_amount, gender, age, count_city, response_communcation, communication_3month, tenure);

CREATE TABLE transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    check_id VARCHAR(36),
    client_id VARCHAR(36),
    products_count DECIMAL(10, 3),
    payment_sum DECIMAL(10, 2),
    date DATE
);

LOAD DATA INFILE 'D:\\Files\\AITY\\3 course\\1 trimester\\Data Visualization\\final project\\cleaned_transactions_info.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(date, check_id, client_id, products_count, payment_sum);

/*
1. a list of clients with a continuous history for the year, that is, every month on a regular basis without omissions 
for the specified annual period, the average receipt for the period from 06/01/2015 to 06/01/2016, the average amount 
of purchases per month, the number of all transactions per client for the period;
*/
SELECT 
    c.client_id,
    COUNT(DISTINCT DATE_FORMAT(t.date, '%Y-%m')) AS months_with_transactions,
    AVG(t.payment_sum) AS avg_receipt,
    SUM(t.payment_sum) / COUNT(DISTINCT DATE_FORMAT(t.date, '%Y-%m')) AS avg_monthly_purchase,
    COUNT(t.id) AS total_transactions
FROM 
    clients c
JOIN 
    transactions t ON c.client_id = t.client_id
GROUP BY 
    c.client_id
HAVING 
    months_with_transactions = 12;

/*
2. information by month:
the average amount of the check per month;
average number of operations per month;
the average number of clients who performed transactions;
the share of the total number of transactions for the year and the share per month of the total amount of transactions;
print the % ratio of M/F/NA in each month with their share of costs;
*/
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    AVG(payment_sum) AS avg_check_amount
FROM 
    transactions
GROUP BY 
    month;

SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    COUNT(id) AS transaction_count
FROM 
    transactions
GROUP BY 
    month;

SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    COUNT(DISTINCT client_id) AS unique_clients
FROM 
    transactions
GROUP BY 
    month;

SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    COUNT(id) AS monthly_transactions,
    (SELECT COUNT(id) FROM transactions WHERE YEAR(date) = 2015) AS total_transactions
FROM 
    transactions
WHERE 
    YEAR(date) = 2015
GROUP BY 
    month;

SELECT 
    DATE_FORMAT(t.date, '%Y-%m') AS month,    
    (SUM(CASE WHEN c.gender = 'M' THEN 1 ELSE 0 END) / COUNT(t.id)) * 100 AS male_percentage,
    (SUM(CASE WHEN c.gender = 'F' THEN 1 ELSE 0 END) / COUNT(t.id)) * 100 AS female_percentage,
    (SUM(CASE WHEN c.gender = '' THEN 1 ELSE 0 END) / COUNT(t.id)) * 100 AS na_percentage,
    
    (SUM(CASE WHEN c.gender = 'M' THEN t.payment_sum ELSE 0 END) / SUM(t.payment_sum)) * 100 AS male_payment_percentage,
    (SUM(CASE WHEN c.gender = 'F' THEN t.payment_sum ELSE 0 END) / SUM(t.payment_sum)) * 100 AS female_payment_percentage,
    (SUM(CASE WHEN c.gender = '' THEN t.payment_sum ELSE 0 END) / SUM(t.payment_sum)) * 100 AS na_payment_percentage
FROM 
    transactions t
JOIN 
    clients c ON t.client_id = c.client_id
GROUP BY 
    month
ORDER BY 
    month;

/*
3. age groups of clients in increments of 10 years and separately clients who do not have this information, 
with the parameters amount and number of transactions for the entire period, and quarterly - averages and %.
*/
SELECT 
    age_group, quarter, quarterly_transactions, quarterly_amount,
    (quarterly_amount / (SELECT SUM(payment_sum) FROM transactions)) * 100 AS amount_percentage,
    (quarterly_transactions / (SELECT COUNT(id) FROM transactions)) * 100 AS transaction_percentage
FROM (
    SELECT 
        CASE 
            WHEN age = 0 THEN 'Unknown'
            WHEN age BETWEEN 1 AND 9 THEN '1-9'
            WHEN age BETWEEN 10 AND 19 THEN '10-19'
            WHEN age BETWEEN 20 AND 29 THEN '20-29'
            WHEN age BETWEEN 30 AND 39 THEN '30-39'
            WHEN age BETWEEN 40 AND 49 THEN '40-49'
            WHEN age BETWEEN 50 AND 59 THEN '50-59'
            WHEN age BETWEEN 60 AND 69 THEN '60-69'
            WHEN age BETWEEN 70 AND 79 THEN '70-79'
            ELSE '80+'
        END AS age_group,
        CONCAT(YEAR(date), ' Q', QUARTER(date)) AS quarter,
        COUNT(transactions.id) AS quarterly_transactions,
        SUM(payment_sum) AS quarterly_amount
    FROM  clients
    JOIN  transactions ON clients.client_id = transactions.client_id
    GROUP BY age_group, quarter
) AS quarterly_summary;

