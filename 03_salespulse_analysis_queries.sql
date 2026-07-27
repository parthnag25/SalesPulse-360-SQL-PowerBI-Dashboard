-- ============================================================
-- SalesPulse 360
-- 03_salespulse_analysis_queries.sql
-- Purpose: Final SQL analysis queries for sales, profitability,
--          discount leakage, returns, customers, sales reps,
--          and opportunity quantification.
-- ============================================================

-- ============================================================
-- Query 1: Executive KPI Baseline
-- ============================================================

SELECT
    ROUND(SUM(i.revenue), 2) AS total_revenue,
    ROUND(SUM(i.contribution_profit), 2) AS contribution_profit,
    ROUND(
        100.0 * SUM(i.contribution_profit) /
        NULLIF(SUM(i.revenue), 0),
        2
    ) AS contribution_margin_pct,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    ROUND(
        SUM(i.revenue) /
        NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value,
    SUM(i.quantity) AS units_sold,
    ROUND(
        100.0 * SUM(i.discount_value) /
        NULLIF(SUM(i.gross_sales), 0),
        2
    ) AS discount_rate_pct
FROM salespulse.fact_order_items i
JOIN salespulse.fact_orders o
    ON i.order_id = o.order_id;


-- ============================================================
-- Query 2: Yearly Performance
-- ============================================================

SELECT
    EXTRACT(YEAR FROM o.order_date)::INTEGER AS sales_year,
    ROUND(SUM(i.revenue), 2) AS total_revenue,
    ROUND(SUM(i.contribution_profit), 2) AS contribution_profit,
    ROUND(
        100.0 * SUM(i.contribution_profit)
        / NULLIF(SUM(i.revenue), 0),
        2
    ) AS contribution_margin_pct,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(i.revenue)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value,
    ROUND(
        100.0 * SUM(i.discount_value)
        / NULLIF(SUM(i.gross_sales), 0),
        2
    ) AS discount_rate_pct
FROM salespulse.fact_orders o
JOIN salespulse.fact_order_items i
    ON o.order_id = i.order_id
GROUP BY EXTRACT(YEAR FROM o.order_date)
ORDER BY sales_year;


-- ============================================================
-- Query 3: Regional Performance
-- ============================================================

SELECT
    l.region,
    ROUND(SUM(i.revenue), 2) AS total_revenue,
    ROUND(SUM(i.contribution_profit), 2) AS contribution_profit,
    ROUND(
        100.0 * SUM(i.contribution_profit)
        / NULLIF(SUM(i.revenue), 0),
        2
    ) AS contribution_margin_pct,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(i.revenue)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value,
    ROUND(
        100.0 * SUM(i.discount_value)
        / NULLIF(SUM(i.gross_sales), 0),
        2
    ) AS discount_rate_pct,
    ROUND(
        100.0 * SUM(i.revenue)
        / SUM(SUM(i.revenue)) OVER (),
        2
    ) AS revenue_share_pct
FROM salespulse.fact_orders o
JOIN salespulse.fact_order_items i
    ON o.order_id = i.order_id
JOIN salespulse.dim_locations l
    ON o.location_id = l.location_id
GROUP BY l.region
ORDER BY total_revenue DESC;


-- ============================================================
-- Query 4: Channel Profitability
-- ============================================================

WITH order_sales AS (
    SELECT
        o.order_id,
        o.channel,
        o.customer_id,
        SUM(i.revenue) AS revenue,
        SUM(i.contribution_profit) AS contribution_profit,
        SUM(i.gross_sales) AS gross_sales,
        SUM(i.discount_value) AS discount_value,
        SUM(i.quantity) AS units_sold
    FROM salespulse.fact_orders o
    JOIN salespulse.fact_order_items i
        ON o.order_id = i.order_id
    GROUP BY
        o.order_id,
        o.channel,
        o.customer_id
),

order_returns AS (
    SELECT
        order_id,
        SUM(return_quantity) AS returned_units,
        SUM(refund_amount) AS refund_amount,
        SUM(refund_amount + restocking_cost) AS total_return_cost
    FROM salespulse.fact_returns
    GROUP BY order_id
)

SELECT
    s.channel,
    ROUND(SUM(s.revenue), 2) AS total_revenue,
    ROUND(SUM(s.contribution_profit), 2) AS contribution_profit,
    ROUND(
        100.0 * SUM(s.contribution_profit)
        / NULLIF(SUM(s.revenue), 0),
        2
    ) AS contribution_margin_pct,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(
        SUM(s.revenue)
        / NULLIF(COUNT(*), 0),
        2
    ) AS average_order_value,
    ROUND(
        100.0 * SUM(s.discount_value)
        / NULLIF(SUM(s.gross_sales), 0),
        2
    ) AS discount_rate_pct,
    ROUND(COALESCE(SUM(r.refund_amount), 0), 2) AS refund_amount,
    ROUND(COALESCE(SUM(r.total_return_cost), 0), 2) AS total_return_cost,
    ROUND(SUM(s.revenue) - COALESCE(SUM(r.refund_amount), 0), 2) AS net_revenue,
    ROUND(SUM(s.contribution_profit) - COALESCE(SUM(r.total_return_cost), 0), 2) AS net_contribution_profit,
    ROUND(
        100.0 * COALESCE(SUM(r.returned_units), 0)
        / NULLIF(SUM(s.units_sold), 0),
        2
    ) AS return_rate_pct,
    ROUND(
        100.0 * SUM(s.revenue)
        / SUM(SUM(s.revenue)) OVER (),
        2
    ) AS revenue_share_pct
FROM order_sales s
LEFT JOIN order_returns r
    ON s.order_id = r.order_id
GROUP BY s.channel
ORDER BY total_revenue DESC;


-- ============================================================
-- Query 5: Discount Band Analysis
-- ============================================================

SELECT
    CASE
        WHEN i.discount_pct = 0 THEN '0%'
        WHEN i.discount_pct < 0.05 THEN '0%–5%'
        WHEN i.discount_pct < 0.10 THEN '5%–10%'
        WHEN i.discount_pct < 0.15 THEN '10%–15%'
        WHEN i.discount_pct < 0.20 THEN '15%–20%'
        ELSE '20%+'
    END AS discount_band,
    COUNT(DISTINCT i.order_id) AS total_orders,
    SUM(i.quantity) AS units_sold,
    ROUND(SUM(i.gross_sales), 2) AS gross_sales,
    ROUND(SUM(i.discount_value), 2) AS discount_value,
    ROUND(SUM(i.revenue), 2) AS total_revenue,
    ROUND(SUM(i.contribution_profit), 2) AS contribution_profit,
    ROUND(
        100.0 * SUM(i.contribution_profit)
        / NULLIF(SUM(i.revenue), 0),
        2
    ) AS contribution_margin_pct,
    ROUND(
        SUM(i.revenue)
        / NULLIF(COUNT(DISTINCT i.order_id), 0),
        2
    ) AS revenue_per_order,
    ROUND(
        100.0 * SUM(i.revenue)
        / SUM(SUM(i.revenue)) OVER (),
        2
    ) AS revenue_share_pct
FROM salespulse.fact_order_items i
GROUP BY
    CASE
        WHEN i.discount_pct = 0 THEN '0%'
        WHEN i.discount_pct < 0.05 THEN '0%–5%'
        WHEN i.discount_pct < 0.10 THEN '5%–10%'
        WHEN i.discount_pct < 0.15 THEN '10%–15%'
        WHEN i.discount_pct < 0.20 THEN '15%–20%'
        ELSE '20%+'
    END
ORDER BY MIN(i.discount_pct);


-- ============================================================
-- Query 6A: Category Profitability
-- ============================================================

WITH category_sales AS (
    SELECT
        p.category,
        COUNT(DISTINCT p.product_id) AS product_count,
        COUNT(DISTINCT i.order_id) AS total_orders,
        SUM(i.quantity) AS units_sold,
        SUM(i.gross_sales) AS gross_sales,
        SUM(i.discount_value) AS discount_value,
        SUM(i.revenue) AS total_revenue,
        SUM(i.contribution_profit) AS contribution_profit
    FROM salespulse.fact_order_items i
    JOIN salespulse.dim_products p
        ON i.product_id = p.product_id
    GROUP BY p.category
),

category_returns AS (
    SELECT
        p.category,
        SUM(r.return_quantity) AS returned_units,
        SUM(r.refund_amount) AS refund_amount,
        SUM(r.refund_amount + r.restocking_cost) AS total_return_cost
    FROM salespulse.fact_returns r
    JOIN salespulse.dim_products p
        ON r.product_id = p.product_id
    GROUP BY p.category
)

SELECT
    s.category,
    s.product_count,
    s.total_orders,
    s.units_sold,
    ROUND(s.total_revenue, 2) AS total_revenue,
    ROUND(s.contribution_profit, 2) AS contribution_profit,
    ROUND(
        100.0 * s.contribution_profit
        / NULLIF(s.total_revenue, 0),
        2
    ) AS contribution_margin_pct,
    ROUND(
        100.0 * s.discount_value
        / NULLIF(s.gross_sales, 0),
        2
    ) AS discount_rate_pct,
    ROUND(COALESCE(r.refund_amount, 0), 2) AS refund_amount,
    ROUND(COALESCE(r.total_return_cost, 0), 2) AS total_return_cost,
    ROUND(
        100.0 * COALESCE(r.returned_units, 0)
        / NULLIF(s.units_sold, 0),
        2
    ) AS return_rate_pct,
    ROUND(
        s.contribution_profit
        - COALESCE(r.total_return_cost, 0),
        2
    ) AS net_contribution_profit,
    ROUND(
        100.0 * s.total_revenue
        / SUM(s.total_revenue) OVER (),
        2
    ) AS revenue_share_pct
FROM category_sales s
LEFT JOIN category_returns r
    ON s.category = r.category
ORDER BY total_revenue DESC;


-- ============================================================
-- Query 6B: Product Profitability
-- ============================================================

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        p.brand,
        COUNT(DISTINCT i.order_id) AS total_orders,
        SUM(i.quantity) AS units_sold,
        SUM(i.gross_sales) AS gross_sales,
        SUM(i.discount_value) AS discount_value,
        SUM(i.revenue) AS total_revenue,
        SUM(i.contribution_profit) AS contribution_profit
    FROM salespulse.fact_order_items i
    JOIN salespulse.dim_products p
        ON i.product_id = p.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        p.brand
),

product_returns AS (
    SELECT
        r.product_id,
        SUM(r.return_quantity) AS returned_units,
        SUM(r.refund_amount) AS refund_amount,
        SUM(r.refund_amount + r.restocking_cost) AS total_return_cost
    FROM salespulse.fact_returns r
    GROUP BY r.product_id
),

product_metrics AS (
    SELECT
        s.product_id,
        s.product_name,
        s.category,
        s.subcategory,
        s.brand,
        s.total_orders,
        s.units_sold,
        ROUND(s.total_revenue, 2) AS total_revenue,
        ROUND(s.contribution_profit, 2) AS contribution_profit,
        ROUND(
            100.0 * s.contribution_profit
            / NULLIF(s.total_revenue, 0),
            2
        ) AS contribution_margin_pct,
        ROUND(
            100.0 * s.discount_value
            / NULLIF(s.gross_sales, 0),
            2
        ) AS discount_rate_pct,
        COALESCE(r.returned_units, 0) AS returned_units,
        ROUND(COALESCE(r.total_return_cost, 0), 2) AS total_return_cost,
        ROUND(
            100.0 * COALESCE(r.returned_units, 0)
            / NULLIF(s.units_sold, 0),
            2
        ) AS return_rate_pct,
        ROUND(
            s.contribution_profit
            - COALESCE(r.total_return_cost, 0),
            2
        ) AS net_contribution_profit,
        ROUND(
            100.0 * (
                s.contribution_profit
                - COALESCE(r.total_return_cost, 0)
            )
            / NULLIF(s.total_revenue, 0),
            2
        ) AS net_contribution_margin_pct
    FROM product_sales s
    LEFT JOIN product_returns r
        ON s.product_id = r.product_id
),

thresholds AS (
    SELECT
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY total_revenue)
            AS median_product_revenue,
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY net_contribution_margin_pct)
            AS median_net_margin
    FROM product_metrics
)

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.total_orders,
    p.units_sold,
    p.total_revenue,
    p.contribution_profit,
    p.contribution_margin_pct,
    p.discount_rate_pct,
    p.return_rate_pct,
    p.total_return_cost,
    p.net_contribution_profit,
    p.net_contribution_margin_pct,
    CASE
        WHEN p.total_revenue >= t.median_product_revenue
         AND p.net_contribution_margin_pct >= t.median_net_margin
            THEN 'High Revenue / High Margin'
        WHEN p.total_revenue >= t.median_product_revenue
         AND p.net_contribution_margin_pct < t.median_net_margin
            THEN 'High Revenue / Low Margin'
        WHEN p.total_revenue < t.median_product_revenue
         AND p.net_contribution_margin_pct >= t.median_net_margin
            THEN 'Low Revenue / High Margin'
        ELSE 'Low Revenue / Low Margin'
    END AS product_portfolio_group
FROM product_metrics p
CROSS JOIN thresholds t
ORDER BY p.total_revenue DESC
LIMIT 25;


-- ============================================================
-- Query 7: Return Cost Drivers
-- ============================================================

WITH category_channel_sales AS (
    SELECT
        p.category,
        o.channel,
        SUM(i.quantity) AS units_sold
    FROM salespulse.fact_order_items i
    JOIN salespulse.fact_orders o
        ON i.order_id = o.order_id
    JOIN salespulse.dim_products p
        ON i.product_id = p.product_id
    GROUP BY
        p.category,
        o.channel
),

return_summary AS (
    SELECT
        p.category,
        o.channel,
        r.return_reason,
        SUM(r.return_quantity) AS returned_units,
        SUM(r.refund_amount) AS refund_amount,
        SUM(r.restocking_cost) AS restocking_cost,
        SUM(r.refund_amount + r.restocking_cost) AS total_return_cost
    FROM salespulse.fact_returns r
    JOIN salespulse.fact_orders o
        ON r.order_id = o.order_id
    JOIN salespulse.dim_products p
        ON r.product_id = p.product_id
    GROUP BY
        p.category,
        o.channel,
        r.return_reason
),

return_metrics AS (
    SELECT
        r.category,
        r.channel,
        r.return_reason,
        s.units_sold,
        r.returned_units,
        ROUND(r.refund_amount, 2) AS refund_amount,
        ROUND(r.restocking_cost, 2) AS restocking_cost,
        ROUND(r.total_return_cost, 2) AS total_return_cost,
        ROUND(
            100.0 * r.returned_units
            / NULLIF(s.units_sold, 0),
            2
        ) AS reason_return_rate_pct,
        ROUND(
            r.refund_amount
            / NULLIF(r.returned_units, 0),
            2
        ) AS average_refund_per_returned_unit,
        ROUND(
            100.0 * r.total_return_cost
            / SUM(r.total_return_cost) OVER (),
            2
        ) AS company_return_cost_share_pct,
        ROUND(
            100.0 * r.total_return_cost
            / SUM(r.total_return_cost)
                OVER (PARTITION BY r.category, r.channel),
            2
        ) AS reason_share_within_category_channel_pct
    FROM return_summary r
    JOIN category_channel_sales s
        ON r.category = s.category
       AND r.channel = s.channel
)

SELECT
    category,
    channel,
    return_reason,
    units_sold,
    returned_units,
    refund_amount,
    restocking_cost,
    total_return_cost,
    reason_return_rate_pct,
    average_refund_per_returned_unit,
    company_return_cost_share_pct,
    reason_share_within_category_channel_pct
FROM return_metrics
ORDER BY total_return_cost DESC
LIMIT 20;


-- ============================================================
-- Query 8: Customer Concentration
-- ============================================================

WITH customer_summary AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        c.loyalty_tier,
        c.acquisition_channel,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(i.quantity) AS units_sold,
        SUM(i.revenue) AS total_revenue,
        SUM(i.contribution_profit) AS contribution_profit,
        SUM(i.discount_value) AS discount_value,
        SUM(i.gross_sales) AS gross_sales
    FROM salespulse.fact_orders o
    JOIN salespulse.fact_order_items i
        ON o.order_id = i.order_id
    JOIN salespulse.dim_customers c
        ON o.customer_id = c.customer_id
    GROUP BY
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        c.loyalty_tier,
        c.acquisition_channel
),

customer_returns AS (
    SELECT
        o.customer_id,
        SUM(r.refund_amount) AS refund_amount,
        SUM(r.refund_amount + r.restocking_cost) AS total_return_cost
    FROM salespulse.fact_returns r
    JOIN salespulse.fact_orders o
        ON r.order_id = o.order_id
    GROUP BY o.customer_id
),

customer_metrics AS (
    SELECT
        s.customer_id,
        s.customer_name,
        s.customer_segment,
        s.loyalty_tier,
        s.acquisition_channel,
        s.total_orders,
        s.units_sold,
        ROUND(s.total_revenue, 2) AS total_revenue,
        ROUND(s.contribution_profit, 2) AS contribution_profit,
        ROUND(
            s.contribution_profit
            - COALESCE(r.total_return_cost, 0),
            2
        ) AS net_contribution_profit,
        ROUND(
            100.0 * (
                s.contribution_profit
                - COALESCE(r.total_return_cost, 0)
            )
            / NULLIF(s.total_revenue, 0),
            2
        ) AS net_contribution_margin_pct,
        ROUND(
            100.0 * s.discount_value
            / NULLIF(s.gross_sales, 0),
            2
        ) AS discount_rate_pct,
        ROUND(COALESCE(r.total_return_cost, 0), 2) AS total_return_cost
    FROM customer_summary s
    LEFT JOIN customer_returns r
        ON s.customer_id = r.customer_id
),

ranked_customers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY total_revenue DESC
        ) AS revenue_rank,
        SUM(total_revenue) OVER () AS company_revenue,
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue
    FROM customer_metrics
),

customer_groups AS (
    SELECT
        CASE
            WHEN revenue_rank <= 100 THEN 'Top 100 Customers'
            WHEN revenue_rank <= 500 THEN 'Customers 101–500'
            WHEN revenue_rank <= 1000 THEN 'Customers 501–1000'
            ELSE 'Remaining Customers'
        END AS customer_group,
        COUNT(*) AS customer_count,
        SUM(total_orders) AS total_orders,
        SUM(units_sold) AS units_sold,
        SUM(total_revenue) AS total_revenue,
        SUM(contribution_profit) AS contribution_profit,
        SUM(net_contribution_profit) AS net_contribution_profit,
        AVG(net_contribution_margin_pct) AS avg_net_contribution_margin_pct,
        AVG(discount_rate_pct) AS avg_discount_rate_pct,
        SUM(total_return_cost) AS total_return_cost,
        MAX(cumulative_revenue / company_revenue) AS cumulative_revenue_share
    FROM ranked_customers
    GROUP BY
        CASE
            WHEN revenue_rank <= 100 THEN 'Top 100 Customers'
            WHEN revenue_rank <= 500 THEN 'Customers 101–500'
            WHEN revenue_rank <= 1000 THEN 'Customers 501–1000'
            ELSE 'Remaining Customers'
        END
)

SELECT
    customer_group,
    customer_count,
    total_orders,
    units_sold,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(net_contribution_profit, 2) AS net_contribution_profit,
    ROUND(
        100.0 * net_contribution_profit
        / NULLIF(total_revenue, 0),
        2
    ) AS net_contribution_margin_pct,
    ROUND(avg_discount_rate_pct, 2) AS avg_discount_rate_pct,
    ROUND(total_return_cost, 2) AS total_return_cost,
    ROUND(
        100.0 * total_revenue
        / SUM(total_revenue) OVER (),
        2
    ) AS revenue_share_pct,
    ROUND(
        100.0 * cumulative_revenue_share,
        2
    ) AS cumulative_revenue_share_pct
FROM customer_groups
ORDER BY
    CASE
        WHEN customer_group = 'Top 100 Customers' THEN 1
        WHEN customer_group = 'Customers 101–500' THEN 2
        WHEN customer_group = 'Customers 501–1000' THEN 3
        ELSE 4
    END;


-- ============================================================
-- Query 9: Sales Rep Target Performance
-- ============================================================

WITH rep_month_actuals AS (
    SELECT
        o.sales_rep_id,
        TO_CHAR(o.order_date, 'YYYY-MM') AS year_month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(i.quantity) AS units_sold,
        SUM(i.gross_sales) AS gross_sales,
        SUM(i.discount_value) AS discount_value,
        SUM(i.revenue) AS total_revenue,
        SUM(i.contribution_profit) AS contribution_profit
    FROM salespulse.fact_orders o
    JOIN salespulse.fact_order_items i
        ON o.order_id = i.order_id
    GROUP BY
        o.sales_rep_id,
        TO_CHAR(o.order_date, 'YYYY-MM')
),

rep_month_returns AS (
    SELECT
        o.sales_rep_id,
        TO_CHAR(o.order_date, 'YYYY-MM') AS year_month,
        SUM(r.refund_amount + r.restocking_cost) AS total_return_cost
    FROM salespulse.fact_returns r
    JOIN salespulse.fact_orders o
        ON r.order_id = o.order_id
    GROUP BY
        o.sales_rep_id,
        TO_CHAR(o.order_date, 'YYYY-MM')
),

rep_summary AS (
    SELECT
        sr.sales_rep_id,
        sr.sales_rep_name,
        sr.region,
        sr.experience_level,
        SUM(a.total_orders) AS total_orders,
        SUM(a.units_sold) AS units_sold,
        SUM(a.total_revenue) AS total_revenue,
        SUM(t.revenue_target) AS revenue_target,
        SUM(a.contribution_profit) AS contribution_profit,
        SUM(t.profit_target) AS profit_target,
        SUM(a.contribution_profit)
            - COALESCE(SUM(r.total_return_cost), 0) AS net_contribution_profit,
        SUM(a.gross_sales) AS gross_sales,
        SUM(a.discount_value) AS discount_value,
        COALESCE(SUM(r.total_return_cost), 0) AS total_return_cost
    FROM rep_month_actuals a
    JOIN salespulse.fact_sales_targets t
        ON a.sales_rep_id = t.sales_rep_id
       AND a.year_month = t.year_month
    JOIN salespulse.dim_sales_reps sr
        ON a.sales_rep_id = sr.sales_rep_id
    LEFT JOIN rep_month_returns r
        ON a.sales_rep_id = r.sales_rep_id
       AND a.year_month = r.year_month
    GROUP BY
        sr.sales_rep_id,
        sr.sales_rep_name,
        sr.region,
        sr.experience_level
)

SELECT
    sales_rep_id,
    sales_rep_name,
    region,
    experience_level,
    total_orders,
    units_sold,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(revenue_target, 2) AS revenue_target,
    ROUND(
        100.0 * total_revenue
        / NULLIF(revenue_target, 0),
        2
    ) AS revenue_attainment_pct,
    ROUND(net_contribution_profit, 2) AS net_contribution_profit,
    ROUND(profit_target, 2) AS profit_target,
    ROUND(
        100.0 * net_contribution_profit
        / NULLIF(profit_target, 0),
        2
    ) AS profit_attainment_pct,
    ROUND(
        100.0 * net_contribution_profit
        / NULLIF(total_revenue, 0),
        2
    ) AS net_contribution_margin_pct,
    ROUND(
        100.0 * discount_value
        / NULLIF(gross_sales, 0),
        2
    ) AS discount_rate_pct,
    ROUND(total_return_cost, 2) AS total_return_cost,
    CASE
        WHEN total_revenue >= revenue_target
         AND net_contribution_profit >= profit_target
            THEN 'Met Revenue and Profit Targets'
        WHEN total_revenue >= revenue_target
         AND net_contribution_profit < profit_target
            THEN 'Met Revenue / Missed Profit'
        WHEN total_revenue < revenue_target
         AND net_contribution_profit >= profit_target
            THEN 'Missed Revenue / Met Profit'
        ELSE 'Missed Revenue and Profit Targets'
    END AS performance_group
FROM rep_summary
ORDER BY profit_attainment_pct ASC;


-- ============================================================
-- Query 10: Opportunity Quantification
-- ============================================================

WITH sales_base AS (
    SELECT
        o.order_id,
        o.order_date,
        o.channel,
        l.region,
        c.customer_id,
        c.customer_segment,
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        i.quantity,
        i.gross_sales,
        i.discount_value,
        i.revenue,
        i.contribution_profit,
        i.discount_pct
    FROM salespulse.fact_orders o
    JOIN salespulse.fact_order_items i
        ON o.order_id = i.order_id
    JOIN salespulse.dim_products p
        ON i.product_id = p.product_id
    JOIN salespulse.dim_customers c
        ON o.customer_id = c.customer_id
    JOIN salespulse.dim_locations l
        ON o.location_id = l.location_id
),

returns_base AS (
    SELECT
        o.order_id,
        o.channel,
        l.region,
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        r.return_reason,
        r.return_quantity,
        r.refund_amount,
        r.restocking_cost,
        r.refund_amount + r.restocking_cost AS total_return_cost
    FROM salespulse.fact_returns r
    JOIN salespulse.fact_orders o
        ON r.order_id = o.order_id
    JOIN salespulse.dim_products p
        ON r.product_id = p.product_id
    JOIN salespulse.dim_locations l
        ON o.location_id = l.location_id
),

customer_revenue_rank AS (
    SELECT
        customer_id,
        SUM(revenue) AS customer_revenue,
        ROW_NUMBER() OVER (
            ORDER BY SUM(revenue) DESC
        ) AS revenue_rank
    FROM sales_base
    GROUP BY customer_id
),

product_metrics AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(revenue) AS product_revenue,
        SUM(contribution_profit) AS product_contribution_profit,
        SUM(discount_value) AS product_discount_value,
        SUM(gross_sales) AS product_gross_sales,
        SUM(contribution_profit)
            - COALESCE((
                SELECT SUM(rb.total_return_cost)
                FROM returns_base rb
                WHERE rb.product_id = sb.product_id
            ), 0) AS product_net_contribution_profit
    FROM sales_base sb
    GROUP BY
        product_id,
        product_name,
        category
),

company_margin AS (
    SELECT
        SUM(contribution_profit) / NULLIF(SUM(revenue), 0) AS company_contribution_margin
    FROM sales_base
),

opportunity_rows AS (
    SELECT
        'Low-margin product review' AS opportunity_area,
        'High-revenue products with weak net contribution margin' AS business_driver,
        ROUND(SUM(product_revenue), 2) AS revenue_exposure,
        ROUND(SUM(product_revenue * cm.company_contribution_margin - product_net_contribution_profit), 2) AS value_exposure,
        ROUND(
            100.0 * SUM(product_net_contribution_profit)
            / NULLIF(SUM(product_revenue), 0),
            2
        ) AS current_margin_pct,
        'Gap between current net contribution profit and company-average margin benchmark' AS exposure_definition,
        25.00 AS conservative_scenario_pct,
        ROUND(
            SUM(product_revenue * cm.company_contribution_margin - product_net_contribution_profit) * 0.25,
            2
        ) AS estimated_opportunity,
        'Scenario assumes 25% of the gap to company-average margin can be recovered through pricing, cost, product mix, or return reduction.' AS interpretation
    FROM product_metrics pm
    CROSS JOIN company_margin cm
    WHERE product_revenue >= (
        SELECT PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY product_revenue)
        FROM product_metrics
    )
      AND product_net_contribution_profit / NULLIF(product_revenue, 0) < cm.company_contribution_margin

    UNION ALL

    SELECT
        'High-discount transactions',
        'Sales discounted above 15%',
        ROUND(SUM(revenue), 2),
        ROUND(SUM(discount_value), 2),
        ROUND(
            100.0 * SUM(contribution_profit)
            / NULLIF(SUM(revenue), 0),
            2
        ),
        'Discount value on transactions above 15%',
        10.00,
        ROUND(SUM(discount_value) * 0.10, 2),
        'Scenario assumes 10% reduction in discount leakage on high-discount transactions.'
    FROM sales_base
    WHERE discount_pct >= 0.15

    UNION ALL

    SELECT
        'Corporate Sales discount leakage',
        'Corporate Sales transactions discounted above 15%',
        ROUND(SUM(revenue), 2),
        ROUND(SUM(discount_value), 2),
        ROUND(
            100.0 * SUM(contribution_profit)
            / NULLIF(SUM(revenue), 0),
            2
        ),
        'Discount value on high-discount Corporate Sales transactions',
        10.00,
        ROUND(SUM(discount_value) * 0.10, 2),
        'Scenario assumes 10% reduction in excessive Corporate Sales discounts while protecting strategic accounts.'
    FROM sales_base
    WHERE channel = 'Corporate Sales'
      AND discount_pct >= 0.15

    UNION ALL

    SELECT
        'Top 500 customer discount review',
        'Discounts given to top 500 revenue customers',
        ROUND(SUM(sb.revenue), 2),
        ROUND(SUM(sb.discount_value), 2),
        ROUND(
            100.0 * SUM(sb.contribution_profit)
            / NULLIF(SUM(sb.revenue), 0),
            2
        ),
        'Discount value from top 500 customers by revenue',
        5.00,
        ROUND(SUM(sb.discount_value) * 0.05, 2),
        'Scenario assumes 5% reduction in discount leakage among large customers after protecting strategic accounts.'
    FROM sales_base sb
    JOIN customer_revenue_rank cr
        ON sb.customer_id = cr.customer_id
    WHERE cr.revenue_rank <= 500

    UNION ALL

    SELECT
        'South region discount leakage',
        'South-region transactions discounted above 15%',
        ROUND(SUM(revenue), 2),
        ROUND(SUM(discount_value), 2),
        ROUND(
            100.0 * SUM(contribution_profit)
            / NULLIF(SUM(revenue), 0),
            2
        ),
        'Discount value on high-discount South-region transactions',
        10.00,
        ROUND(SUM(discount_value) * 0.10, 2),
        'Scenario assumes 10% reduction in excessive South-region discounts.'
    FROM sales_base
    WHERE region = 'South'
      AND discount_pct >= 0.15

    UNION ALL

    SELECT
        'Electronics return-cost reduction',
        'Preventable Electronics return reasons',
        ROUND(SUM(refund_amount), 2),
        ROUND(SUM(total_return_cost), 2),
        NULL,
        'Return cost from Compatibility Issue, Defective, Not as Expected, and Damaged in Transit',
        10.00,
        ROUND(SUM(total_return_cost) * 0.10, 2),
        'Scenario assumes 10% reduction in preventable Electronics return costs through better product information, quality control, and packaging.'
    FROM returns_base
    WHERE category = 'Electronics'
      AND return_reason IN (
          'Compatibility Issue',
          'Defective',
          'Not as Expected',
          'Damaged in Transit'
      )
)

SELECT
    opportunity_area,
    business_driver,
    revenue_exposure,
    value_exposure,
    current_margin_pct,
    exposure_definition,
    conservative_scenario_pct,
    estimated_opportunity,
    interpretation
FROM opportunity_rows
ORDER BY estimated_opportunity DESC;
