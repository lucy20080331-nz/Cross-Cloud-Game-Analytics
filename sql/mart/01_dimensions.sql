/*
Redshift Game Analytics — Dimensions

Creates:
  mart.dim_event
  mart.dim_date
  mart.dim_user
  mart.dim_game_content
*/

-- =========================================================
-- 1. EVENT DIMENSION
-- =========================================================

DROP TABLE IF EXISTS mart.dim_event;

CREATE TABLE mart.dim_event
DISTSTYLE ALL
SORTKEY (event_group, event_name)
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY event_name) AS event_key,
    event_name,
    CASE
        WHEN event_name IN (
            'level_start', 'level_end', 'level_complete', 'level_fail',
            'level_retry', 'level_reset', 'level_up', 'completed_5_levels',
            'level_start_quickplay', 'level_end_quickplay',
            'level_complete_quickplay', 'level_fail_quickplay',
            'level_retry_quickplay', 'level_reset_quickplay',
            'post_score', 'use_extra_steps', 'no_more_extra_steps'
        ) THEN 'Gameplay'
        WHEN event_name IN (
            'first_open', 'session_start', 'user_engagement',
            'screen_view', 'app_background', 'app_foreground'
        ) THEN 'Engagement'
        WHEN event_name IN (
            'notification_receive', 'notification_open',
            'notification_dismiss', 'notification_foreground'
        ) THEN 'Notification'
        WHEN event_name IN (
            'dynamic_link_first_open', 'dynamic_link_app_open'
        ) THEN 'Acquisition'
        WHEN event_name IN (
            'in_app_purchase', 'spend_virtual_currency', 'ad_reward'
        ) THEN 'Monetisation'
        WHEN event_name IN (
            'app_exception', 'error', 'app_update', 'os_update',
            'app_remove', 'app_clear_data'
        ) THEN 'Technical'
        ELSE 'Other'
    END AS event_group,
    CASE
        WHEN event_name LIKE '%_quickplay' THEN 'Quickplay'
        WHEN event_name IN (
            'level_start', 'level_end', 'level_complete', 'level_fail',
            'level_retry', 'level_reset', 'level_up', 'completed_5_levels'
        ) THEN 'Progressive'
        WHEN event_name IN (
            'post_score', 'use_extra_steps', 'no_more_extra_steps',
            'spend_virtual_currency', 'ad_reward'
        ) THEN 'Cross-mode'
        ELSE 'Not applicable'
    END AS game_mode,
    CASE
        WHEN event_name IN ('level_start', 'level_start_quickplay') THEN 'Start'
        WHEN event_name IN ('level_end', 'level_end_quickplay') THEN 'End'
        WHEN event_name IN ('level_complete', 'level_complete_quickplay') THEN 'Complete'
        WHEN event_name IN ('level_fail', 'level_fail_quickplay') THEN 'Fail'
        WHEN event_name IN ('level_retry', 'level_retry_quickplay') THEN 'Retry'
        WHEN event_name IN ('level_reset', 'level_reset_quickplay') THEN 'Reset'
        WHEN event_name = 'level_up' THEN 'Level up'
        WHEN event_name = 'completed_5_levels' THEN 'Milestone'
        WHEN event_name = 'post_score' THEN 'Post score'
        WHEN event_name = 'use_extra_steps' THEN 'Use extra steps'
        WHEN event_name = 'no_more_extra_steps' THEN 'No extra steps'
        WHEN event_name = 'spend_virtual_currency' THEN 'Spend virtual currency'
        WHEN event_name = 'ad_reward' THEN 'Receive ad reward'
        ELSE 'Not applicable'
    END AS gameplay_action,
    CASE
        WHEN event_name IN (
            'level_complete', 'level_complete_quickplay',
            'level_up', 'completed_5_levels'
        ) THEN 'Success'
        WHEN event_name IN (
            'level_fail', 'level_fail_quickplay', 'no_more_extra_steps'
        ) THEN 'Failure'
        WHEN event_name IN ('level_retry', 'level_retry_quickplay') THEN 'Retry'
        WHEN event_name IN ('level_reset', 'level_reset_quickplay') THEN 'Reset'
        ELSE 'Not applicable'
    END AS gameplay_outcome,
    CASE WHEN event_name IN (
        'level_start', 'level_end', 'level_complete', 'level_fail',
        'level_retry', 'level_reset', 'level_up',
        'level_start_quickplay', 'level_end_quickplay',
        'level_complete_quickplay', 'level_fail_quickplay',
        'level_retry_quickplay', 'level_reset_quickplay'
    ) THEN TRUE ELSE FALSE END AS is_level_event,
    CASE WHEN event_name IN (
        'level_complete', 'level_complete_quickplay'
    ) THEN TRUE ELSE FALSE END AS is_completion_event,
    CASE WHEN event_name IN (
        'level_fail', 'level_fail_quickplay'
    ) THEN TRUE ELSE FALSE END AS is_failure_event
FROM (
    SELECT DISTINCT event_name
    FROM core.events
    WHERE event_name IS NOT NULL
) AS event_names;

SELECT
    COUNT(*) AS dimension_rows,
    COUNT(DISTINCT event_key) AS distinct_event_keys,
    COUNT(DISTINCT event_name) AS distinct_event_names
FROM mart.dim_event;

SELECT *
FROM mart.dim_event
WHERE event_group = 'Other';


-- =========================================================
-- 2. DATE DIMENSION
-- =========================================================

DROP TABLE IF EXISTS mart.dim_date;

CREATE TABLE mart.dim_date
DISTSTYLE ALL
SORTKEY (calendar_date)
AS
WITH date_bounds AS (
    SELECT MIN(event_date) AS min_date, MAX(event_date) AS max_date
    FROM core.events
),
date_numbers AS (
    SELECT ROW_NUMBER() OVER () - 1 AS day_number
    FROM core.events
    LIMIT 10000
),
calendar AS (
    SELECT DATEADD(day, n.day_number, b.min_date)::DATE AS calendar_date
    FROM date_bounds AS b
    CROSS JOIN date_numbers AS n
    WHERE n.day_number <= DATEDIFF(day, b.min_date, b.max_date)
)
SELECT
    CAST(TO_CHAR(calendar_date, 'YYYYMMDD') AS INTEGER) AS date_key,
    calendar_date,
    EXTRACT(YEAR FROM calendar_date)::INTEGER AS calendar_year,
    EXTRACT(QUARTER FROM calendar_date)::INTEGER AS calendar_quarter,
    'Q' || EXTRACT(QUARTER FROM calendar_date)::INTEGER AS quarter_name,
    EXTRACT(MONTH FROM calendar_date)::INTEGER AS month_number,
    TRIM(TO_CHAR(calendar_date, 'Month')) AS month_name,
    TO_CHAR(calendar_date, 'Mon') AS month_short_name,
    TO_CHAR(calendar_date, 'YYYY-MM') AS year_month,
    EXTRACT(WEEK FROM calendar_date)::INTEGER AS week_of_year,
    DATE_TRUNC('week', calendar_date)::DATE AS week_start_date,
    EXTRACT(DAY FROM calendar_date)::INTEGER AS day_of_month,
    EXTRACT(DOW FROM calendar_date)::INTEGER AS day_of_week_number,
    TRIM(TO_CHAR(calendar_date, 'Day')) AS day_name,
    TO_CHAR(calendar_date, 'Dy') AS day_short_name,
    CASE WHEN EXTRACT(DOW FROM calendar_date) IN (0, 6)
        THEN TRUE ELSE FALSE END AS is_weekend
FROM calendar;

SELECT
    COUNT(*) AS date_rows,
    COUNT(DISTINCT date_key) AS distinct_date_keys,
    COUNT(DISTINCT calendar_date) AS distinct_dates,
    MIN(calendar_date) AS first_date,
    MAX(calendar_date) AS last_date
FROM mart.dim_date;

SELECT COUNT(*) AS missing_calendar_dates
FROM (
    SELECT calendar_date,
           LAG(calendar_date) OVER (ORDER BY calendar_date) AS previous_date
    FROM mart.dim_date
) AS date_sequence
WHERE previous_date IS NOT NULL
  AND DATEDIFF(day, previous_date, calendar_date) <> 1;

SELECT COUNT(*) AS unmatched_event_dates
FROM (SELECT DISTINCT event_date FROM core.events) AS e
LEFT JOIN mart.dim_date AS d
    ON e.event_date = d.calendar_date
WHERE d.date_key IS NULL;


-- =========================================================
-- 3. USER DIMENSION
-- =========================================================

DROP TABLE IF EXISTS mart.dim_user;

CREATE TABLE mart.dim_user
DISTSTYLE ALL
SORTKEY (user_pseudo_id)
AS
WITH ranked_events AS (
    SELECT
        e.*,
        ROW_NUMBER() OVER (
            PARTITION BY e.user_pseudo_id
            ORDER BY e.event_datetime, e.event_id
        ) AS first_event_rank,
        ROW_NUMBER() OVER (
            PARTITION BY e.user_pseudo_id
            ORDER BY e.event_datetime DESC, e.event_id DESC
        ) AS latest_event_rank
    FROM core.events AS e
    WHERE e.user_pseudo_id IS NOT NULL
),
user_summary AS (
    SELECT
        user_pseudo_id,
        MIN(user_first_touch_timestamp) AS user_first_touch_timestamp,
        MIN(user_first_touch_datetime) AS user_first_touch_datetime,
        MIN(event_datetime) AS first_event_datetime,
        MAX(event_datetime) AS last_event_datetime,
        MIN(event_date) AS first_active_date,
        MAX(event_date) AS last_active_date,
        COUNT(*) AS lifetime_event_count,
        COUNT(DISTINCT event_date) AS lifetime_active_days
    FROM ranked_events
    GROUP BY user_pseudo_id
),
first_observed AS (
    SELECT
        user_pseudo_id,
        user_id,
        traffic_source AS acquisition_source,
        traffic_medium AS acquisition_medium,
        traffic_campaign AS acquisition_campaign,
        install_source AS first_install_source,
        install_store AS first_install_store,
        app_version AS first_app_version
    FROM ranked_events
    WHERE first_event_rank = 1
),
latest_observed AS (
    SELECT
        user_pseudo_id,
        device_category,
        mobile_brand_name,
        mobile_model_name,
        mobile_marketing_name,
        operating_system,
        operating_system_version,
        device_language,
        is_limited_ad_tracking,
        time_zone_offset_seconds,
        continent,
        country,
        region,
        city,
        app_id,
        app_version AS latest_app_version,
        install_store,
        install_source,
        event_platform
    FROM ranked_events
    WHERE latest_event_rank = 1
)
SELECT
    ROW_NUMBER() OVER (ORDER BY s.user_pseudo_id) AS user_key,
    s.user_pseudo_id,
    f.user_id,
    s.user_first_touch_timestamp,
    s.user_first_touch_datetime,
    s.first_event_datetime,
    s.last_event_datetime,
    s.first_active_date,
    s.last_active_date,
    DATEDIFF(day, s.first_active_date, s.last_active_date)
        AS observed_lifetime_days,
    s.lifetime_event_count,
    s.lifetime_active_days,
    f.acquisition_source,
    f.acquisition_medium,
    f.acquisition_campaign,
    f.first_install_source,
    f.first_install_store,
    f.first_app_version,
    l.device_category,
    l.mobile_brand_name,
    l.mobile_model_name,
    l.mobile_marketing_name,
    l.operating_system,
    l.operating_system_version,
    l.device_language,
    l.is_limited_ad_tracking,
    l.time_zone_offset_seconds,
    l.continent,
    l.country,
    l.region,
    l.city,
    l.app_id,
    l.latest_app_version,
    l.install_store AS latest_install_store,
    l.install_source AS latest_install_source,
    l.event_platform
FROM user_summary AS s
LEFT JOIN first_observed AS f
    ON s.user_pseudo_id = f.user_pseudo_id
LEFT JOIN latest_observed AS l
    ON s.user_pseudo_id = l.user_pseudo_id;

SELECT
    COUNT(*) AS dimension_rows,
    COUNT(DISTINCT user_key) AS distinct_user_keys,
    COUNT(DISTINCT user_pseudo_id) AS distinct_users,
    MIN(first_active_date) AS earliest_first_activity,
    MAX(last_active_date) AS latest_activity
FROM mart.dim_user;

SELECT user_pseudo_id, COUNT(*) AS copies
FROM mart.dim_user
GROUP BY user_pseudo_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS unmatched_event_users
FROM (
    SELECT DISTINCT user_pseudo_id
    FROM core.events
    WHERE user_pseudo_id IS NOT NULL
) AS e
LEFT JOIN mart.dim_user AS u
    ON e.user_pseudo_id = u.user_pseudo_id
WHERE u.user_key IS NULL;


-- =========================================================
-- 4. GAME CONTENT DIMENSION
-- =========================================================

DROP TABLE IF EXISTS mart.dim_game_content;

CREATE TABLE mart.dim_game_content
DISTSTYLE ALL
SORTKEY (game_mode, content_sort_order)
AS
WITH progressive_levels AS (
    SELECT DISTINCT
        'Progressive'::VARCHAR(20) AS game_mode,
        'LEVEL_' || TRIM(p.parameter_value) AS content_id,
        'Level ' || TRIM(p.parameter_value) AS content_name,
        TRY_CAST(p.parameter_value AS INTEGER) AS level_number,
        NULL::VARCHAR(10) AS board_code,
        TRY_CAST(p.parameter_value AS INTEGER) AS content_sort_order
    FROM core.event_params AS p
    JOIN core.events AS e ON p.event_id = e.event_id
    WHERE e.event_name IN (
        'level_start', 'level_end', 'level_complete', 'level_fail',
        'level_retry', 'level_reset', 'level_up'
    )
      AND p.parameter_name = 'level'
      AND p.parameter_value IS NOT NULL
      AND TRY_CAST(p.parameter_value AS INTEGER) IS NOT NULL
),
quickplay_boards AS (
    SELECT DISTINCT
        'Quickplay'::VARCHAR(20) AS game_mode,
        'BOARD_' || UPPER(TRIM(p.parameter_value)) AS content_id,
        CASE UPPER(TRIM(p.parameter_value))
            WHEN 'S' THEN 'Small Board'
            WHEN 'M' THEN 'Medium Board'
            WHEN 'L' THEN 'Large Board'
            ELSE 'Board ' || UPPER(TRIM(p.parameter_value))
        END AS content_name,
        NULL::INTEGER AS level_number,
        UPPER(TRIM(p.parameter_value)) AS board_code,
        CASE UPPER(TRIM(p.parameter_value))
            WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 ELSE 99
        END AS content_sort_order
    FROM core.event_params AS p
    JOIN core.events AS e ON p.event_id = e.event_id
    WHERE e.event_name IN (
        'level_start_quickplay', 'level_end_quickplay',
        'level_complete_quickplay', 'level_fail_quickplay',
        'level_retry_quickplay', 'level_reset_quickplay'
    )
      AND p.parameter_name = 'board'
      AND p.parameter_value IS NOT NULL
),
all_content AS (
    SELECT * FROM progressive_levels
    UNION ALL
    SELECT * FROM quickplay_boards
),
numbered_content AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY game_mode, content_sort_order, content_id
        ) AS generated_key,
        *
    FROM all_content
)
SELECT
    generated_key AS game_content_key,
    game_mode,
    content_id,
    content_name,
    level_number,
    board_code,
    content_sort_order
FROM numbered_content;

SELECT
    COUNT(*) AS dimension_rows,
    COUNT(DISTINCT game_content_key) AS distinct_keys,
    COUNT(DISTINCT content_id) AS distinct_content_ids
FROM mart.dim_game_content;

SELECT game_mode, content_id, COUNT(*) AS copies
FROM mart.dim_game_content
GROUP BY game_mode, content_id
HAVING COUNT(*) > 1;

WITH source_content AS (
    SELECT DISTINCT
        CASE WHEN e.event_name LIKE '%_quickplay'
            THEN 'Quickplay' ELSE 'Progressive' END AS game_mode,
        CASE WHEN e.event_name LIKE '%_quickplay'
            THEN 'BOARD_' || UPPER(TRIM(p.parameter_value))
            ELSE 'LEVEL_' || TRIM(p.parameter_value) END AS content_id
    FROM core.event_params AS p
    JOIN core.events AS e ON p.event_id = e.event_id
    WHERE (
        e.event_name IN (
            'level_start', 'level_end', 'level_complete', 'level_fail',
            'level_retry', 'level_reset', 'level_up'
        )
        AND p.parameter_name = 'level'
    )
    OR (
        e.event_name IN (
            'level_start_quickplay', 'level_end_quickplay',
            'level_complete_quickplay', 'level_fail_quickplay',
            'level_retry_quickplay', 'level_reset_quickplay'
        )
        AND p.parameter_name = 'board'
    )
)
SELECT COUNT(*) AS unmatched_content_values
FROM source_content AS s
LEFT JOIN mart.dim_game_content AS d
    ON s.game_mode = d.game_mode
   AND s.content_id = d.content_id
WHERE d.game_content_key IS NULL;

