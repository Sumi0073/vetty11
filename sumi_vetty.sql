1. 
SELECT DATE_FORMAT(purchase_time, '%Y-%m') AS purchase_month, COUNT(*) AS purchase_count
FROM transactions
WHERE status <> 'refunded'
GROUP BY purchase_month;


-- +---------------+----------------+
-- | purchase_month | purchase_count |
-- +---------------+----------------+
-- | 2020-10       | 45             |
-- | 2020-11       | 30             |
-- +---------------+----------------+

 2. 
SELECT store_id, COUNT(transaction_id) AS order_count
FROM transactions
WHERE DATE_FORMAT(purchase_time, '%Y-%m') = '2020-10'
GROUP BY store_id
HAVING order_count >= 5;


-- +----------+-------------+
-- | store_id | order_count |
-- +----------+-------------+
-- | 101      | 7           |
-- | 202      | 6           |
-- +----------+-------------+

3. 
SELECT store_id, MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_time)) AS shortest_interval_min
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id;


-- +----------+---------------------+
-- | store_id | shortest_interval_min |
-- +----------+---------------------+
-- | 101      | 15                  |
-- | 202      | 30                  |
-- +----------+---------------------+

 4. 
SELECT t1.store_id, t1.transaction_id, t1.gross_transaction_value
FROM transactions t1
WHERE t1.purchase_time = (SELECT MIN(t2.purchase_time) FROM transactions t2 WHERE t1.store_id = t2.store_id);


-- +----------+---------------+----------------------+
-- | store_id | transaction_id | gross_transaction_value |
-- +----------+---------------+----------------------+
-- | 101      | 5001          | 250.50               |
-- | 202      | 5005          | 180.00               |
-- +----------+---------------+----------------------+

5. 
SELECT i.item_name, COUNT(*) AS order_count
FROM items i
JOIN transactions t ON i.transaction_id = t.transaction_id
WHERE t.buyer_id IN (
    SELECT buyer_id FROM transactions GROUP BY buyer_id HAVING MIN(purchase_time) = purchase_time
)
GROUP BY i.item_name
ORDER BY order_count DESC
LIMIT 1;


-- +------------+-------------+
-- | item_name  | order_count |
-- +------------+-------------+
-- | Widget A   | 10          |
-- +------------+-------------+

 6. 
SELECT transaction_id, purchase_time, refund_time,
    CASE WHEN TIMESTAMPDIFF(HOUR, purchase_time, refund_time) <= 72 THEN 'Processed' ELSE 'Not Processed' END AS refund_status
FROM transactions
WHERE refund_time IS NOT NULL;

-- +---------------+---------------------+---------------------+---------------+
-- | transaction_id | purchase_time      | refund_time         | refund_status |
-- +---------------+---------------------+---------------------+---------------+
-- | 6001          | 2020-10-05 10:00:00 | 2020-10-07 09:00:00 | Processed     |
-- | 6002          | 2020-10-05 11:00:00 | 2020-10-10 12:00:00 | Not Processed |
-- +---------------+---------------------+---------------------+---------------+

 7.
WITH ranked_purchases AS (
    SELECT transaction_id, buyer_id, purchase_time,
           RANK() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS purchase_rank
    FROM transactions
    WHERE status <> 'refunded'
)
SELECT transaction_id, buyer_id, purchase_time
FROM ranked_purchases
WHERE purchase_rank = 2;


-- +---------------+----------+---------------------+
-- | transaction_id | buyer_id | purchase_time      |
-- +---------------+----------+---------------------+
-- | 7002          | 3        | 2020-10-08 14:00:00 |
-- +---------------+----------+---------------------+

 8.
SELECT t1.buyer_id, t1.purchase_time
FROM transactions t1
WHERE (SELECT COUNT(*) FROM transactions t2 WHERE t2.buyer_id = t1.buyer_id AND t2.purchase_time < t1.purchase_time) = 1;


-- +----------+---------------------+
-- | buyer_id | purchase_time       |
-- +----------+---------------------+
-- | 3        | 2020-10-08 14:00:00 |
-- +----------+---------------------+