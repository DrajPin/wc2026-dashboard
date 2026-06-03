WITH competitive_base AS (
    SELECT 
        team_name,
        COUNT(*) AS total_competitive_matches,
        COUNT(CASE WHEN match_outcome = 'Win' THEN 1 END)::NUMERIC / NULLIF(COUNT(*), 0) AS competitive_win_rate
    FROM {{ ref('fact_matches') }}
    WHERE match_date >= '2018-01-01'
      AND tournament != 'Friendly' 
    GROUP BY 1
),

ranked_population AS (
    SELECT 
        g.team_name,
        g.group_name,
        g.wc_appearances,
        c.competitive_win_rate,
        PERCENT_RANK() OVER (ORDER BY c.competitive_win_rate) AS form_percentile,
        PERCENT_RANK() OVER (ORDER BY g.wc_appearances) AS pedigree_percentile
    FROM {{ ref('agg_group_scout') }} g
    LEFT JOIN competitive_base c ON g.team_name = c.team_name
),

mathematical_delta AS (
    SELECT 
        *,
        (form_percentile - pedigree_percentile) AS raw_dark_horse_score
    FROM ranked_population
),

scaled_data AS (
    SELECT 
        team_name,
        group_name,
        wc_appearances,
        ROUND((competitive_win_rate * 100)::NUMERIC, 1) AS modern_era_win_rate_pct,
        ROUND(((((raw_dark_horse_score - MIN(raw_dark_horse_score) OVER()) / 
        NULLIF(MAX(raw_dark_horse_score) OVER() - MIN(raw_dark_horse_score) OVER(), 0)) * 100))::NUMERIC, 1) AS dark_horse_index_score
    FROM mathematical_delta
)

SELECT 
    team_name,
    group_name,
    wc_appearances,
    modern_era_win_rate_pct,
    dark_horse_index_score,
    CASE 
        WHEN dark_horse_index_score >= 75 THEN 'Elite Dark Horse'
        WHEN dark_horse_index_score >= 50 THEN 'Dark Horse Threat'
        ELSE 'Expected Performer'
    END AS dark_horse_classification
FROM scaled_data