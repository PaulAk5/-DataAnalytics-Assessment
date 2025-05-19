-- Aggregate funded savings plans per user
WITH funded_savings AS (
    SELECT 
        s.owner_id,
        COUNT(DISTINCT s.plan_id) AS savings_count,        -- Count distinct savings plans to avoid overcounting deposits
        SUM(s.confirmed_amount) AS total_savings           -- Sum confirmed deposits 
    FROM savings_savingsaccount s
    JOIN plans_plan p ON s.plan_id = p.id
    WHERE 
        s.confirmed_amount > 0                             -- Only include funded transactions
        AND p.is_regular_savings = 1                       -- Only regular savings plans
    GROUP BY s.owner_id
),

-- Aggregate funded investment plans per user
funded_investments AS (
    SELECT 
        owner_id,
        COUNT(*) AS investment_count,                      -- Each row is already one investment plan
        SUM(amount) AS total_investments                   -- Sum investment plan amounts
    FROM plans_plan
    WHERE 
        amount > 0 
        AND is_a_fund = 1                                  -- Must be an investment-type plan
        AND is_deleted = 0                                 -- Plan must be active
        AND is_archived = 0
    GROUP BY owner_id
)

-- Combine results with user details
SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    s.savings_count,
    i.investment_count,
    ROUND((s.total_savings + i.total_investments) / 100, 2) AS total_deposits  -- Convert from kobo to naira
FROM users_customuser u
JOIN funded_savings s ON s.owner_id = u.id
JOIN funded_investments i ON i.owner_id = u.id
ORDER BY total_deposits DESC;
