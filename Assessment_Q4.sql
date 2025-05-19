-- Get total savings inflow and transaction count per user
WITH user_transactions AS (
    SELECT 
        owner_id,
        COUNT(*) AS total_transactions,
        SUM(confirmed_amount) / 100 AS total_transaction_value_naira  -- Convert from kobo to naira
    FROM savings_savingsaccount
    WHERE confirmed_amount > 0
    GROUP BY owner_id
),

-- Get each user's tenure since account creation (in months)
user_tenure AS (
    SELECT 
        id AS customer_id,
        CONCAT(first_name, ' ', last_name) AS name,
        TIMESTAMPDIFF(MONTH, created_on, CURDATE()) AS tenure_months
    FROM users_customuser
),

-- Calculate CLV using the simplified formula
clv_calc AS (
    SELECT 
        u.customer_id,
        u.name,
        u.tenure_months,
        COALESCE(t.total_transactions, 0) AS total_transactions,
        ROUND(
            (COALESCE(t.total_transactions, 0) / NULLIF(u.tenure_months, 0)) * 12 * 
            (0.001 * COALESCE(t.total_transaction_value_naira, 0) / NULLIF(t.total_transactions, 0)), 
        2) AS estimated_clv
    FROM user_tenure u
    LEFT JOIN user_transactions t ON u.customer_id = t.owner_id
)

-- Return and rank users by estimated CLV
SELECT * 
FROM clv_calc
ORDER BY estimated_clv DESC;