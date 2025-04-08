-- Using the superstore database
USE superstore;

-- ========================================================
--                    TABLE OVERVIEW
-- ========================================================
SELECT 'customers' AS table_name, COUNT(*) AS total_records FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sales', COUNT(*) FROM sales;

-- ========================================================
--                     DATA PREVIEW
-- ========================================================
SELECT * FROM customers LIMIT 5;
SELECT * FROM orders LIMIT 5;
SELECT * FROM products LIMIT 5;
SELECT * FROM sales LIMIT 5;

-- ========================================================
--                   ANALYSIS OVERVIEW
-- ========================================================
-- 1. Sales Performance and Revenue Analysis
-- 2. Customer Behavior and Segmentation
-- 3. Product Performance and Market Analysis
-- 4. Operational and Logistics Analysis


-- ========================================================
--        1. Sales Performance and Revenue Analysis
-- ========================================================

# 1.1 Sales Metrics

-- 1) What is the total sales revenue, total profit, and average discount offered?
SELECT 
    SUM(sales) AS total_revenue, 
    SUM(profit) AS total_profit, 
    ROUND(AVG(discount), 2) AS avg_discount 
FROM sales; 

-- 2) What is the average sales per order?
SELECT 
    ROUND(AVG(order_total), 2) AS avg_sales_per_order
FROM
    (SELECT 
        order_id, SUM(sales) AS order_total
    FROM
        sales
    GROUP BY order_id) AS t;

-- 3) What is the total number of orders placed and the total quantity of products sold?
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity_sold
FROM sales;

-- 4) What is the overall profit margin (profit as a percentage of sales)?
SELECT 
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS overall_profit_margin
FROM
    sales;

# 1.2 Sales Trends and Seasonality

-- 1) What is the monthly trend of sales and profit? 
SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit
FROM orders
JOIN sales ON orders.order_id = sales.order_id
GROUP BY month
ORDER BY month;

-- 2) What are the peak and off-peak seasons for sales based on monthly performance?
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(sales) AS total_sales
    FROM orders
    JOIN sales ON orders.order_id = sales.order_id
    GROUP BY month
),
avg_monthly_sales AS (
    SELECT AVG(total_sales) AS avg_sales
    FROM monthly_sales
)
SELECT 
    ms.month,
    ms.total_sales,
    CASE 
        WHEN ms.total_sales > ams.avg_sales THEN 'Peak'
        ELSE 'Off-Peak'
    END AS seasonality
FROM monthly_sales ms
CROSS JOIN avg_monthly_sales ams
ORDER BY ms.month;

-- 3) What are the monthly, quarterly, and yearly sales growth rates over time?
-- Monthly Growth Rate
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(sales) AS total_sales
    FROM orders
    JOIN sales ON orders.order_id = sales.order_id
    GROUP BY month
)
SELECT 
    month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month) AS previous_month_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY month)) / LAG(total_sales) OVER (ORDER BY month) * 100, 
        2
    ) AS monthly_growth_rate
FROM monthly_sales
ORDER BY month;

-- Quarterly Sales Growth Rate
WITH quarterly_sales AS (
    SELECT 
        YEAR(order_date) AS year,
        QUARTER(order_date) AS quarter,
        SUM(sales) AS total_sales
    FROM orders
    JOIN sales ON orders.order_id = sales.order_id
    GROUP BY year, quarter
)
SELECT 
    CONCAT(year, '-Q', quarter) AS quarter,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year, quarter) AS previous_quarter_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY year, quarter)) / LAG(total_sales) OVER (ORDER BY year, quarter) * 100, 
        2
    ) AS quarterly_growth_rate
FROM quarterly_sales
ORDER BY year, quarter;

-- Yearly Sales Growth Rate
WITH yearly_sales AS (
    SELECT 
        YEAR(order_date) AS year,
        SUM(sales) AS total_sales
    FROM orders
    JOIN sales ON orders.order_id = sales.order_id
    GROUP BY year
)
SELECT 
    year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year) AS previous_year_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY year)) / LAG(total_sales) OVER (ORDER BY year) * 100, 
        2
    ) AS yearly_growth_rate
FROM yearly_sales
ORDER BY year;

-- 4) How can we forecast sales using a 3-month rolling average?
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(sales) AS total_sales
    FROM orders
    JOIN sales ON orders.order_id = sales.order_id
    GROUP BY month
),
rolling_forecast AS (
    SELECT 
        month,
        total_sales,
        ROUND(AVG(total_sales) OVER (
            ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2) AS rolling_3_month_avg
    FROM monthly_sales
)
SELECT 
    month,
    total_sales,
    rolling_3_month_avg AS forecasted_sales
FROM rolling_forecast
ORDER BY month;

# 1.3 Regional Sales Performance

-- 1) Which region generates the highest sales and profit?
SELECT 
    region,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM orders
JOIN sales ON orders.order_id = sales.order_id
GROUP BY region
ORDER BY total_sales DESC, total_profit DESC;

-- 2) How are states ranked based on total sales performance?
SELECT
	o.state,
    SUM(s.sales) as total_sales,
    RANK() OVER (ORDER BY SUM(s.sales) DESC) AS sales_rank
FROM orders O
JOIN sales s ON o.order_id = s.order_id
GROUP BY 
	o.state
LIMIT 10;

# 1.4 Discount Impact on Sales and Profitability

-- 1) Identify the optimal discount range where profit remains stable.
SELECT 
    discount,
    ROUND(AVG(profit), 2) AS avg_profit
FROM sales
GROUP BY discount
ORDER BY discount;

-- 2) How do sales and profit compare between discounted and non-discounted orders?
WITH order_totals AS (
    SELECT 
        order_id,
        SUM(sales) AS order_sales,
        SUM(profit) AS order_profit,
        CASE 
            WHEN SUM(discount) > 0 THEN 'Discounted'
            ELSE 'Non-Discounted'
        END AS discount_status
    FROM sales
    GROUP BY order_id
)
SELECT 
    discount_status,
    COUNT(order_id) AS total_orders,
    SUM(order_sales) AS total_sales,
    SUM(order_profit) AS total_profit,
    ROUND((SUM(order_profit) / SUM(order_sales)) * 100, 2) AS profit_margin,
    ROUND(AVG(order_sales), 2) AS avg_sales_per_order,
    ROUND(AVG(order_profit), 2) AS avg_profit_per_order
FROM order_totals
GROUP BY discount_status;

-- 3) What is the impact of discounts on sales and profit by product category?
SELECT 
    p.category,
    CASE 
        WHEN s.discount > 0 THEN 'Discounted'
        ELSE 'Non-Discounted'
    END AS discount_status,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.category, discount_status
ORDER BY p.category, discount_status;

-- 4) How does profit change before and after applying discounts?
SELECT 
    CASE 
        WHEN s.discount = 0 THEN 'No Discount'
        WHEN s.discount <= 0.1 THEN 'Low Discount (<= 10%)'
        WHEN s.discount <= 0.25 THEN 'Medium Discount (<= 25%)'
        ELSE 'High Discount (> 25%)'
    END AS discount_range,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit,
    SUM(s.profit) * 100.0 / SUM(s.sales) AS profit_margin
FROM sales s
GROUP BY discount_range
ORDER BY total_profit DESC;


-- ========================================================
--          2. Customer Behavior and Segmentation
-- ========================================================

# 2.1 Customer Metrics

-- 1) How many unique customers are there?
SELECT 
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customers;

-- 2) Identify the top 10 customers by total sales and total profit.
SELECT 
    c.customer_id,
    c.customer_name,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN sales s ON o.order_id = s.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_sales DESC
LIMIT 10;

-- 3) What is the average order value (AOV) per customer?
SELECT 
    c.customer_id,
    c.customer_name,
    ROUND(AVG(s.sales), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN sales s ON o.order_id = s.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY avg_order_value DESC;

-- 4) How many new customers (first-time buyers) are acquired each month?
SELECT 
    DATE_FORMAT(first_order_date, '%Y-%m') AS month,
    COUNT(customer_id) AS new_customers
FROM
    (SELECT 
        customer_id, MIN(order_date) AS first_order_date
    FROM
        orders
    GROUP BY customer_id) AS first_orders
GROUP BY month
ORDER BY month;

# 2.2 Customer Purchase Frequency

-- 1) Which customers spent the most per order?
SELECT 
    c.customer_name, ROUND(AVG(s.sales), 2) AS avg_order_value
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    sales s ON o.order_id = s.order_id
GROUP BY c.customer_name
ORDER BY avg_order_value DESC
LIMIT 10;

-- 2) Calculate the most frequent customers by order count.
SELECT c.customer_name, COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_orders DESC
LIMIT 10;

-- 3) What are the monthly customer order trends?
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(DISTINCT o.customer_id) AS active_customers,
    COUNT(o.order_id) AS total_orders
FROM orders o
GROUP BY month
ORDER BY month;

-- 4) What is the frequency distribution of customers based on their total sales?
WITH customer_totals AS (
    SELECT
        c.customer_id,
        SUM(s.sales) AS total_sales
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN sales s ON o.order_id = s.order_id
    GROUP BY c.customer_id
)
SELECT 
    CASE 
        WHEN total_sales < 1000 THEN '< 1K'
        WHEN total_sales BETWEEN 1000 AND 2000 THEN '1K-2K'
        WHEN total_sales BETWEEN 2000 AND 3000 THEN '2K-3K'
        WHEN total_sales BETWEEN 3000 AND 5000 THEN '3K-5K'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN '5K-10K'
        ELSE 'Above 10K'
    END AS sales_range,
    COUNT(*) AS customer_count
FROM customer_totals
GROUP BY sales_range
ORDER BY sales_range;

-- 5) How does customer purchasing behavior vary across different geographic locations (state, city, and region)?
SELECT 
    o.state,
    o.city,
    o.region,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS customer_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN sales s ON o.order_id = s.order_id
GROUP BY o.state, o.city, o.region
ORDER BY total_sales DESC;

-- 6) What is the average number of days between orders for each customer, and how do customers' purchase frequencies vary (monthly, quarterly, yearly)?
WITH customer_order_dates AS (
    SELECT 
        o.customer_id,
        c.customer_name,
        o.order_date,
        LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS previous_order_date
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
),
customer_order_intervals AS (
    SELECT 
        customer_id,
        customer_name,
        ROUND(AVG(DATEDIFF(order_date, previous_order_date)), 1) AS avg_days_between_orders
    FROM customer_order_dates
    WHERE previous_order_date IS NOT NULL
    GROUP BY customer_id, customer_name
)
SELECT 
    customer_id,
    customer_name,
    avg_days_between_orders,
    CASE 
        WHEN avg_days_between_orders <= 30 THEN 'Monthly Buyer'
        WHEN avg_days_between_orders <= 90 THEN 'Quarterly Buyer'
        ELSE 'Yearly Buyer'
    END AS buyer_category
FROM customer_order_intervals
ORDER BY avg_days_between_orders;

# 2.3 Customer Segmentation

-- 1) Who are the top 10% of customers based on total spending?
WITH customer_revenue AS (
    SELECT 
        o.customer_id,
        c.customer_name,
        SUM(s.sales) AS total_revenue
    FROM orders o
    JOIN sales s ON o.order_id = s.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY o.customer_id, c.customer_name
),
top_customers AS (
    SELECT 
        customer_id,
        customer_name,
        total_revenue,
        NTILE(100) OVER (ORDER BY total_revenue DESC) AS percentile_rank
    FROM customer_revenue
)
SELECT 
    customer_id,
    customer_name,
    total_revenue
FROM top_customers
WHERE percentile_rank <= 10 -- Top 10% customers
ORDER BY total_revenue DESC;

-- 2) How can customers be segmented into high-value, medium-value, and low-value groups, and how does their behavior vary across different metrics?
-- (a) How can customers be classified into high-value, medium-value, and low-value groups based on their total spending?
-- (b) What is the Average Order Value (AOV) for each customer segment?
-- (c) How does the distribution of high, medium, and low-value customers vary across different geographic locations (state, city, and region)?
CREATE TEMPORARY TABLE segmented_customers AS
WITH customer_revenue AS (
    SELECT 
        o.customer_id, 
        c.customer_name,
        SUM(s.sales) AS total_sales,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN sales s ON o.order_id = s.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY o.customer_id, c.customer_name
)
SELECT 
    customer_id,
    customer_name,
    total_sales,
    CASE 
        WHEN total_sales > 5000 THEN 'High-Value'
        WHEN total_sales BETWEEN 2000 AND 5000 THEN 'Medium-Value'
        ELSE 'Low-Value'
    END AS customer_segment
FROM customer_revenue;

-- (a) Segemented Customers Details  
SELECT 
    customer_id,
    customer_name,
    total_sales,
    customer_segment
FROM segmented_customers
ORDER BY total_sales DESC;

-- (b) Average Order Value
SELECT 
    customer_segment,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(total_sales / (SELECT COUNT(DISTINCT o.order_id) 
                             FROM orders o 
                             WHERE o.customer_id = sc.customer_id)), 2) AS avg_order_value
FROM segmented_customers sc
GROUP BY customer_segment
ORDER BY avg_order_value DESC;

-- (c) Distrbution of Customers by Segment
SELECT 
    o.state,
    o.city,
    o.region,
    COUNT(DISTINCT CASE WHEN sc.customer_segment = 'High-Value' THEN sc.customer_id END) AS high_value_customers,
    COUNT(DISTINCT CASE WHEN sc.customer_segment = 'Medium-Value' THEN sc.customer_id END) AS medium_value_customers,
    COUNT(DISTINCT CASE WHEN sc.customer_segment = 'Low-Value' THEN sc.customer_id END) AS low_value_customers
FROM segmented_customers sc
JOIN orders o ON sc.customer_id = o.customer_id
GROUP BY o.state, o.city, o.region
ORDER BY high_value_customers DESC;

-- Optional Step:
DROP TEMPORARY TABLE IF EXISTS segmented_customers;

-- 3) How can we segment customers based on Recency, Frequency, and Monetary (RFM) value?
-- (a) How can we calculate the RFM values for each customer?
-- (b) How can we assign RFM scores for customers?
/* RFM analysis is a method that categorizes customers using three metrics: 
(i) Recency: How recently did a customer make a purchase?
(ii) Frequency: How often do they purchase?
(iii) Monetary Value: How much do they spend?
This segmentation helps identify which customers are the most valuable versus those who are less engaged. 
Typically, a 1-5 scale is used for each factor, with 1 representing the lowest value and 5 representing the highest value. 
Then individual R, F, and M scores are combined to create a single RFM score for each customer. */
CREATE TEMPORARY TABLE rfm_table AS
WITH rfm_raw AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        DATEDIFF(
            (SELECT MAX(order_date) FROM orders),  -- Latest order date in dataset
            MAX(o.order_date)                      -- Customer’s most recent order
        ) AS recency,  
        COUNT(DISTINCT o.order_id) AS frequency,  
        SUM(s.sales) AS monetary  
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN sales s ON o.order_id = s.order_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT * FROM rfm_raw;

-- (a) RFM values for each customer
SELECT * FROM rfm_table
ORDER BY recency ASC, frequency DESC, monetary DESC;

-- (b) RFM scores for each customer
WITH rfm_scores AS (
    SELECT 
        customer_id,
        customer_name,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency ASC) AS recency_score,  
        NTILE(5) OVER (ORDER BY frequency DESC) AS frequency_score,  
        NTILE(5) OVER (ORDER BY monetary DESC) AS monetary_score  
    FROM rfm_table
)
SELECT 
    customer_id,
    customer_name,
    recency_score,
    frequency_score,
    monetary_score,
    CONCAT(recency_score, frequency_score, monetary_score) AS rfm_score
FROM rfm_scores
ORDER BY rfm_score DESC;

-- Optional Step:
DROP TEMPORARY TABLE IF EXISTS rfm_table;

# 2.4. Customer Retention and Churn

-- 1) What is the repeat purchase rate of customers?
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT 
    ROUND(SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_id), 2) AS repeat_purchase_rate
FROM customer_orders;

-- 2) What is the percentage of customers returning within 6 months of their first purchase?
WITH first_orders AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY customer_id
),
returning_customers AS (
    SELECT DISTINCT
        o.customer_id
    FROM orders o
    JOIN first_orders fo ON o.customer_id = fo.customer_id
    WHERE o.order_date > fo.first_order_date  
    AND o.order_date <= DATE_ADD(fo.first_order_date, INTERVAL 6 MONTH) 
)
SELECT 
    ROUND(COUNT(rc.customer_id) * 100.0 / COUNT(fo.customer_id), 2) AS returning_within_6_months
FROM first_orders fo
LEFT JOIN returning_customers rc ON fo.customer_id = rc.customer_id;

-- 3) Compare the sales contribution of new customers (first purchase in a given month) with that of returning customers.
WITH first_purchase_month_cte AS (
    SELECT 
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS first_purchase_month
    FROM orders
    GROUP BY customer_id
),
monthly_sales_cte AS (
    SELECT 
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,  
        SUM(sales.sales) AS total_sales
    FROM orders
    JOIN sales
      ON orders.order_id = sales.order_id
    GROUP BY customer_id, order_month
)
SELECT 
    ms.order_month,  
    SUM(CASE WHEN fp.first_purchase_month = ms.order_month THEN ms.total_sales ELSE 0 END) AS new_customer_sales,
    SUM(CASE WHEN fp.first_purchase_month < ms.order_month THEN ms.total_sales ELSE 0 END) AS returning_customer_sales
FROM monthly_sales_cte ms
JOIN first_purchase_month_cte fp
    ON ms.customer_id = fp.customer_id
GROUP BY ms.order_month;

-- 4) What is the customer churn rate (the percentage of customers who haven’t placed an order in the last 6 months)?
-- Ensuring that customers who placed an order after the 6-month period aren’t counted as churned incorrectly.
WITH customer_activity AS (
    -- Identify last purchase date for each customer
    SELECT 
        customer_id, 
        MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY customer_id
),
active_customers AS (
    -- Customers who made a purchase in the last 6 months
    SELECT customer_id
    FROM customer_activity
    WHERE last_order_date >= DATE_SUB((SELECT MAX(order_date) FROM orders), INTERVAL 6 MONTH)
),
churned_customers AS (
    -- Customers who haven’t purchased in the last 6 months but had at least one order before
    SELECT customer_id
    FROM customer_activity
    WHERE last_order_date < DATE_SUB((SELECT MAX(order_date) FROM orders), INTERVAL 6 MONTH)
)
SELECT 
    ROUND((COUNT(DISTINCT churned_customers.customer_id) / 
		   COUNT(DISTINCT customer_activity.customer_id) * 100), 2) AS churn_rate_percentage
FROM customer_activity
LEFT JOIN churned_customers ON customer_activity.customer_id = churned_customers.customer_id;

-- 5) What is the customer lifetime value (CLV) for each customer?
-- CLV = Average Purchase Value × Average Purchase Frequency × Average Customer Lifespan
WITH customer_data AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(s.profit) AS total_profit,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date)) / 365.0 AS customer_lifespan_years
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN sales s ON o.order_id = s.order_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT 
    customer_id,
    customer_name,
    total_profit / total_orders AS avg_purchase_value,
    total_orders / customer_lifespan_years AS avg_purchase_frequency,
    customer_lifespan_years,
    ROUND((total_profit / total_orders) * (total_orders / customer_lifespan_years) * customer_lifespan_years, 2) AS clv
FROM customer_data
ORDER BY clv DESC;


-- ========================================================
--        3. Product and Market Analysis
-- ========================================================

# 3.1. Product Metrics

-- 1) How many unique products are available?
SELECT 
    COUNT(DISTINCT product_id) AS unique_products
FROM products;

-- 2) What is the average order value (AOV) for each product?
SELECT 
    p.product_id,
    p.product_name,
    ROUND(SUM(s.sales) / COUNT(DISTINCT s.order_id), 2) AS avg_order_value
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name
ORDER BY avg_order_value DESC;

-- 3) What is the profit margin for each product?
SELECT 
    p.product_id,
    p.product_name,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit,
    ROUND((SUM(s.profit) / SUM(s.sales)) * 100, 2) AS profit_margin
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name
ORDER BY profit_margin DESC;

-- 4) What are the most frequently occurring order quantities? 
SELECT 
    quantity,
    COUNT(*) AS frequency
FROM sales
GROUP BY quantity
ORDER BY frequency DESC;

-- 5) What is the lifetime revenue per product?
SELECT 
    p.product_id,
    p.product_name,
    COUNT(DISTINCT s.order_id) AS total_orders,
    SUM(s.sales) AS total_lifetime_revenue
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_lifetime_revenue DESC;

# 3.2. Top and Bottom Performers

-- 1) What are the top best-selling products by total sales revenue and profit? Calculate their total quantity sold and average price per unit for each product.
SELECT 
    p.product_id,
    p.product_name,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit,
    ROUND(SUM(s.sales) / SUM(s.quantity), 2) AS avg_price_per_unit
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_sales DESC;

-- 2) Which are the bottom 5 products by profit margin?
SELECT 
    p.product_name,
    SUM(s.profit) AS total_profit,
    ROUND(SUM(s.profit) / SUM(s.sales) * 100, 2) AS profit_margin
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY profit_margin ASC
LIMIT 5;

-- 3) Identify loss-making orders (orders with negative profit).
SELECT o.order_id, c.customer_name, s.sales, s.profit
FROM orders o
JOIN sales s ON o.order_id = s.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE s.profit < 0
ORDER BY s.profit ASC
LIMIT 10;

-- 4) Which are the top 5 best-selling products in each category based on quantity sold?
WITH product_sales AS (
    SELECT 
        p.category, 
        s.product_id, 
        p.product_name, 
        SUM(s.quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(s.quantity) DESC) AS product_rank
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.category, s.product_id, p.product_name
)
SELECT *
FROM product_sales
WHERE product_rank <= 5; 

# 3.3 Discount Impact on Products

-- 1) Which segment receives the highest discounts?
SELECT 
    c.segment,
    AVG(s.discount) AS avg_discount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN sales s ON o.order_id = s.order_id
GROUP BY c.segment
ORDER BY avg_discount DESC;

-- 2) Which products have the highest discount?
SELECT p.product_name, AVG(s.discount) AS avg_discount
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY avg_discount DESC
LIMIT 10;

-- 3) What is the discount impact on product category/sub-category sales and profit?
SELECT 
    p.category,
    p.sub_category,
    ROUND(AVG(s.discount), 2) AS avg_discount,
    SUM(CASE WHEN s.discount > 0 THEN s.sales ELSE 0 END) AS sales_with_discount,
    SUM(CASE WHEN s.discount = 0 THEN s.sales ELSE 0 END) AS sales_without_discount,
    SUM(CASE WHEN s.discount > 0 THEN s.profit ELSE 0 END) AS profit_with_discount,
    SUM(CASE WHEN s.discount = 0 THEN s.profit ELSE 0 END) AS profit_without_discount
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.category, p.sub_category
ORDER BY avg_discount DESC;

-- 4) How do price changes impact sales volume and profitability of different product categories?
WITH price_changes AS (
    SELECT 
        p.category,
        DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
        SUM(s.sales) AS total_sales,
        SUM(s.quantity) AS total_quantity_sold,
        ROUND(SUM(s.sales) / NULLIF(SUM(s.quantity), 0), 2) AS avg_price_per_unit,
        SUM(s.profit) AS total_profit
    FROM products p
    JOIN sales s ON p.product_id = s.product_id
    JOIN orders o ON s.order_id = o.order_id
    GROUP BY p.category, sales_month
)
SELECT 
    sales_month,
    category,
    total_sales,
    total_quantity_sold,
    avg_price_per_unit,
    total_profit,
    LAG(avg_price_per_unit) OVER (PARTITION BY category ORDER BY sales_month) AS previous_avg_price,
    ROUND(avg_price_per_unit - LAG(avg_price_per_unit) OVER (PARTITION BY category ORDER BY sales_month), 2) AS price_change,
    ROUND(total_quantity_sold - LAG(total_quantity_sold) OVER (PARTITION BY category ORDER BY sales_month), 2) AS quantity_change,
    ROUND(total_profit - LAG(total_profit) OVER (PARTITION BY category ORDER BY sales_month), 2) AS profit_change
FROM price_changes
ORDER BY category, sales_month;

# 3.4. Market Trends and Insights

-- 1) What is the sales and profit contribution (percentage) of each product category/sub-category?
-- By Product Category
SELECT 
    p.category,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit,
    ROUND(SUM(s.sales) / (SELECT SUM(sales) FROM sales) * 100 , 2) AS sales_contribution,
    ROUND(SUM(s.profit) / (SELECT SUM(profit) FROM sales) * 100 , 2) AS profit_contribution
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.category
ORDER BY sales_contribution DESC;
-- By Sub-Category
SELECT 
    p.category,
    p.sub_category,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit,
    ROUND(SUM(s.sales) / (SELECT SUM(sales) FROM sales) * 100 , 2) AS sales_contribution,
    ROUND(SUM(s.profit) / (SELECT SUM(profit) FROM sales) * 100 , 2) AS profit_contribution
FROM products p
JOIN sales s ON p.product_id = s.product_id
GROUP BY p.category, p.sub_category
ORDER BY sales_contribution DESC;

-- 2) Which customer segments generate the highest profit across different product categories?
SELECT 
    c.segment,
    p.category,
    SUM(s.profit) AS total_profit
FROM sales s
JOIN orders o
    ON s.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN products p
    ON s.product_id = p.product_id
GROUP BY c.segment, p.category
ORDER BY total_profit DESC;

-- 3) Which products are frequently bought together (market basket analysis)?
WITH product_pairs AS (
    SELECT 
        s1.product_id AS product1,
        s2.product_id AS product2,
        COUNT(*) AS frequency
    FROM sales s1
    JOIN sales s2 ON s1.order_id = s2.order_id
    WHERE s1.product_id < s2.product_id
    GROUP BY s1.product_id, s2.product_id
)
SELECT 
    p1.product_name AS product1,
    p2.product_name AS product2,
    pp.frequency
FROM product_pairs pp
JOIN products p1 ON pp.product1 = p1.product_id
JOIN products p2 ON pp.product2 = p2.product_id
ORDER BY pp.frequency DESC
LIMIT 10;


-- ========================================================
--        4. Operational and Logistics Analysis
-- ========================================================

# 4.1 Shipping Performance

-- 1) What is the average shipping time (in days) for all orders?
SELECT 
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 1) AS avg_shipping_time
FROM orders;

-- 2) How does the average shipping time vary by city?
SELECT 
    city,
    ROUND(AVG(DATEDIFF(ship_date, order_date)),2) AS avg_shipping_time
FROM orders
GROUP BY city
ORDER BY avg_shipping_time DESC;

-- 3) Which states have the highest and lowest average shipping times?
-- Highest Shipping Times
SELECT 
    state,
    AVG(DATEDIFF(ship_date, order_date)) AS avg_shipping_time
FROM orders
GROUP BY city
ORDER BY avg_shipping_time DESC
LIMIT 5;
-- Lowest Shipping Times
SELECT 
    state,
    AVG(DATEDIFF(ship_date, order_date)) AS avg_shipping_time
FROM orders
GROUP BY city
ORDER BY avg_shipping_time ASC
LIMIT 5;

-- 4) Identify orders that experienced delays (assuming 3 days is the expected shipping time) and analyze patterns.
SELECT 
    COUNT(*) AS delayed_orders,
    ROUND(AVG(DATEDIFF(ship_date, order_date) - 3), 2) AS avg_shipping_delay,  -- Delay beyond 3 days
    MAX(DATEDIFF(ship_date, order_date) - 3) AS longest_delay, 
    MIN(DATEDIFF(ship_date, order_date) - 3) AS shortest_delay
FROM orders
WHERE ship_date IS NOT NULL 
AND DATEDIFF(ship_date, order_date) > 3;  

# 4.2 Shipping Modes and Efficiency

-- 1) How many orders are shipped by each ship mode? What is the distribution of orders across different ship modes (as a percentage of total orders)?
SELECT 
    ship_mode,
    COUNT(order_id) AS total_orders,
    ROUND(COUNT(order_id) * 1.0 / 
		 (SELECT COUNT(*) FROM orders) * 100, 2) AS order_percentage
FROM
    orders
GROUP BY ship_mode
ORDER BY total_orders DESC;

-- 2) Which ship mode is the most cost-effective in terms of profit per order?
SELECT 
    o.ship_mode,
    SUM(s.profit) AS total_profit,
    ROUND(SUM(s.profit) / COUNT(DISTINCT o.order_id), 2) AS profit_per_order
FROM orders o
JOIN sales s ON o.order_id = s.order_id
GROUP BY o.ship_mode
ORDER BY profit_per_order DESC;

-- 3) Identify which shipping modes are causing the most delays.
SELECT 
    ship_mode,
    COUNT(*) AS delayed_orders,
    ROUND(AVG(DATEDIFF(ship_date, order_date) - 3), 2) AS avg_shipping_delay,
    MAX(DATEDIFF(ship_date, order_date) - 3) AS longest_delay,
    MIN(DATEDIFF(ship_date, order_date) - 3) AS shortest_delay
FROM orders
WHERE ship_date IS NOT NULL 
AND DATEDIFF(ship_date, order_date) > 3
GROUP BY ship_mode
ORDER BY avg_shipping_delay DESC;

# 4.3 Order and Shipping Trends

-- 1) Which regions and states has the highest number of orders?
-- By Region
SELECT 
    region,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY region
ORDER BY total_orders DESC;
-- By State
SELECT 
    state,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY city
ORDER BY total_orders DESC
LIMIT 10;

-- 2) Which months have the highest order volumes, and which days of the week see the most orders?
-- Peak Order Months
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY month
ORDER BY total_orders DESC;
-- Days of the Week with Most Orders
SELECT 
    DAYNAME(order_date) AS day_of_week,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY day_of_week
ORDER BY total_orders DESC;

-- 3) How do shipping times and order volumes vary by month?
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 2) AS avg_shipping_time,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY month
ORDER BY month;

# 4.4 Customer Satisfaction and Logistics

-- 1) What is the on-time delivery rate (percentage of orders delivered within 4 days)?
SELECT 
    ROUND(COUNT(CASE
                WHEN DATEDIFF(ship_date, order_date) <= 4 THEN order_id
            END) * 1.0 / COUNT(order_id) * 100,
            2) AS on_time_delivery_rate
FROM
    orders;

-- 2) What are the average shipping times and how are products categorized by shipping speed?
WITH shipping_time AS (
    SELECT 
        o.order_id,
        p.product_name,
        DATEDIFF(o.ship_date, o.order_date) AS days_to_ship
    FROM orders o
    JOIN sales s ON o.order_id = s.order_id
    JOIN products p ON s.product_id = p.product_id
),
shipping_stats AS (
    SELECT 
        product_name,
        ROUND(AVG(days_to_ship), 2) AS avg_shipping_time
    FROM shipping_time
    GROUP BY product_name
)
SELECT 
    product_name,
    avg_shipping_time,
    CASE 
        WHEN avg_shipping_time <= 2 THEN 'Fast Shipping'
        WHEN avg_shipping_time <= 4 THEN 'Moderate Shipping'
        ELSE 'Slow Shipping'
    END AS shipping_category
FROM shipping_stats
ORDER BY avg_shipping_time ASC;



