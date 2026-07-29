/*
Redshift Game Analytics — Event Fact
Grain: one row per event in core.events.
*/

DROP TABLE IF EXISTS mart.fact_events;

CREATE TABLE mart.fact_events
DISTSTYLE KEY
DISTKEY (user_key)
COMPOUND SORTKEY (event_date, event_name)
AS
WITH parameter_pivot AS (
    SELECT
        event_id,
        MAX(CASE WHEN parameter_name = 'level'
            THEN TRY_CAST(parameter_value AS INTEGER) END) AS level_number,
        MAX(CASE WHEN parameter_name = 'level_name'
            THEN parameter_value END) AS level_name,
        MAX(CASE WHEN parameter_name = 'board'
            THEN UPPER(TRIM(parameter_value)) END) AS board_code,
        MAX(CASE WHEN parameter_name = 'score'
            THEN TRY_CAST(parameter_value AS BIGINT) END) AS score,
        MAX(CASE WHEN parameter_name = 'time'
            THEN TRY_CAST(parameter_value AS DOUBLE PRECISION) END) AS gameplay_time,
        MAX(CASE WHEN parameter_name = 'engagement_time_msec'
            THEN TRY_CAST(parameter_value AS BIGINT) END) AS engagement_time_msec,
        MAX(CASE WHEN parameter_name = 'value'
            THEN TRY_CAST(parameter_value AS DOUBLE PRECISION) END) AS event_value,
        MAX(CASE WHEN parameter_name = 'item_name'
            THEN parameter_value END) AS item_name,
        MAX(CASE WHEN parameter_name = 'virtual_currency_name'
            THEN parameter_value END) AS virtual_currency_name,
        MAX(CASE WHEN parameter_name = 'type'
            THEN parameter_value END) AS reward_type,
        MAX(CASE WHEN parameter_name = 'ad_unit_code'
            THEN parameter_value END) AS ad_unit_code,
        MAX(CASE WHEN parameter_name = 'currency'
            THEN UPPER(parameter_value) END) AS purchase_currency,
        MAX(CASE WHEN parameter_name = 'price'
            THEN TRY_CAST(parameter_value AS DECIMAL(18,4)) END) AS purchase_price_raw,
        MAX(CASE WHEN parameter_name = 'product_id'
            THEN parameter_value END) AS product_id,
        MAX(CASE WHEN parameter_name = 'quantity'
            THEN TRY_CAST(parameter_value AS INTEGER) END) AS purchase_quantity,
        MAX(CASE WHEN parameter_name = 'validated'
            THEN LOWER(parameter_value) END) AS purchase_validated_raw
    FROM core.event_params
    WHERE parameter_name IN (
        'level', 'level_name', 'board', 'score', 'time',
        'engagement_time_msec', 'value', 'item_name',
        'virtual_currency_name', 'type', 'ad_unit_code',
        'currency', 'price', 'product_id', 'quantity', 'validated'
    )
    GROUP BY event_id
),
event_enriched AS (
    SELECT
        e.event_id,
        e.event_date,
        e.event_timestamp,
        e.event_datetime,
        e.event_name,
        e.user_pseudo_id,
        d.date_key,
        de.event_key,
        u.user_key,
        de.event_group,
        de.game_mode,
        de.gameplay_action,
        de.gameplay_outcome,
        p.level_number,
        p.level_name,
        p.board_code,
        CASE
            WHEN de.game_mode = 'Progressive' AND p.level_number IS NOT NULL
                THEN 'LEVEL_' || p.level_number::VARCHAR
            WHEN de.game_mode = 'Quickplay' AND p.board_code IS NOT NULL
                THEN 'BOARD_' || p.board_code
            ELSE NULL
        END AS content_id,
        p.score,
        p.gameplay_time,
        p.engagement_time_msec,
        p.event_value,
        p.item_name,
        p.virtual_currency_name,
        p.reward_type,
        p.ad_unit_code,
        p.purchase_currency,
        p.purchase_price_raw,
        p.product_id,
        p.purchase_quantity,
        p.purchase_validated_raw,
        CASE WHEN e.event_name = 'ad_reward'
            THEN p.event_value END AS reward_steps,
        CASE WHEN e.event_name = 'use_extra_steps'
            THEN p.event_value END AS extra_steps_used,
        CASE WHEN e.event_name = 'spend_virtual_currency'
            THEN p.event_value END AS virtual_currency_spent,
        CASE
            WHEN LOWER(p.purchase_validated_raw) IN ('1', 'true', 't', 'yes')
                THEN TRUE
            WHEN LOWER(p.purchase_validated_raw) IN ('0', 'false', 'f', 'no')
                THEN FALSE
            ELSE NULL
        END AS is_purchase_validated,
        e.event_platform,
        e.device_category,
        e.operating_system,
        e.operating_system_version,
        e.mobile_brand_name,
        e.mobile_model_name,
        e.device_language,
        e.continent,
        e.country,
        e.region,
        e.city,
        e.app_id,
        e.app_version,
        e.traffic_source,
        e.traffic_medium,
        e.traffic_campaign
    FROM core.events AS e
    LEFT JOIN parameter_pivot AS p ON e.event_id = p.event_id
    LEFT JOIN mart.dim_date AS d ON e.event_date = d.calendar_date
    LEFT JOIN mart.dim_event AS de ON e.event_name = de.event_name
    LEFT JOIN mart.dim_user AS u ON e.user_pseudo_id = u.user_pseudo_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY event_datetime, event_id) AS fact_event_key,
    ee.event_id,
    ee.date_key,
    ee.event_key,
    ee.user_key,
    gc.game_content_key,
    ee.event_date,
    ee.event_timestamp,
    ee.event_datetime,
    ee.event_name,
    ee.user_pseudo_id,
    ee.event_group,
    ee.game_mode,
    ee.gameplay_action,
    ee.gameplay_outcome,
    ee.content_id,
    ee.level_number,
    ee.level_name,
    ee.board_code,
    ee.score,
    ee.gameplay_time,
    ee.engagement_time_msec,
    ee.engagement_time_msec / 1000.0 AS engagement_time_seconds,
    ee.event_value,
    ee.reward_steps,
    ee.extra_steps_used,
    ee.virtual_currency_spent,
    ee.item_name,
    ee.virtual_currency_name,
    ee.reward_type,
    ee.ad_unit_code,
    ee.purchase_currency,
    ee.purchase_price_raw,
    ee.product_id,
    ee.purchase_quantity,
    ee.is_purchase_validated,
    ee.event_platform,
    ee.device_category,
    ee.operating_system,
    ee.operating_system_version,
    ee.mobile_brand_name,
    ee.mobile_model_name,
    ee.device_language,
    ee.continent,
    ee.country,
    ee.region,
    ee.city,
    ee.app_id,
    ee.app_version,
    ee.traffic_source,
    ee.traffic_medium,
    ee.traffic_campaign
FROM event_enriched AS ee
LEFT JOIN mart.dim_game_content AS gc
    ON ee.game_mode = gc.game_mode
   AND ee.content_id = gc.content_id;

-- Grain validation
SELECT
    (SELECT COUNT(*) FROM core.events) AS core_event_rows,
    COUNT(*) AS fact_event_rows,
    COUNT(DISTINCT event_id) AS distinct_event_ids,
    COUNT(DISTINCT fact_event_key) AS distinct_fact_keys
FROM mart.fact_events;

SELECT event_id, COUNT(*) AS copies
FROM mart.fact_events
GROUP BY event_id
HAVING COUNT(*) > 1
LIMIT 20;

-- Dimension relationship validation
SELECT
    SUM(CASE WHEN date_key IS NULL THEN 1 ELSE 0 END) AS missing_date_keys,
    SUM(CASE WHEN event_key IS NULL THEN 1 ELSE 0 END) AS missing_event_keys,
    SUM(CASE WHEN user_pseudo_id IS NOT NULL AND user_key IS NULL
        THEN 1 ELSE 0 END) AS missing_user_keys
FROM mart.fact_events;

-- Game-content matching validation
SELECT
    game_mode,
    event_name,
    COUNT(*) AS event_count,
    SUM(CASE WHEN game_content_key IS NULL THEN 1 ELSE 0 END)
        AS missing_content_count,
    ROUND(
        100.0 * SUM(CASE WHEN game_content_key IS NULL THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS missing_content_pct
FROM mart.fact_events
WHERE game_mode IN ('Progressive', 'Quickplay')
  AND event_name LIKE 'level%'
GROUP BY game_mode, event_name
ORDER BY game_mode, event_name;

