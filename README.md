# 🏆 2026 World Cup Analytics Dashboard

[![Live App](https://img.shields.io/badge/Streamlit-Live%20Demo-FF4B4B?logo=streamlit)](https://wc2026-dashboard.streamlit.app/)

An interactive data dashboard built to predict tournament brackets and analyze match history for the 2026 World Cup.

## 🚀 Project Overview
This project transforms raw historical international match data into a clean analytical warehouse using **dbt (data build tool)** and surfaces predictive tournament insights via a single-page **Streamlit** dashboard. The core focus of this project is data quality, pipeline testing, and automated deduplication.

## 🛠 Tech Stack
* **Database:** PostgreSQL (Hosted via Supabase)
* **Transformation:** dbt (Core v1.12)
* **Frontend Dashboard:** Streamlit (`Home.py`)
* **Methodology:** Dimensional Modeling (Star Schema), Surrogate Key Hashing, and Window Function Deduplication.

## ⛓️ Data Architecture & Lineage
The project follows an ELT (Extract, Load, Transform) architecture. Using dbt, I established a clear data lineage path to ensure every metric on the dashboard can be traced back to its raw source.

![dbt Lineage Graph](wc2026-dashboard/lineage_graph.png)

## ⚙️ Key Engineering Features
* **Automated Deduplication:** Implemented `ROW_NUMBER() OVER (PARTITION BY ...)` window functions within the `fact_matches` pipeline to catch and squash duplicate match listings natively in the database.
* **Data & Referential Integrity:** Configured schema-level data tests (`unique`, `not_null`) alongside foreign key `relationships` tests to validate data quality before it hits the presentation layer.
* **Robust Surrogate Keys:** Utilized deterministic MD5 pipe-delimited hashing to generate immutable unique identifiers (`match_fact_id`) across unpivoted match perspectives.
* **Pure Separation of Concerns:** Left mathematical precision intact at the database layer (using Min-Max scaling for indices) and offloaded UI decimal formatting entirely to Streamlit's frontend engine to prevent rounding errors.

## 📂 Project Structure
```text
├── dbt_project/
│   ├── models/
│   │   ├── staging/    # Raw source cleanup and renaming views
│   │   ├── marts/      # Analytical dimensions, facts, and aggregated marts
│   │   └── schema.yml  # Data quality test definitions and YAML configurations
└── Home.py             # Main Streamlit dashboard entrypoint
