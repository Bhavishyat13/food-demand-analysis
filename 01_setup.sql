/* =====================================================================
   Food Demand Forecasting: database setup
   Author: Bhavishyat Jamwal

   Creates the tables, imports the three CSVs from the Kaggle dataset,
   links the tables and builds the combined view orders_full.
   Safe to run more than once: it removes old versions first.

   Before running: put the CSVs in a folder PostgreSQL can read and
   update the three COPY file paths below to match.
   ===================================================================== */

-- 1. Remove everything made before
DROP VIEW IF EXISTS orders_full;
DROP TABLE IF EXISTS orders, centers, meals CASCADE;

-- 2. Create fresh empty tables
CREATE TABLE centers (
    center_id INTEGER PRIMARY KEY, city_code INTEGER, region_code INTEGER,
    center_type TEXT, op_area NUMERIC
);
CREATE TABLE meals (
    meal_id INTEGER PRIMARY KEY, category TEXT, cuisine TEXT
);
CREATE TABLE orders (
    id INTEGER PRIMARY KEY, week INTEGER, center_id INTEGER, meal_id INTEGER,
    checkout_price NUMERIC, base_price NUMERIC, emailer_for_promotion SMALLINT,
    homepage_featured SMALLINT, num_orders INTEGER
);

-- 3. Import the CSVs
COPY centers FROM 'C:/Users/Public/food-demand/fulfilment_center_info.csv' WITH (FORMAT csv, HEADER true);
COPY meals   FROM 'C:/Users/Public/food-demand/meal_info.csv'              WITH (FORMAT csv, HEADER true);
COPY orders  FROM 'C:/Users/Public/food-demand/train.csv'                  WITH (FORMAT csv, HEADER true);

-- 4. Link the tables
ALTER TABLE orders ADD CONSTRAINT fk_orders_center FOREIGN KEY (center_id) REFERENCES centers (center_id);
ALTER TABLE orders ADD CONSTRAINT fk_orders_meal   FOREIGN KEY (meal_id)   REFERENCES meals (meal_id);
CREATE INDEX idx_orders_center_meal_week ON orders (center_id, meal_id, week);

-- 5. Combined view
CREATE VIEW orders_full AS
SELECT o.id, o.week, o.center_id, c.center_type, c.region_code, c.city_code, c.op_area,
       o.meal_id, m.category, m.cuisine, o.checkout_price, o.base_price,
       ROUND((o.base_price - o.checkout_price) / NULLIF(o.base_price, 0) * 100, 1) AS discount_pct,
       o.emailer_for_promotion, o.homepage_featured, o.num_orders,
       ROUND(o.checkout_price * o.num_orders, 2) AS revenue
FROM orders o
JOIN centers c ON c.center_id = o.center_id
JOIN meals   m ON m.meal_id   = o.meal_id;

-- 6. Check: expect 77, 51 and about 456,000
SELECT 'centers' AS table_name, COUNT(*) AS row_count FROM centers
UNION ALL SELECT 'meals', COUNT(*) FROM meals
UNION ALL SELECT 'orders', COUNT(*) FROM orders;
