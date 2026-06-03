WITH source AS (
    SELECT * FROM {{ source('raw', 'wc_2026_fixtures') }}
),

team_map AS (
    SELECT * FROM {{ ref('team_name_mapping') }}
),

cleaned AS (
    SELECT
        round,
        date::DATE AS match_date,
        COALESCE(map_home.standard_name, source.home_team) AS home_team,
        COALESCE(map_away.standard_name, source.away_team) AS away_team,
        "group" AS group_name,
        ground,
        home_score::INT AS home_score,
        away_score::INT AS away_score,

        CASE
            WHEN home_score > away_score THEN COALESCE(map_home.standard_name, source.home_team)
            WHEN away_score > home_score THEN COALESCE(map_away.standard_name, source.away_team)
            WHEN home_score = away_score AND home_score IS NOT NULL THEN 'Draw'
            ELSE NULL
        END AS winner,

        CASE
            WHEN home_score IS NOT NULL THEN 'FINISHED'
            ELSE 'SCHEDULED'
        END AS status,

        CASE 
            WHEN source.home_team SIMILAR TO '[0-9][A-L]' 
              OR source.home_team LIKE 'W%' 
              OR source.home_team LIKE 'L%'
              OR source.away_team LIKE '%/%' THEN TRUE
            ELSE FALSE
        END AS is_placeholder

    FROM source
    LEFT JOIN team_map AS map_home ON source.home_team = map_home.raw_name
    LEFT JOIN team_map AS map_away ON source.away_team = map_away.raw_name
)

SELECT *
FROM cleaned