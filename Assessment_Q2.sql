-- Combine all valid transaction dates (savings inflows and withdrawals)
WITH all_transactions AS (
    SELECT owner_id, transaction_date
    FROM savings_savingsaccount
    WHERE confirmed_amount > 0

    UNION ALL

    SELECT owner_id, transaction_date
    FROM withdrawals_withdrawal
    WHERE amount_withdrawn > 0
),

-- Aggregate total transactions and calculate active months
transactions_per_user AS (
    SELECT
        owner_id,
        COUNT(*) AS total_transactions,
        TIMESTAMPDIFF(MONTH, MIN(transaction_date), MAX(transaction_date)) AS active_months
    FROM all_transactions
    GROUP BY owner_id
),

-- Compute average transactions per month
average_transactions AS (
    SELECT
        owner_id,
        CASE 
            WHEN active_months < 1 THEN 1                     -- Prevent divide-by-zero issues for short-tenure users
            ELSE active_months
        END AS months_active,
        ROUND(total_transactions / 
            CASE 
                WHEN active_months < 1 THEN 1 
                ELSE active_months 
            END, 1) AS avg_transactions_per_month
    FROM transactions_per_user
),

-- Segment users by frequency category
frequency_segmented AS (
    SELECT
        CASE
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
            WHEN avg_transactions_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        avg_transactions_per_month
    FROM average_transactions
)

-- Aggregate segment-level insights
SELECT
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month
FROM frequency_segmented
GROUP BY frequency_category
ORDER BY 
    CASE 
        WHEN frequency_category = 'High Frequency' THEN 1
        WHEN frequency_category = 'Medium Frequency' THEN 2
        ELSE 3
    END;
