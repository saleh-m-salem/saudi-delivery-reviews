USE DeliveryReviews;

SELECT app,
       COUNT(*) AS total_reviews,
       CAST(AVG(score * 1.0) AS DECIMAL(4,2)) AS avg_rating,
       CAST(100.0 * SUM(CASE WHEN score <= 2 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS pct_negative,
       CAST(100.0 * SUM(CASE WHEN score >= 4 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS pct_positive,
       CAST(100.0 * SUM(CASE WHEN replyContent IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS reply_rate
FROM reviews
GROUP BY app
ORDER BY avg_rating DESC;

-- Q1: What do customers complain about in each app? (% of negative reviews)
SELECT app,
       COUNT(*) AS negative_reviews,
       CAST(100.0 * SUM(CAST([Customer service]  AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS customer_service,
       CAST(100.0 * SUM(CAST(Price               AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS price,
       CAST(100.0 * SUM(CAST(Driver              AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS driver,
       CAST(100.0 * SUM(CAST([Payment & refund]  AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS payment_refund,
       CAST(100.0 * SUM(CAST(Delay               AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS delay,
       CAST(100.0 * SUM(CAST([Order issue]       AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS order_issue,
       CAST(100.0 * SUM(CAST(Offers              AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS offers,
       CAST(100.0 * SUM(CAST([Fraud accusations] AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS fraud,
       CAST(100.0 * SUM(CAST([App technical]     AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS app_technical,
       CAST(100.0 * SUM(CAST(Cancellation        AS INT)) / COUNT(*) AS DECIMAL(5,1)) AS cancellation
FROM reviews
WHERE score <= 2
GROUP BY app
ORDER BY app;

-- Q2: Did things change after Keeta entered Saudi Arabia (Sep 2024)?
SELECT app,
       CASE WHEN at < '2024-09-01' THEN '1) Before Keeta'
            WHEN at < '2025-08-01' THEN '2) Keeta - Saudi only'
            ELSE                        '3) Keeta - Gulf expansion' END AS period,
       COUNT(*) AS reviews,
       CAST(AVG(score * 1.0) AS DECIMAL(4,2)) AS avg_rating,
       CAST(100.0 * SUM(CASE WHEN score <= 2 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS pct_negative,
       CAST(100.0 * SUM(CASE WHEN score <= 2 AND Price = 1 THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN score <= 2 THEN 1 ELSE 0 END), 0) AS DECIMAL(5,1)) AS price_share_of_complaints
FROM reviews
GROUP BY app,
       CASE WHEN at < '2024-09-01' THEN '1) Before Keeta'
            WHEN at < '2025-08-01' THEN '2) Keeta - Saudi only'
            ELSE                        '3) Keeta - Gulf expansion' END
ORDER BY app, period;

-- Q3: Which app versions had the worst ratings? (versions with 100+ reviews)
WITH version_stats AS (
    SELECT app,
           reviewCreatedVersion AS version,
           COUNT(*) AS reviews,
           CAST(MIN(at) AS DATE) AS first_seen,
           CAST(AVG(score * 1.0) AS DECIMAL(4,2)) AS avg_rating
    FROM reviews
    WHERE reviewCreatedVersion IS NOT NULL
    GROUP BY app, reviewCreatedVersion
    HAVING COUNT(*) >= 100
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY app ORDER BY avg_rating ASC) AS worst_rank
    FROM version_stats
)
SELECT app, version, reviews, first_seen, avg_rating
FROM ranked
WHERE worst_rank <= 2
ORDER BY app, worst_rank;

-- Q4: How fast does each app reply? (only reviews that got a reply)
SELECT app,
       COUNT(*) AS replied_reviews,
       CAST(AVG(DATEDIFF(MINUTE, at, repliedAt) / 60.0) AS DECIMAL(6,1)) AS avg_hours_to_reply,
       CAST(100.0 * SUM(CASE WHEN DATEDIFF(HOUR, at, repliedAt) <= 24 THEN 1 ELSE 0 END)
            / COUNT(*) AS DECIMAL(5,1)) AS pct_within_24h
FROM reviews
WHERE repliedAt IS NOT NULL
  AND repliedAt >= at
GROUP BY app
ORDER BY pct_within_24h DESC;

-- Q5: Stars vs AI sentiment
SELECT score, ai_label, COUNT(*) AS reviews
FROM reviews
GROUP BY score, ai_label
ORDER BY score, ai_label;