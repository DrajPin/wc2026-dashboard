WITH current_groups AS (
    SELECT DISTINCT group_name, home_team AS team_name FROM {{ ref('stg_wc_fixtures') }} WHERE group_name IS NOT NULL AND is_placeholder = FALSE
    UNION
    SELECT DISTINCT group_name, away_team AS team_name FROM {{ ref('stg_wc_fixtures') }} WHERE group_name IS NOT NULL AND is_placeholder = FALSE
),

historical_metrics AS (
    SELECT 
        team_name,
        COUNT(DISTINCT CASE WHEN is_world_cup = TRUE THEN match_year END) AS total_wc_appearances,
        
        ROUND((COUNT(CASE WHEN match_date >= '2018-01-01' AND match_outcome = 'Win' THEN 1 END)::NUMERIC / 
            NULLIF(COUNT(CASE WHEN match_date >= '2018-01-01' THEN 1 END), 0)) * 100, 1) AS modern_win_rate_pct,

        ROUND((COUNT(CASE WHEN match_date >= '2018-01-01' AND match_outcome = 'Draw' THEN 1 END)::NUMERIC / 
            NULLIF(COUNT(CASE WHEN match_date >= '2018-01-01' THEN 1 END), 0)) * 100, 1) AS modern_draw_rate_pct,

        ROUND((COUNT(CASE WHEN match_date >= '2018-01-01' AND goals_conceded = 0 THEN 1 END)::NUMERIC / 
            NULLIF(COUNT(CASE WHEN match_date >= '2018-01-01' THEN 1 END), 0)) * 100, 1) AS modern_clean_sheet_pct
    FROM {{ ref('fact_matches') }}
    GROUP BY 1
)

SELECT 
    g.group_name,
    g.team_name,
    COALESCE(h.total_wc_appearances, 0) AS wc_appearances,
    COALESCE(h.modern_win_rate_pct, 0.0) AS modern_win_rate_pct,
    COALESCE(h.modern_draw_rate_pct, 0.0) AS modern_draw_rate_pct,
    COALESCE(h.modern_clean_sheet_pct, 0.0) AS modern_clean_sheet_pct,
    
    SUM(COALESCE(h.total_wc_appearances, 0)) OVER(PARTITION BY g.group_name) AS group_accumulated_wc_appearances,
    ROUND(AVG(COALESCE(h.modern_win_rate_pct, 0.0)) OVER(PARTITION BY g.group_name), 1) AS group_avg_modern_win_rate
FROM current_groups g
LEFT JOIN historical_metrics h ON g.team_name = h.team_name