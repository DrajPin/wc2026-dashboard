SELECT 
    match_year,
    COUNT(DISTINCT match_fact_id) AS total_games,
    ROUND(AVG(goals_scored + goals_conceded), 2) AS avg_goals_per_game
FROM {{ ref('fact_matches') }}
GROUP BY 1
ORDER BY match_year ASC