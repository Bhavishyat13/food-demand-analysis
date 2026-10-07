# Meal Delivery Demand Analysis: Planning Stock Across 77 Kitchens

SQL analysis of 145 weeks of orders from a meal delivery company with 77 fulfilment centres and 51 meals, focused on one operations question:

**How much of each meal should each kitchen plan for, and what makes demand hard to predict?**

**Tools:** PostgreSQL 18, pgAdmin 4

---

## Key findings

**1. Three categories carry the business.**
Beverages, Rice Bowl and Sandwich make up **66% of the 119.6 million orders** and 56% of revenue. The top 10 of 51 meals account for 54% of all orders, and a single rice bowl (meal 2290) accounts for 8% on its own.

**2. High volume does not mean high value.**
Beverages are **34% of orders but only 23% of revenue**, earning about 182 per order against an overall average of 267. Pizza, Seafood and Fish earn roughly **twice the average per order**: Pizza is 6% of orders but 12% of revenue.

**3. Type B centres are the strongest performers.**
They average **13,983 orders per centre per week**, 26% more than Type A and 87% more than Type C. This lines up with operating area (4.8 vs 4.1 and 3.2).

**4. Promoted weeks sell several times more.**
Comparing each meal against its own normal weeks, email promotions lifted orders by **+291% to +346%** for Rice Bowl, Sandwich and Seafood, and homepage features by +263% to +374%. Extras and Biryani barely respond to homepage features (+12% and +19%) and were never promoted by email.

**5. The most promotion sensitive categories are the hardest to plan.**
Seafood, Sandwich, Rice Bowl and Pizza have the most volatile demand (coefficient of variation **0.81 to 1.15**), while Extras and Biryani are the steadiest (0.43 and 0.53). Across the 14 categories, promotion uplift and volatility are strongly correlated (r ≈ 0.9), which suggests promotions drive much of the week to week swing.

**6. Safety stock needs differ sharply by meal.**
For the 20 busiest centre and meal pairs over the last 26 weeks, beverage meal 1885 needs only a **12% to 28% buffer** above average demand, while rice bowls need **39% to 115%**. Sandwich 1971 at centre 43 needs a 250% buffer, a sign of a one off spike worth investigating before setting stock.

---

## Recommendations

1. **Share the promotion calendar with kitchen planning.** Forecast promoted and normal weeks separately, instead of holding permanent buffer stock to cover promotion spikes.
2. **Set safety stock by category.** Keep lean buffers for steady items like Beverages and Extras, and larger buffers for Rice Bowl, Sandwich and Seafood.
3. **Use promotions where they pay most.** Pizza and Seafood respond strongly to promotions and earn about twice the average per order.
4. **Review outliers before planning.** Pairs like Sandwich 1971 at centre 43 should be checked for one off events so they don't inflate future stock levels.

---

## Data

[Food Demand Forecasting dataset on Kaggle](https://www.kaggle.com/datasets/kannanaikkal/food-demand-forecasting)

| Table | Source file | Contents |
|---|---|---|
| `orders` | train.csv | 456,548 rows: week, centre, meal, checkout price, base price, email and homepage promotion flags, number of orders |
| `centers` | fulfilment_center_info.csv | 77 centres: city, region, centre type, operating area |
| `meals` | meal_info.csv | 51 meals: category, cuisine |

---

## Approach

| File | What it does |
|---|---|
| `01_setup.sql` | Creates the tables, imports the CSVs, adds primary and foreign keys, and builds a combined view (`orders_full`) with discount and revenue columns |
| `02_analysis.sql` | Answers 8 business questions, from overall size of the business to recommended stock levels |

**SQL techniques used:** joins and views, CTEs, window functions, `FILTER`, `STDDEV`, `HAVING`, type casting

**Method notes**
- **Promotion uplift** compares each meal's promoted weeks with its own unpromoted weeks, so popular meals don't distort the result.
- **Volatility** is the standard deviation divided by average weekly orders, measured per centre and meal pair with at least 52 weeks of history, because each kitchen plans separately.
- **Recommended stock** is average weekly demand plus 1.65 × standard deviation, which covers demand in about 95% of weeks.

---

## Limitations

- Promotion uplift shows an association, not proof of cause. Promoted weeks often include discounts, and email and homepage promotions can overlap.
- The safety stock formula assumes roughly normal demand and does not account for supplier lead times.
- The dataset has no stock, waste or cost data, and does not state a currency, so revenue is shown in the dataset's own price units.
- The link between promotion uplift and volatility is based on only 14 categories.

---

## About me

**Bhavishyat Jamwal**, MSc Business Analytics, University of Essex

Previously Inventory Management & Stock Controller at Calo, where I forecast daily kitchen demand and set reorder quantities. This project applies the same thinking at the scale of 77 kitchens.

[LinkedIn](https://www.linkedin.com/in/bhavishyat-jamwal)
