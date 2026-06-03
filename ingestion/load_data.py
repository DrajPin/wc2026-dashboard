# IMPORTS
import pandas as pd
import requests
import json
from sqlalchemy import create_engine
from dotenv import load_dotenv
from urllib.parse import quote_plus
import os


# Load credentials from .env file
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
API_KEY = os.getenv("FOOTBALL_DATA_API_KEY")


# Connect to Postgres
DB_URL = (
    f"postgresql://{DB_USER}:{quote_plus(DB_PASSWORD)}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)
engine = create_engine(DB_URL)
print("Connected to Postgres successfully.")


# Load Kaggle international historical results CSV
print("Loading Kaggle international results...")
df_past_results = pd.read_csv("data/results.csv")
df_past_results.columns = df_past_results.columns.str.lower().str.replace(" ", "_")
df_past_results.to_sql(
    "past_results", engine, schema="raw", if_exists="replace", index=False
)
print(f"Successfully loaded {len(df_past_results)} international match results.")


# Load Kaggle former country names CSV
print("Loading former names of countries...")
df_former_names = pd.read_csv("data/former_names.csv")
df_former_names.columns = df_former_names.columns.str.lower().str.replace(" ", "_")
df_former_names.to_sql(
    "former_team_names", engine, schema="raw", if_exists="replace", index=False
)
print(f"Successfully loaded {len(df_former_names)} country names.")


# Load 2026 World Cup fixtures JSON from Github
print("Fetching 2026 WC fixtures from github...")
url = "https://raw.githubusercontent.com/openfootball/worldcup.json/refs/heads/master/2026/worldcup.json"
response = requests.get(url)
wc_data = response.json()

matches = []
for match in wc_data.get("matches", []):
    matches.append(
        {
            "round": match.get("round"),
            "date": match.get("date"),
            "time": match.get("time"),
            "home_team": match.get("team1"),
            "away_team": match.get("team2"),
            "group": match.get("group"),
            "ground": match.get("ground"),
            "home_score": None,
            "away_score": None,
        }
    )

df_fixtures = pd.DataFrame(matches)
df_fixtures.to_sql(
    "wc_2026_fixtures", engine, schema="raw", if_exists="replace", index=False
)
print(f"Successfully loaded {len(df_fixtures)} WC 2026 fixtures.")


print("\nAll data loaded successfully. Check pgAdmin to verify")
