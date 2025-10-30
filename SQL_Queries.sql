#CODEBASICS_SQL_PROJECT_CHALLENGE

/* 1.Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business 
in the  APAC  region.*/

SELECT DISTINCT market FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region = 'APAC';


/* 2.What is the percentage of unique product increase in 2021 vs. 2020? 
The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg  */

with cte as (
select
(SELECT COUNT(DISTINCT product_code)
FROM fact_sales_monthly WHERE fiscal_year = '2020') as unique_products_2020,
(SELECT COUNT(DISTINCT product_code) 
    FROM fact_sales_monthly WHERE fiscal_year = '2021') as unique_products_2021) 
SELECT 
    unique_products_2020,
    unique_products_2021,
    ROUND((unique_products_2021 - unique_products_2020) / unique_products_2020 * 100,2) AS percentage_chg
from cte;


/* 3.Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts. 
The final output contains 2 fields, segment product_count */

SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;


-- 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, segment product_count_2020 product_count_2021 difference 

#approach 1- using cte
with 
cte as (SELECT segment, COUNT(DISTINCT product_code) AS product_code_2020 FROM dim_product 
 JOIN fact_sales_monthly USING (product_code)
 WHERE fiscal_year = '2020' GROUP BY segment),
cte1 as(SELECT 
    segment, COUNT(DISTINCT product_code) AS product_code_2021 FROM dim_product
        JOIN fact_sales_monthly USING (product_code)
        WHERE fiscal_year = '2021'GROUP BY segment ) 
select *,(product_code_2021-product_code_2020) as Difference from cte 
join cte1 using (segment)
group by segment;

#approach 2 - using case statement
SELECT segment,
    COUNT(DISTINCT CASE WHEN fiscal_year = '2020' THEN product_code END) AS product_code_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = '2021' THEN product_code END) AS product_code_2021,
    COUNT(DISTINCT CASE WHEN fiscal_year = '2021' THEN product_code END) 
    - COUNT(DISTINCT CASE WHEN fiscal_year = '2020' THEN product_code END) AS difference
FROM dim_product JOIN fact_sales_monthly USING (product_code)
GROUP BY segment;


-- 5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, 
-- product_code product manufacturing_cost 

SELECT m.product_code, p.product, m.manufacturing_cost
FROM fact_manufacturing_cost m
        JOIN dim_product p ON m.product_code = p.product_code
WHERE m.manufacturing_cost = (SELECT MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR m.manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost);


-- 6.Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  for the  fiscal  
-- year 2021  and in the Indian  market. The final output contains these fields, customer_code customer average_discount_percentage 

SELECT 
    c.customer_code,
    c.customer,
    AVG(pre_invoice_discount_pct) * 100 AS average_discount_percentage
FROM dim_customer c JOIN
    fact_pre_invoice_deductions p ON c.customer_code = p.customer_code
WHERE market = 'India' AND fiscal_year = '2021'
GROUP BY c.customer_code , c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;


-- 7.Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month  . This analysis helps to  get 
-- an idea of low and high-performing months and take strategic decisions.The final report contains these columns: Month Year Gross sales Amount 

#approach 1
SELECT 
    MONTHNAME(s.date) AS month,s.fiscal_year,
    SUM(g.gross_price * s.sold_quantity) / 1000000 AS gross_sales_amount
FROM fact_gross_price g JOIN
     fact_sales_monthly s ON g.product_code = s.product_code
        AND g.fiscal_year = s.fiscal_year
        JOIN dim_customer USING (customer_code)
WHERE customer = 'Atliq Exclusive' GROUP BY month , fiscal_year
order by fiscal_year;

#approach 2 - using cte
with cte as(
SELECT * FROM fact_gross_price g
         JOIN fact_sales_monthly USING (product_code , fiscal_year)
         JOIN dim_customer USING (customer_code)
WHERE customer = 'Atliq Exclusive')
SELECT 
    MONTHNAME(date) AS month, fiscal_year,
    SUM(gross_price * sold_quantity) / 1000000 AS gross_sales_amount
FROM cte GROUP BY month , fiscal_year;


-- 8.  In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity 

SELECT 
    CASE
        WHEN MONTH(date) IN (9 , 10, 11) THEN 'Q1'
        WHEN MONTH(date) IN (12 , 1, 2) THEN 'Q2'
        WHEN MONTH(date) IN (3 , 5, 6) THEN 'Q3'
        ELSE 'Q4'
    END AS Quarter,
    ROUND(SUM(sold_quantity) / 1000000, 2) AS total_sold_qty
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_qty DESC;


-- 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
--  The final output  contains these fields, channel gross_sales_mln percentage 

#approach 1 - using Cross Join and Multiple CTEs
with cte as(SELECT * FROM fact_gross_price g JOIN fact_sales_monthly 
	    USING (product_code , fiscal_year)
        JOIN dim_customer USING (customer_code)
        WHERE fiscal_year = 2021),
cte1 as (SELECT SUM(gross_price * sold_quantity) / 1000000 AS gross_sales_total FROM cte )
SELECT channel,
	SUM(gross_price * sold_quantity) / 1000000 AS gross_sales_amount,
	(SUM(gross_price * sold_quantity) / 1000000) / c.gross_sales_total * 100 AS percentag
FROM cte CROSS JOIN cte1 c GROUP BY channel;

#approach 2 - Using Window Functions
WITH cte AS (SELECT channel,SUM(gross_price * sold_quantity) / 1000000 AS gross_sales_amount
    FROM fact_gross_price g
    JOIN fact_sales_monthly USING(product_code, fiscal_year)
    JOIN dim_customer USING(customer_code)
    WHERE fiscal_year = 2021
    GROUP BY channel)
SELECT 
    channel,round(gross_sales_amount,2) as gross_sales_amount,
    ROUND(gross_sales_amount * 100.0 / SUM(gross_sales_amount) OVER (),2) AS gross_sales_percentage
FROM cte;


-- 10.  Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields, division product_code  product total_sold_quantity rank_order 

with cte as(
SELECT division,product_code,product,
    SUM(sold_quantity) AS total_sold_quantity,
rank () over(partition by division order by sum(sold_quantity) desc) as rank_order
from fact_sales_monthly 
join dim_product using (product_code)
where fiscal_year=2021
group by division,product_code,product)
SELECT * FROM cte WHERE rank_order <= 3;
