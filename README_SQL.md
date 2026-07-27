# SalesPulse 360 SQL Files

This folder contains the final SQL scripts for the SalesPulse 360 portfolio project.

## Files

1. `01_create_schema.sql`
   - Creates the `salespulse` schema and all nine project tables.
   - Use this before importing the CSV files.

2. `02_data_quality_checks.sql`
   - Checks row counts, duplicate keys, orphan records, invalid values, date logic, return quantities, and financial reconciliations.
   - Use this after importing the CSV files.

3. `03_salespulse_analysis_queries.sql`
   - Contains all final business analysis queries.
   - Covers executive KPIs, yearly trends, regions, channels, discounts, products, returns, customers, sales reps, and opportunity quantification.

## Important Notes

- Do not include your PostgreSQL password in any SQL file.
- These SQL files are proof of the technical analysis.
- The Power BI dashboard should connect to PostgreSQL separately.
- The opportunity estimates are overlapping opportunity pools and should not be added together as total savings.
