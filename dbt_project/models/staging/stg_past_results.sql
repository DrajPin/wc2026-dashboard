WITH source AS (
    SELECT * FROM {{ source('raw', 'past_results') }}
),

team_map AS (
    SELECT * FROM {{ ref('team_name_mapping') }}
),

cleaned AS (
    SELECT
        date::DATE AS match_date,
        -- Standardise names using your seed mapping table
        COALESCE(map_home.standard_name, source.home_team) AS home_team,
        COALESCE(map_away.standard_name, source.away_team) AS away_team,
        home_score::INT AS home_score,
        away_score::INT AS away_score,
        tournament,
        
        -- Flag whether it is a World Cup match
        CASE 
            WHEN tournament ILIKE '%FIFA World Cup%' AND tournament NOT ILIKE '%qualification%' THEN TRUE 
            ELSE FALSE 
        END AS is_world_cup,

        -- Calculate the winner
        CASE 
            WHEN home_score > away_score THEN COALESCE(map_home.standard_name, source.home_team)
            WHEN away_score > home_score THEN COALESCE(map_away.standard_name, source.away_team)
            WHEN home_score = away_score THEN 'Draw'
            ELSE NULL
        END AS winner
    FROM source
    LEFT JOIN team_map AS map_home ON source.home_team = map_home.raw_name
    LEFT JOIN team_map AS map_away ON source.away_team = map_away.raw_name
)

SELECT 
    match_date,
    home_team,
    away_team,
    home_score,
    away_score,
    tournament,
    is_world_cup,
    winner
FROM cleaned
WHERE home_score IS NOT NULL AND away_score IS NOT NULL