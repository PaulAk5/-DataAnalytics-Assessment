-- Latest savings inflow per plan
WITH latest_savings AS (
    SELECT 
        s.plan_id,
        s.owner_id,
        MAX(s.transaction_date) AS last_transaction_date
    FROM savings_savingsaccount s
    JOIN plans_plan p ON s.plan_id = p.id
    WHERE 
        s.confirmed_amount > 0                  -- Must be an actual inflow
        AND p.is_regular_savings = 1            -- Only regular savings plans
        AND p.is_deleted = 0 
        AND p.is_archived = 0
    GROUP BY s.plan_id, s.owner_id
),

-- Latest investment funding date per plan (based on created_on for simplicity)
latest_investments AS (
    SELECT 
        p.id AS plan_id,
        p.owner_id,
        p.created_on AS last_transaction_date
    FROM plans_plan p
    WHERE 
        p.amount > 0                            -- Funded investment
        AND p.is_a_fund = 1                     -- Must be an investment plan
        AND p.is_deleted = 0 
        AND p.is_archived = 0
),

-- Savings plans inactive for over 1 year
inactive_savings AS (
    SELECT 
        plan_id,
        owner_id,
        'Savings' AS type,
        last_transaction_date,
        DATEDIFF(CURDATE(), last_transaction_date) AS inactivity_days
    FROM latest_savings
    WHERE DATEDIFF(CURDATE(), last_transaction_date) > 365
),

-- Investment plans inactive for over 1 year
inactive_investments AS (
    SELECT 
        plan_id,
        owner_id,
        'Investment' AS type,
        last_transaction_date,
        DATEDIFF(CURDATE(), last_transaction_date) AS inactivity_days
    FROM latest_investments
    WHERE DATEDIFF(CURDATE(), last_transaction_date) > 365
)

-- Combine results
SELECT * 
FROM inactive_savings
UNION ALL
SELECT * 
FROM inactive_investments
ORDER BY inactivity_days DESC;