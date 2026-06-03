WITH all_teams AS (
    SELECT DISTINCT home_team AS team_name FROM {{ ref('stg_past_results') }}
    UNION
    SELECT DISTINCT away_team AS team_name FROM {{ ref('stg_past_results') }}
),

fixtures_teams AS (
    SELECT DISTINCT home_team AS team_name FROM {{ ref('stg_wc_fixtures') }} WHERE is_placeholder = FALSE
    UNION
    SELECT DISTINCT away_team AS team_name FROM {{ ref('stg_wc_fixtures') }} WHERE is_placeholder = FALSE
),

team_history_metadata AS (
    SELECT 
        home_team AS team_name,
        MIN(match_date) AS historic_debut_date,
        MIN(CASE WHEN is_world_cup = TRUE THEN EXTRACT(YEAR FROM match_date) END)::INT AS first_wc_year
    FROM {{ ref('stg_past_results') }}
    GROUP BY 1

    UNION ALL

    SELECT 
        away_team AS team_name,
        MIN(match_date) AS historic_debut_date,
        MIN(CASE WHEN is_world_cup = TRUE THEN EXTRACT(YEAR FROM match_date) END)::INT AS first_wc_year
    FROM {{ ref('stg_past_results') }}
    GROUP BY 1
),

final_metadata AS (
    SELECT 
        team_name,
        MIN(historic_debut_date) AS historic_debut_date,
        MIN(first_wc_year) AS first_world_cup_appearance_year
    FROM team_history_metadata
    GROUP BY 1
)

SELECT
    t.team_name,
    m.historic_debut_date,
    m.first_world_cup_appearance_year,
    CASE WHEN m.first_world_cup_appearance_year = 2026 THEN TRUE ELSE FALSE END AS is_wc_debutant,
    CASE WHEN f.team_name IS NOT NULL THEN TRUE ELSE FALSE END AS is_qualified_2026
FROM all_teams t
LEFT JOIN final_metadata m ON t.team_name = m.team_name
LEFT JOIN fixtures_teams f ON t.team_name = f.team_name