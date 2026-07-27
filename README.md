# SalesPulse 360: SQL + Power BI Business Performance Dashboard

## Project Overview

SalesPulse 360 is an end-to-end business analytics project built using PostgreSQL and Power BI. The project analyzes sales performance, profitability drivers, customer behavior, sales rep target attainment, and AI-assisted low-margin drivers across a synthetic omnichannel retail dataset.

The goal of this project is to demonstrate how SQL, Power BI, DAX, data modeling, and AI-assisted insights can be used to support business decision-making.

---

## Business Problem

The business wants to understand why revenue is growing while profitability is under pressure.

Key questions answered in this project:

- What is the overall sales and profitability performance?
- Which regions, channels, and product categories drive revenue?
- How do discounts affect profitability?
- Which customers and sales reps contribute the most to revenue?
- Are sales reps meeting revenue and profit targets?
- What factors are driving low-margin transactions?
- What business actions should leadership prioritize?

---

## Tools Used

- PostgreSQL
- SQL
- Power BI
- DAX
- Power BI Key Influencers
- Power BI Smart Narrative
- Data Modeling
- Business Analysis

---

## Dataset Overview

The project uses a synthetic omnichannel retail dataset containing sales, orders, products, customers, locations, returns, sales reps, and sales targets.

Main tables used:

- Customers
- Products
- Orders
- Order Items
- Returns
- Locations
- Sales Reps
- Sales Targets
- Date Table

---

## SQL Analysis

SQL was used to create the database structure, perform data quality checks, and answer business questions.

The SQL analysis included:

- Executive KPI baseline
- Yearly revenue and margin performance
- Regional performance
- Channel profitability
- Discount band analysis
- Category and product profitability
- Return cost drivers
- Customer concentration
- Sales rep target performance
- Opportunity quantification

SQL scripts are available in the `SQL` folder.

---

## Power BI Dashboard Pages

### Page 1: Executive Overview

This page provides a high-level view of business performance, including total revenue, contribution profit, margin, total orders, customers, average order value, units sold, and discount rate.

Key insight:

The business generated approximately $92.5M in revenue and $23.5M in contribution profit across 30,000 orders. Revenue increased over time, but contribution margin declined, indicating profitability pressure.

---

### Page 2: Profitability Drivers

This page analyzes product category performance, discount impact, and top product profitability.

Key insight:

Electronics generated the highest revenue, but had weaker margin performance compared with categories like Apparel and Office Supplies. Higher discount bands were associated with lower profitability, especially transactions above 15% discount.

---

### Page 3: Customer and Sales Performance

This page analyzes customer segment performance, top customers, and sales rep target attainment.

Key insight:

Corporate customers generated the highest revenue. Sales reps showed strong revenue attainment overall, but profit attainment was weaker, showing that sales performance should be evaluated using both revenue and profitability metrics.

---

### Page 4: AI-Assisted Insights and Recommendations

This page uses Power BI Key Influencers to identify drivers of low-margin transactions.

Key insight:

Power BI’s Key Influencers analysis identified Electronics as the strongest driver of Low Margin, making products in this category 8.08x more likely to fall into the Low Margin group. The 20%+ discount band was also identified as a major low-margin driver.

---

## Dashboard Screenshots

### Data Model

![Data Model](Images/Model%20View.png)

### Page 1: Executive Overview

![Executive Overview](Images/Page%201%20Executive%20Overview.png)

### Page 2: Profitability Drivers

![Profitability Drivers](Images/Page%202%20Profitability%20Drivers.png)

### Page 3: Customer and Sales Performance

![Customer and Sales Performance](Images/Page%203%20Customer%20and%20Sales%20Performance.png)

### Page 4: AI-Assisted Insights

![AI-Assisted Insights](Images/Page%204%20AI-Assisted%20Insights.png)





## Key Business Findings

- Total revenue was approximately $92.5M.
- Contribution profit was approximately $23.5M.
- Contribution margin was 25.44%.
- Net contribution margin was 22.45%.
- Revenue grew year over year, but margin declined.
- Electronics drove the most revenue but had weaker margin performance.
- Higher discount bands reduced profitability.
- Corporate customers generated the highest revenue.
- Sales reps exceeded revenue targets overall, but profit attainment was lower.
- AI-assisted analysis identified Electronics and 20%+ discounts as major low-margin drivers.

---

## Recommended Business Actions

1. Review Electronics pricing and cost structure to improve margins.
2. Reduce unnecessary discounts above 20%.
3. Review Corporate Sales discounting because the channel drives strong revenue but has weaker profitability.
4. Investigate Electronics return drivers, especially defective and compatibility-related returns.
5. Evaluate sales reps using profit attainment, not only revenue attainment.

---

## Repository Structure

```text
SalesPulse-360-SQL-PowerBI-Dashboard
│
├── SQL
│   ├── 01_create_schema.sql
│   ├── 02_data_quality_checks.sql
│   ├── 03_salespulse_analysis_queries.sql
│   └── README_SQL.md
│
├── Power BI
│   ├── SalesPulse 360 Dashboard.pbix
│   └── SalesPulse 360 Dashboard.pdf
│
├── Insights
│   └── business_insights_summary.md
