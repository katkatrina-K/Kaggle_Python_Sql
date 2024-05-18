CREATE TABLE df_orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    ship_mode VARCHAR(20),
    segment VARCHAR(20),
    country VARCHAR(20),
    city VARCHAR(20),
    state VARCHAR(20),
    postal_code VARCHAR(20),
    region VARCHAR(20),
    category VARCHAR(20),
    sub_category VARCHAR(20),
    product_id VARCHAR(20),
    quantity INT,
    discount DECIMAL(7,2),
    sale_price DECIMAL(7,2),
    profit DECIMAL(7,2)
);

SELECT * FROM df_orders;

-- find top 10 highest revenue generating products
SELECT 
	product_id, SUM(profit) AS revenue
FROM df_orders
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 10;

-- find top 5 highest selling products in each region
WITH CTE AS(
	SELECT
		region, product_id, SUM(quantity) AS cnt
	FROM df_orders
	GROUP BY product_id, region)
SELECT region, product_id, cnt
FROM(
	SELECT 
		*,
		DENSE_RANK() OVER(PARTITION BY region ORDER BY cnt DESC) AS rnk
	 FROM CTE) AS subquery
WHERE rnk <= 5;

-- find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
WITH CTE AS(
	SELECT 
		YEAR(order_date) AS yr, MONTH(order_date) AS mth,
		SUM(sale_price) AS sales
	FROM df_orders
	GROUP BY yr, mth)
SELECT
	*, 
    ROUND((sales_2023 - sales_2022) / sales_2022, 2) AS sales_growth
FROM(
	SELECT 
		mth,
		SUM(CASE WHEN yr = 2022 THEN sales ELSE 0 END) AS sales_2022,
		SUM(CASE WHEN yr = 2023 THEN sales ELSE 0 END) AS sales_2023
	FROM CTE
	GROUP BY mth
	ORDER BY mth) AS subquery;
    
-- for each category which month had highest sales
WITH CTE AS( 
	SELECT 
		category, 
		DATE_FORMAT(order_date, '%Y-%m') AS yr_mth, SUM(sale_price) AS sales
	FROM df_orders
	GROUP BY category, yr_mth)
SELECT category, yr_mth, sales
FROM(
	SELECT
		category, yr_mth, sales,
		ROW_NUMBER() OVER(PARTITION BY category ORDER BY sales DESC) AS rnk
	FROM CTE) AS subquery
WHERE rnk = 1;

-- which sub category had highest growth by profit in 2023 compare to 2022
WITH Total_Ravenue AS(
	SELECT 
		sub_category, YEAR(order_date) AS yr, SUM(profit) AS revenue
	FROM df_orders
	GROUP BY sub_category, yr),

Revenue_Comparison AS(
	SELECT 
		sub_category,
		DENSE_RANK() OVER(ORDER BY (revenue_2023 - revenue_2022)/revenue_2022 DESC) AS rnk
	FROM(
		SELECT 
			sub_category,
			SUM(CASE WHEN yr = 2022 THEN revenue ELSE 0 END) AS revenue_2022,
			SUM(CASE WHEN yr = 2023 THEN revenue ELSE 0 END) AS revenue_2023
		FROM Total_Ravenue
		GROUP BY sub_category) AS subquery)
        
SELECT sub_category FROM Revenue_Comparison WHERE rnk = 1;
