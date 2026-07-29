/*
Redshift Game Analytics — Gameplay Performance
Grain: one row per Progressive level or Quickplay board.
*/

DROP TABLE IF EXISTS mart.gameplay_performance;

CREATE TABLE mart.gameplay_performance
DISTSTYLE ALL
SORTKEY (game_mode, content_sort_order)
AS
WITH gameplay_summary AS (
    SELECT
        f.game_content_key,
        MIN(f.event_date) AS first_event_date,
        MAX(f.event_date) AS last_event_date,
        COUNT(*) AS total_gameplay_events,
        COUNT(DISTINCT f.user_key) AS unique_players,
        COUNT(DISTINCT f.event_date) AS active_dates,
        SUM(CASE WHEN f.gameplay_action = 'Start' THEN 1 ELSE 0 END) AS starts,
        SUM(CASE WHEN f.gameplay_action = 'End' THEN 1 ELSE 0 END) AS ends,
        SUM(CASE WHEN f.gameplay_action = 'Complete' THEN 1 ELSE 0 END) AS completions,
        SUM(CASE WHEN f.gameplay_action = 'Fail' THEN 1 ELSE 0 END) AS failures,
        SUM(CASE WHEN f.gameplay_action = 'Retry' THEN 1 ELSE 0 END) AS retries,
        SUM(CASE WHEN f.gameplay_action = 'Reset' THEN 1 ELSE 0 END) AS resets,
        COUNT(DISTINCT CASE WHEN f.gameplay_action = 'Start'
            THEN f.user_key END) AS starting_players,
        COUNT(DISTINCT CASE WHEN f.gameplay_action = 'Complete'
            THEN f.user_key END) AS completing_players,
        COUNT(DISTINCT CASE WHEN f.gameplay_action = 'Fail'
            THEN f.user_key END) AS failing_players,
        COUNT(DISTINCT CASE WHEN f.gameplay_action = 'Retry'
            THEN f.user_key END) AS retrying_players,
        COUNT(DISTINCT CASE WHEN f.gameplay_action = 'Reset'
            THEN f.user_key END) AS resetting_players,
        COUNT(f.score) AS scores_posted,
        AVG(CASE WHEN f.score IS NOT NULL
            THEN f.score::DOUBLE PRECISION END) AS average_score,
        MAX(f.score) AS highest_score,
        SUM(CASE WHEN f.event_name = 'use_extra_steps'
            THEN 1 ELSE 0 END) AS extra_step_events,
        SUM(CASE WHEN f.event_name = 'use_extra_steps'
            THEN COALESCE(f.extra_steps_used, 0) ELSE 0 END)
            AS total_extra_steps_used,
        COUNT(DISTINCT CASE WHEN f.event_name = 'use_extra_steps'
            THEN f.user_key END) AS extra_step_users
    FROM mart.fact_events AS f
    WHERE f.game_content_key IS NOT NULL
    GROUP BY f.game_content_key
)
SELECT
    c.game_content_key,
    c.game_mode,
    c.content_id,
    c.content_name,
    c.level_number,
    c.board_code,
    c.content_sort_order,
    s.first_event_date,
    s.last_event_date,
    COALESCE(s.total_gameplay_events, 0) AS total_gameplay_events,
    COALESCE(s.unique_players, 0) AS unique_players,
    COALESCE(s.active_dates, 0) AS active_dates,
    COALESCE(s.starts, 0) AS starts,
    COALESCE(s.ends, 0) AS ends,
    COALESCE(s.completions, 0) AS completions,
    COALESCE(s.failures, 0) AS failures,
    COALESCE(s.retries, 0) AS retries,
    COALESCE(s.resets, 0) AS resets,
    COALESCE(s.starting_players, 0) AS starting_players,
    COALESCE(s.completing_players, 0) AS completing_players,
    COALESCE(s.failing_players, 0) AS failing_players,
    COALESCE(s.retrying_players, 0) AS retrying_players,
    COALESCE(s.resetting_players, 0) AS resetting_players,
    100.0 * s.completions / NULLIF(s.starts, 0)
        AS completion_event_ratio_pct,
    100.0 * s.failures / NULLIF(s.starts, 0)
        AS failure_event_ratio_pct,
    100.0 * s.retries / NULLIF(s.starts, 0)
        AS retry_event_ratio_pct,
    100.0 * s.resets / NULLIF(s.starts, 0)
        AS reset_event_ratio_pct,
    100.0 * s.completing_players / NULLIF(s.starting_players, 0)
        AS completing_player_ratio_pct,
    100.0 * s.failing_players / NULLIF(s.starting_players, 0)
        AS failing_player_ratio_pct,
    s.retries::DECIMAL(18,4) / NULLIF(s.completions, 0)
        AS retries_per_completion,
    s.failures::DECIMAL(18,4) / NULLIF(s.completions, 0)
        AS failures_per_completion,
    COALESCE(s.scores_posted, 0) AS scores_posted,
    s.average_score,
    s.highest_score,
    COALESCE(s.extra_step_events, 0) AS extra_step_events,
    COALESCE(s.total_extra_steps_used, 0) AS total_extra_steps_used,
    COALESCE(s.extra_step_users, 0) AS extra_step_users
FROM mart.dim_game_content AS c
LEFT JOIN gameplay_summary AS s
    ON c.game_content_key = s.game_content_key;

-- Grain validation
SELECT
    COUNT(*) AS performance_rows,
    COUNT(DISTINCT game_content_key) AS distinct_content_keys,
    COUNT(DISTINCT content_id) AS distinct_content_ids
FROM mart.gameplay_performance;

-- All dimension records should be present
SELECT c.game_content_key, c.game_mode, c.content_id
FROM mart.dim_game_content AS c
LEFT JOIN mart.gameplay_performance AS p
    ON c.game_content_key = p.game_content_key
WHERE p.game_content_key IS NULL;

-- Reconcile starts and completions by mode
SELECT
    p.game_mode,
    SUM(p.starts) AS mart_starts,
    (
        SELECT COUNT(*)
        FROM mart.fact_events AS f
        WHERE f.game_content_key IS NOT NULL
          AND f.game_mode = p.game_mode
          AND f.gameplay_action = 'Start'
    ) AS fact_starts,
    SUM(p.completions) AS mart_completions,
    (
        SELECT COUNT(*)
        FROM mart.fact_events AS f
        WHERE f.game_content_key IS NOT NULL
          AND f.game_mode = p.game_mode
          AND f.gameplay_action = 'Complete'
    ) AS fact_completions
FROM mart.gameplay_performance AS p
GROUP BY p.game_mode
ORDER BY p.game_mode;

