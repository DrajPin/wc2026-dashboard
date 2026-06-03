WITH source AS (
    SELECT *
    FROM {{ source('raw', 'former_team_names')}}
)
SELECT
    current  AS current_name,
    former AS former_name,
    start_date::date AS start_date,
    end_date::date AS end_date
FROM source