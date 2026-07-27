-- ============================================================
-- SalesPulse 360
-- 02_data_quality_checks.sql
-- Purpose: Validate loaded data before analysis
-- ============================================================

-- Row-count validation
SELECT 'dim_date' AS table_name, COUNT(*) AS row_count
FROM salespulse.dim_date
UNION ALL
SELECT 'dim_locations', COUNT(*)
FROM salespulse.dim_locations
UNION ALL
SELECT 'dim_sales_reps', COUNT(*)
FROM salespulse.dim_sales_reps
UNION ALL
SELECT 'dim_customers', COUNT(*)
FROM salespulse.dim_customers
UNION ALL
SELECT 'dim_products', COUNT(*)
FROM salespulse.dim_products
UNION ALL
SELECT 'fact_orders', COUNT(*)
FROM salespulse.fact_orders
UNION ALL
SELECT 'fact_order_items', COUNT(*)
FROM salespulse.fact_order_items
UNION ALL
SELECT 'fact_returns', COUNT(*)
FROM salespulse.fact_returns
UNION ALL
SELECT 'fact_sales_targets', COUNT(*)
FROM salespulse.fact_sales_targets;

-- Structural quality checks
SELECT 'Duplicate order IDs' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT order_id
    FROM salespulse.fact_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'Duplicate order-line IDs', COUNT(*)
FROM (
    SELECT order_line_id
    FROM salespulse.fact_order_items
    GROUP BY order_line_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'Order items without matching orders', COUNT(*)
FROM salespulse.fact_order_items i
LEFT JOIN salespulse.fact_orders o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'Returns without matching order lines', COUNT(*)
FROM salespulse.fact_returns r
LEFT JOIN salespulse.fact_order_items i
    ON r.order_line_id = i.order_line_id
WHERE i.order_line_id IS NULL

UNION ALL

SELECT 'Invalid financial values', COUNT(*)
FROM salespulse.fact_order_items
WHERE revenue < 0
   OR cogs < 0
   OR discount_pct < 0
   OR discount_pct > 1

UNION ALL

SELECT 'Invalid shipping dates', COUNT(*)
FROM salespulse.fact_orders
WHERE ship_date < order_date

UNION ALL

SELECT 'Invalid return quantities', COUNT(*)
FROM salespulse.fact_returns r
JOIN salespulse.fact_order_items i
    ON r.order_line_id = i.order_line_id
WHERE r.return_quantity > i.quantity
   OR r.return_quantity <= 0;

-- Financial reconciliation checks
SELECT
    'Gross sales reconciliation issues' AS check_name,
    COUNT(*) AS issue_count
FROM salespulse.fact_order_items
WHERE ABS(gross_sales - discount_value - revenue) > 0.05

UNION ALL

SELECT
    'Contribution profit reconciliation issues',
    COUNT(*)
FROM salespulse.fact_order_items
WHERE ABS(revenue - cogs - allocated_shipping - contribution_profit) > 0.05;
