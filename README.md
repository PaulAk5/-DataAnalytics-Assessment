# Data Analyst Assessment

This repository contains a series of SQL queries developed to as an assessment for the Data Analyst position at Cowrywise as at 19th May, 2025. 

The queries address key operational, marketing, and financial questions by analyzing customer behaviors, transaction frequencies, and account activity across savings and investment products.


## How I Approached the Assessment Questions

### 1. **High-Value Customers with Multiple Products**
**Goal:** The business wants to identify customers who have both a savings and an investment plan (cross-selling opportunity).

**Why It Matters:**

This helps the growth team pinpoint users who are already cross-product active. A great segment for upsell or early adopter feedback loops.


**Approach:**
- Filtered savings data for confirmed inflows (`confirmed_amount > 0`) and validated the plans with `is_regular_savings = 1`
- Aggregated investment data using `amount > 0` and filtered for valid investment plans with `is_a_fund = 1`, excluding deleted/archived plans
- Joined both to `users_customuser`, calculated total deposits (in naira), and ranked users

**Challenges**
 - Savings plans often had multiple transactions — I avoided overcounting by using `COUNT(DISTINCT s.plan_id)`
- All monetary fields were in kobo — I converted to naira early in the logic
- I joined to `plans_plan` from the savings table to apply the savings-type constraint (`is_regular_savings = 1`)


### 2. **Transaction Frequency Segmentation**
**Goal:** The finance team wants to analyze how often customers transact to segment them (e.g., frequent vs. occasional users).

**Why It Matters**

This helps us understand behavioral patterns. Frequent users are great for referral campaigns, while low-frequency users might need reactivation nudges.

**Approach**
- Merged savings inflows and withdrawals using `UNION ALL`
- Used `TIMESTAMPDIFF(MONTH, MIN, MAX)` instead of `DATEDIFF / 30` to more accurately calculate a customer’s activity window
- Calculated average monthly transactions, then segmented accordingly:
  - High: ≥ 10/month
  - Medium: 3–9/month
  - Low: ≤ 2/month


**Challenges**
- For users with very short activity spans, I defaulted their tenure to 1 month to avoid divide-by-zero and inflated averages
- I excluded withdrawal records with `amount_withdrawn = 0` to keep the transaction pool clean 

### 3. **Inactive Account Detection**
**Goal:** The ops team wants to flag accounts with no inflow transactions for over one year.

**Why It Matters**

This query feeds directly into account re-engagement workflows and could help to automate dormant account flagging.

**Approach**
- For savings: found the latest `transaction_date` where `confirmed_amount > 0`
- For investments: used `created_on` as a proxy for last funding (since no funding transaction table existed), but applied strict filters (`is_a_fund = 1`, `amount > 0`, not archived/deleted)
- Calculated `inactivity_days` using `DATEDIFF(CURDATE(), last_transaction_date)` and filtered where > 365

**Challenges**
- No direct "last transaction" for investments, so I clearly documented that `created_on` is an approximation
- Ensured only **active** plans were evaluated (`is_deleted = 0`, `is_archived = 0`) to avoid false flags


### 4. **Customer Lifetime Value (CLV) Estimation**
**Goal:**  Marketing wants to estimate CLV based on account tenure and transaction volume (simplified model).

**Why It Matters**

This model allows to rank users by estimated value, useful for premium tier targeting, personalized engagement, and budget allocation.
CLV modeling also supports revenue forecasting and helps estimate the financial impact of growing user segments especially for investor reporting and strategic planning.

**Approach**

Calculated tenure using `TIMESTAMPDIFF(MONTH, created_on, CURDATE())`
- Aggregated confirmed inflows from savings and converted from kobo to naira
- Used the formula:  
  `CLV = (total_transactions / tenure_months) * 12 * avg_profit_per_transaction`,  
  where `avg_profit = 0.1%` of transaction value

**Challenges**
- I used `NULLIF(..., 0)` to avoid divide-by-zero issues
- Included all users (even with no transactions) using `LEFT JOIN`, so new customers would have a baseline CLV of 0
- The profit model is simplified but extensible — documented this clearly for future upgrades