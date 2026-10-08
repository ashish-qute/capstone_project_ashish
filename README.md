# Mamaearth Growth Analytics: Return Rate & Margin Leakage Pipeline

This repository contains the end-to-end data pipeline built for Mamaearth's Growth Analytics team. The pipeline proves and quantifies how product returns and duplicate transactions erode operating margins,
feeding structured SQL data into a Python pandas analysis layer, which in turn feeds a verified GenAI-powered executive narrative layer.

---

## Repository Structure

```text
.
├── README.md                           # Front door: setup instructions & pipeline documentation
├── sql/
│   ├── schema.sql                      # DDL for MYSQL Workbench/SQLite database tables
│   ├── seed_data.sql                   # Data loading and null-cleansing SQL script
│   └── reports.sql                     # SQL analytical queries and verified output comments
├── data/
│   ├── customers.csv                   # Source customers data (45 rows)
│   ├── products.csv                    # Source products data (16 rows)
│   └── orders.csv                      # Source raw orders data (180 rows)
├── analysis/
│   ├── clean_and_eda.py                # Pandas cleaning, deduplication, IQR & EDA script
│   └── visualize.py                    # Matplotlib chart generation script
├── visualizations/
│   ├── return_rate_by_payment.png      # Bar chart: Return rate by payment method
│   └── monthly_revenue_trend.png       # Line chart: Outlier-corrected revenue trend
└── narrator/
    ├── findings.json                   # Automated JSON export of verified metrics
    ├── generate_narrative.py           # Gemini GenAI + deterministic offline narrative engine
    └── sample_output.txt               # Validated sample output narrative

## Step-by-Step Execution Guide

### Prerequisites

* **Python**: 3.9+
* **Database**: SQLite3 CLI or MySQL Workbench
* **Python Libraries**: `pandas`, `numpy`, `matplotlib`, `google-genai`

### Installation

Install all required Python dependencies:

```bash
pip install pandas numpy matplotlib google-genai

```

---

## Pipeline Execution

### Part 1: SQL Relational Layer & Reporting

#### 1. Initialize Database and Load Seed Data

Execute `schema.sql` and `seed_data.sql` in SQLite (or MySQL Workbench):

```bash
sqlite3 mamaearth.db < sql/schema.sql
sqlite3 mamaearth.db < sql/seed_data.sql

```

#### 2. Verification Counts

Run the following checks to confirm row counts:

```sql
SELECT COUNT(*) FROM customers; -- Expected: 45
SELECT COUNT(*) FROM products;  -- Expected: 16
SELECT COUNT(*) FROM orders;    -- Expected: 180

```

#### 3. Run Analytical Reports

Execute the analytical queries:

```bash
sqlite3 mamaearth.db < sql/reports.sql

```

> **Note:** All expected outputs and comments are documented directly below each query inside `sql/reports.sql`.

---

### Part 2: Python / Pandas Data Wrangling & EDA

#### 1. Run Cleaning and Analysis Pipeline

```bash
python analysis/clean_and_eda.py

```

**Execution Flow:**

* Cleans payment method casing (**CARD**: 70, **UPI**: 55, **COD**: 55).
* Drops 5 duplicate orders (`O0176`–`O0180`), reducing total row count from 180 to 175.
* Imputes missing `discount_pct` with `0` and missing `rating` with the median (`3.0`).
* Reconciles the total revenue delta (**₹2,501.90**) between raw (**₹99,860.20**) and clean (**₹97,358.30**).
* Flags bulk quantity outliers (`O0011` quantity 25; `O0098` quantity 30).
* Confirms high COD return rate (**44.4%**) and isolates the highest-risk segment (**COD + Tier-2 cities at 54.5%**).
* Generates and exports `narrator/findings.json`.

#### 2. Generate Visualizations

```bash
python analysis/visualize.py

```

**Outputs:**

* `visualizations/return_rate_by_payment.png`
* `visualizations/monthly_revenue_trend.png`

---

### Part 3: GenAI-Powered Insight Narrator

#### 1. Run Narrative Generator

**Online Mode (Gemini API):**
Set your API key as an environment variable and run:

```bash
export GEMINI_API_KEY="your-api-key-here"
python narrator/generate_narrative.py

```

**Offline Mode (Zero API Key / Fully Offline):**
If no API key is present or network calls fail, the script automatically uses the offline engine:

```bash
unset GEMINI_API_KEY
python narrator/generate_narrative.py

```

#### 2. Verification

The script asserts that all 5 mandatory metrics exist in the output narrative before saving the validated text to `narrator/sample_output.txt`:

1. Clean Revenue: **₹97,358.30**
2. COD Return Rate: **44.4%**
3. Tier-2 COD Return Rate: **54.5%**
4. Duplicate Revenue Delta: **₹2,501.90**
5. March Revenue: **₹20,318.90**

---

## Data Flow

```text
[data/*.csv] ──> [Part 1: SQLite Layer] ──> Reports & Verification
      │
      └──> [Part 2: analysis/clean_and_eda.py] ──> Clean, Deduplicate & Analyze
                        │
                        ├──> [visualizations/*.png]
                        └──> [Part 3: narrator/findings.json]
                                        │
                                        └──> [narrator/generate_narrative.py]
                                                        │
                                                        └──> [narrator/sample_output.txt]
