/* =====================================================================
   Food Demand Forecasting: Analysis Round 1
   Author: Bhavishyat Jamwal

   HOW TO USE
   Run ONE query at a time: highlight it, press F5, read the Data Output.
   Write what you notice under each "Notes:" line. These notes become
   the findings section of your GitHub README.
   ===================================================================== */


/* ---------------------------------------------------------------------
   Q1. How big is the business?
   SQL skills: COUNT, SUM, COUNT(DISTINCT)
   --------------------------------------------------------------------- */
SELECT
    COUNT(DISTINCT week)       AS weeks,
    COUNT(DISTINCT center_id)  AS centres,
    COUNT(DISTINCT meal_id)    AS meals,
    SUM(num_orders)            AS total_orders,
    ROUND(SUM(num_orders)::numeric / COUNT(DISTINCT week)) AS avg_orders_per_week,
    ROUND(SUM(revenue))        AS total_revenue
FROM orders_full;

-- Notes:


/* ---------------------------------------------------------------------
   Q2. How do total orders change week by week?
   SQL skills: GROUP BY, ORDER BY
   Tip: look for spikes, dips and whether demand grows over time.
   --------------------------------------------------------------------- */
SELECT
    week,
    SUM(num_orders) AS total_orders
FROM orders_full
GROUP BY week
ORDER BY week;

-- Notes:


/* ---------------------------------------------------------------------
   Q3. Which meal categories drive orders and revenue?
   SQL skills: window function SUM() OVER () for percentage of total
   --------------------------------------------------------------------- */
SELECT
    category,
    SUM(num_orders) AS total_orders,
    ROUND(100.0 * SUM(num_orders) / SUM(SUM(num_orders)) OVER (), 1) AS pct_of_orders,
    ROUND(SUM(revenue)) AS total_revenue,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct_of_revenue
FROM orders_full
GROUP BY category
ORDER BY total_orders DESC;

-- Notes: (does any category sell a lot but earn little, or the reverse?)


/* ---------------------------------------------------------------------
   Q4. Top 10 meals by orders
   SQL skills: GROUP BY several columns, LIMIT
   --------------------------------------------------------------------- */
SELECT
    meal_id,
    category,
    cuisine,
    SUM(num_orders)               AS total_orders,
    ROUND(AVG(checkout_price), 2) AS avg_price
FROM orders_full
GROUP BY meal_id, category, cuisine
ORDER BY total_orders DESC
LIMIT 10;

-- Notes:


/* ---------------------------------------------------------------------
   Q5. Do bigger centres sell more? (by centre type)
   SQL skills: CTE (WITH ... AS), aggregating an aggregate
   --------------------------------------------------------------------- */
WITH centre_totals AS (
    SELECT
        center_id,
        center_type,
        op_area,
        SUM(num_orders)::numeric / COUNT(DISTINCT week) AS avg_weekly_orders
    FROM orders_full
    GROUP BY center_id, center_type, op_area
)
SELECT
    center_type,
    COUNT(*)                       AS centres,
    ROUND(AVG(avg_weekly_orders))  AS avg_weekly_orders_per_centre,
    ROUND(AVG(op_area), 1)         AS avg_op_area
FROM centre_totals
GROUP BY center_type
ORDER BY avg_weekly_orders_per_centre DESC;

-- Notes:


/* ---------------------------------------------------------------------
   Q6. How much do promotions lift orders?
   Compares each meal against ITSELF (promoted weeks vs normal weeks),
   so popular meals don't distort the result.
   SQL skills: FILTER (WHERE ...), CTE, ratios
   Caveat: promoted weeks often also have discounts, so treat this as
   the combined effect of promotion + price.
   --------------------------------------------------------------------- */
WITH by_meal AS (
    SELECT
        meal_id,
        category,
        AVG(num_orders) FILTER (WHERE emailer_for_promotion = 0 AND homepage_featured = 0) AS avg_no_promo,
        AVG(num_orders) FILTER (WHERE emailer_for_promotion = 1) AS avg_email,
        AVG(num_orders) FILTER (WHERE homepage_featured = 1)     AS avg_homepage
    FROM orders_full
    GROUP BY meal_id, category
)
SELECT
    category,
    COUNT(*) AS meals,
    ROUND(AVG(avg_email    / avg_no_promo - 1) * 100) AS email_uplift_pct,
    ROUND(AVG(avg_homepage / avg_no_promo - 1) * 100) AS homepage_uplift_pct
FROM by_meal
WHERE avg_no_promo IS NOT NULL
GROUP BY category
ORDER BY email_uplift_pct DESC NULLS LAST;

-- Notes: (which channel works better, email or homepage? for which categories?)


/* ---------------------------------------------------------------------
   Q7. Which categories are hardest to plan for?
   Volatility = standard deviation / average (coefficient of variation)
     around 0.2 = steady demand, easy to plan
     around 1.0 = demand swings as much as its average, hard to plan
   Measured per centre and meal, because each kitchen plans separately.
   SQL skills: STDDEV, HAVING
   --------------------------------------------------------------------- */
WITH centre_meal AS (
    SELECT
        center_id,
        meal_id,
        category,
        COUNT(*)           AS weeks_sold,
        AVG(num_orders)    AS avg_orders,
        STDDEV(num_orders) AS sd_orders
    FROM orders_full
    GROUP BY center_id, meal_id, category
    HAVING COUNT(*) >= 52          -- at least a year of history
)
SELECT
    category,
    COUNT(*)                               AS centre_meal_pairs,
    ROUND(AVG(avg_orders))                 AS avg_weekly_orders,
    ROUND(AVG(sd_orders / avg_orders), 2)  AS avg_volatility
FROM centre_meal
GROUP BY category
ORDER BY avg_volatility DESC;

-- Notes:


/* ---------------------------------------------------------------------
   Q8. Recommended weekly stock level for the 20 busiest centre/meal pairs
   Uses the last 26 weeks only (most relevant for planning).
   Recommended stock = average demand + safety stock
   Safety stock = 1.65 x standard deviation, which covers demand in about
   95% of weeks if demand is roughly normally distributed.
   This is the Calo link: the same logic as setting reorder quantities.
   --------------------------------------------------------------------- */
WITH recent AS (
    SELECT
        center_id,
        meal_id,
        category,
        AVG(num_orders)    AS avg_orders,
        STDDEV(num_orders) AS sd_orders
    FROM orders_full
    WHERE week > (SELECT MAX(week) FROM orders) - 26
    GROUP BY center_id, meal_id, category
    HAVING COUNT(*) >= 20
)
SELECT
    center_id,
    meal_id,
    category,
    ROUND(avg_orders)                     AS avg_weekly_demand,
    ROUND(1.65 * sd_orders)               AS safety_stock,
    CEIL(avg_orders + 1.65 * sd_orders)   AS recommended_weekly_stock,
    ROUND(100 * 1.65 * sd_orders / avg_orders) AS buffer_pct
FROM recent
ORDER BY avg_orders DESC
LIMIT 20;

-- Notes: (which pairs need the biggest buffer relative to demand?)
