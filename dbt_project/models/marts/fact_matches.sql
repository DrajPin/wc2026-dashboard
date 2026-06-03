WITH base_matches AS (
    SELECT 
        match_date, tournament, is_world_cup, home_team AS team_name,
        away_team AS opponent_name, home_score AS goals_scored,
        away_score AS goals_conceded, 'Home' AS venue_status
    FROM {{ ref('stg_past_results') }}
    UNION ALL
    SELECT 
        match_date, tournament, is_world_cup, away_team AS team_name,
        home_team AS opponent_name, away_score AS goals_scored,
        home_score AS goals_conceded, 'Away' AS venue_status
    FROM {{ ref('stg_past_results') }}
),

ranked_matches AS (
    -- This assigns a rank of '1' to the first version of a match it sees.
    -- If there's a duplicate, it gets '2', '3', etc.
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY match_date, team_name, opponent_name, tournament 
               ORDER BY goals_scored DESC -- Keeps the record with the most goals if there's a conflict
           ) as row_rank
    FROM base_matches
)

-- Final SELECT: Only keep the rank 1 rows
SELECT 
    MD5(match_date::text || '|' || team_name || '|' || opponent_name || '|' || tournament) AS match_fact_id,
    match_date,
    EXTRACT(YEAR FROM match_date)::INT AS match_year,
    tournament,
    is_world_cup,
    team_name,
    opponent_name,
    goals_scored,
    goals_conceded,
    CASE 
        WHEN goals_scored > goals_conceded THEN 'Win'
        WHEN goals_scored < goals_conceded THEN 'Loss'
        ELSE 'Draw'
    END AS match_outcome,
    venue_status,
    (goals_scored - goals_conceded) AS goal_differential
FROM ranked_matches
WHERE row_rank = 1