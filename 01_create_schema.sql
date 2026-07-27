-- ============================================================
-- SalesPulse 360
-- 01_create_schema.sql
-- Purpose: Create schema and tables for the SalesPulse 360 project
-- Database: PostgreSQL
-- ============================================================

DROP SCHEMA IF EXISTS salespulse CASCADE;
CREATE SCHEMA salespulse;
SET search_path TO salespulse;

CREATE TABLE dim_date (
    date_key DATE PRIMARY KEY,
    year INTEGER NOT NULL,
    quarter VARCHAR(2) NOT NULL,
    month_number INTEGER NOT NULL,
    month_name VARCHAR(12) NOT NULL,
    year_month VARCHAR(7) NOT NULL,
    week_of_year INTEGER NOT NULL,
    day_name VARCHAR(12) NOT NULL,
    is_weekend VARCHAR(3) NOT NULL
);

CREATE TABLE dim_locations (
    location_id VARCHAR(10) PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,
    region VARCHAR(20) NOT NULL,
    state VARCHAR(2) NOT NULL,
    city VARCHAR(50) NOT NULL,
    store_format VARCHAR(30) NOT NULL
);

CREATE TABLE dim_sales_reps (
    sales_rep_id VARCHAR(10) PRIMARY KEY,
    sales_rep_name VARCHAR(100) NOT NULL,
    region VARCHAR(20) NOT NULL,
    team VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    experience_level VARCHAR(20) NOT NULL,
    manager VARCHAR(100) NOT NULL
);

CREATE TABLE dim_customers (
    customer_id VARCHAR(12) PRIMARY KEY,
    customer_name VARCHAR(120) NOT NULL,
    customer_segment VARCHAR(30) NOT NULL,
    region VARCHAR(20) NOT NULL,
    state VARCHAR(2) NOT NULL,
    city VARCHAR(50) NOT NULL,
    customer_since DATE NOT NULL,
    acquisition_channel VARCHAR(30) NOT NULL,
    loyalty_tier VARCHAR(20) NOT NULL
);

CREATE TABLE dim_products (
    product_id VARCHAR(12) PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    unit_cost NUMERIC(12,2) NOT NULL,
    list_price NUMERIC(12,2) NOT NULL,
    supplier VARCHAR(50) NOT NULL,
    launch_date DATE NOT NULL,
    product_status VARCHAR(20) NOT NULL
);

CREATE TABLE fact_orders (
    order_id VARCHAR(15) PRIMARY KEY,
    order_date DATE NOT NULL REFERENCES dim_date(date_key),
    ship_date DATE NOT NULL,
    customer_id VARCHAR(12) NOT NULL REFERENCES dim_customers(customer_id),
    sales_rep_id VARCHAR(10) NOT NULL REFERENCES dim_sales_reps(sales_rep_id),
    location_id VARCHAR(10) NOT NULL REFERENCES dim_locations(location_id),
    channel VARCHAR(30) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    promotion_type VARCHAR(30) NOT NULL,
    shipping_cost NUMERIC(12,2) NOT NULL,
    order_status VARCHAR(20) NOT NULL
);

CREATE TABLE fact_order_items (
    order_line_id VARCHAR(16) PRIMARY KEY,
    order_id VARCHAR(15) NOT NULL REFERENCES fact_orders(order_id),
    product_id VARCHAR(12) NOT NULL REFERENCES dim_products(product_id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    discount_pct NUMERIC(8,4) NOT NULL,
    gross_sales NUMERIC(14,2) NOT NULL,
    discount_value NUMERIC(14,2) NOT NULL,
    revenue NUMERIC(14,2) NOT NULL,
    cogs NUMERIC(14,2) NOT NULL,
    allocated_shipping NUMERIC(14,2) NOT NULL,
    contribution_profit NUMERIC(14,2) NOT NULL
);

CREATE TABLE fact_returns (
    return_id VARCHAR(15) PRIMARY KEY,
    order_line_id VARCHAR(16) NOT NULL REFERENCES fact_order_items(order_line_id),
    order_id VARCHAR(15) NOT NULL REFERENCES fact_orders(order_id),
    product_id VARCHAR(12) NOT NULL REFERENCES dim_products(product_id),
    return_date DATE NOT NULL,
    return_quantity INTEGER NOT NULL,
    return_reason VARCHAR(50) NOT NULL,
    refund_amount NUMERIC(14,2) NOT NULL,
    restocking_cost NUMERIC(14,2) NOT NULL
);

CREATE TABLE fact_sales_targets (
    target_id VARCHAR(15) PRIMARY KEY,
    year_month VARCHAR(7) NOT NULL,
    sales_rep_id VARCHAR(10) NOT NULL REFERENCES dim_sales_reps(sales_rep_id),
    revenue_target NUMERIC(14,2) NOT NULL,
    profit_target NUMERIC(14,2) NOT NULL
);

CREATE INDEX idx_orders_order_date ON fact_orders(order_date);
CREATE INDEX idx_orders_customer ON fact_orders(customer_id);
CREATE INDEX idx_orders_rep ON fact_orders(sales_rep_id);
CREATE INDEX idx_items_order ON fact_order_items(order_id);
CREATE INDEX idx_items_product ON fact_order_items(product_id);
CREATE INDEX idx_returns_order_line ON fact_returns(order_line_id);
