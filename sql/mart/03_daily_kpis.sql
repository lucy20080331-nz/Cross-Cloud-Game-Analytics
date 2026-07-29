/*
Redshift Game Analytics — Daily KPIs
Grain: one row per calendar date.
*/

DROP TABLE IF EXISTS mart.daily_kpis;

CREATE TABLE mart.daily_kpis
DISTSTYLE ALL
SORTKEY (calendar_date)
AS
WITH daily_activity AS (
    SELECT
        event_date,
        COUNT(*) AS total_events,
        COUNT(DISTINCT user_key) AS daily_active_users,
        COUNT(DISTINCT CASE WHEN event_name = 'session_start'
            THEN event_id END) AS sessions,
        COUNT(DISTINCT CASE WHEN event_name = 'session_start'
            THEN user_key END) AS session_users,
        COUNT(DISTINCT CASE WHEN event_name = 'first_open'
            THEN user_key END) AS new_users,
        SUM(CASE WHEN event_name = 'user_engagement'
            THEN COALESCE(engagement_time_seconds, 0) ELSE 0 END)
            AS total_engagement_seconds,
        COUNT(DISTINCT CASE WHEN event_name = 'user_engagement'
            THEN user_key END) AS engaged_users,
        SUM(CASE WHEN event_name = 'level_start' THEN 1 ELSE 0 END)
            AS progressive_starts,
        SUM(CASE WHEN event_name = 'level_complete' THEN 1 ELSE 0 END)
            AS progressive_completions,
        SUM(CASE WHEN event_name = 'level_fail' THEN 1 ELSE 0 END)
            AS progressive_failures,
        SUM(CASE WHEN event_name = 'level_retry' THEN 1 ELSE 0 END)
            AS progressive_retries,
        SUM(CASE WHEN event_name = 'level_reset' THEN 1 ELSE 0 END)
            AS progressive_resets,
        COUNT(DISTINCT CASE WHEN event_name IN (
            'level_start', 'level_complete', 'level_fail', 'level_retry',
            'level_reset', 'level_end', 'level_up'
        ) THEN user_key END) AS progressive_players,
        SUM(CASE WHEN event_name = 'level_start_quickplay' THEN 1 ELSE 0 END)
            AS quickplay_starts,
        SUM(CASE WHEN event_name = 'level_complete_quickplay' THEN 1 ELSE 0 END)
            AS quickplay_completions,
        SUM(CASE WHEN event_name = 'level_fail_quickplay' THEN 1 ELSE 0 END)
            AS quickplay_failures,
        SUM(CASE WHEN event_name = 'level_retry_quickplay' THEN 1 ELSE 0 END)
            AS quickplay_retries,
        SUM(CASE WHEN event_name = 'level_reset_quickplay' THEN 1 ELSE 0 END)
            AS quickplay_resets,
        COUNT(DISTINCT CASE WHEN event_name LIKE '%_quickplay'
            THEN user_key END) AS quickplay_players,
        COUNT(CASE WHEN event_name = 'post_score' THEN score END)
            AS scores_posted,
        AVG(CASE WHEN event_name = 'post_score'
            THEN score::DOUBLE PRECISION END) AS average_score,
        MAX(CASE WHEN event_name = 'post_score' THEN score END)
            AS highest_score,
        SUM(CASE WHEN event_name = 'use_extra_steps' THEN 1 ELSE 0 END)
            AS extra_step_events,
        SUM(CASE WHEN event_name = 'use_extra_steps'
            THEN COALESCE(extra_steps_used, 0) ELSE 0 END)
            AS total_extra_steps_used,
        SUM(CASE WHEN event_name = 'ad_reward' THEN 1 ELSE 0 END)
            AS ad_reward_events,
        COUNT(DISTINCT CASE WHEN event_name = 'ad_reward'
            THEN user_key END) AS ad_reward_users,
        SUM(CASE WHEN event_name = 'in_app_purchase' THEN 1 ELSE 0 END)
            AS purchase_events,
        COUNT(DISTINCT CASE WHEN event_name = 'in_app_purchase'
            THEN user_key END) AS purchasing_users,
        SUM(CASE WHEN event_name = 'in_app_purchase'
                  AND is_purchase_validated = TRUE
            THEN 1 ELSE 0 END) AS validated_purchase_events,
        SUM(CASE WHEN event_name = 'spend_virtual_currency'
            THEN 1 ELSE 0 END) AS virtual_currency_spend_events
    FROM mart.fact_events
    GROUP BY event_date
)
SELECT
    d.date_key,
    d.calendar_date,
    d.calendar_year,
    d.calendar_quarter,
    d.month_number,
    d.month_name,
    d.year_month,
    d.week_of_year,
    d.week_start_date,
    d.day_of_week_number,
    d.day_name,
    d.is_weekend,
    COALESCE(a.total_events, 0) AS total_events,
    COALESCE(a.daily_active_users, 0) AS daily_active_users,
    COALESCE(a.sessions, 0) AS sessions,
    COALESCE(a.session_users, 0) AS session_users,
    COALESCE(a.new_users, 0) AS new_users,
    COALESCE(a.total_engagement_seconds, 0) AS total_engagement_seconds,
    COALESCE(a.engaged_users, 0) AS engaged_users,
    a.total_engagement_seconds / NULLIF(a.daily_active_users, 0)
        AS average_engagement_seconds_per_user,
    a.total_engagement_seconds / NULLIF(a.sessions, 0)
        AS average_engagement_seconds_per_session,
    a.total_events::DECIMAL(18,4) / NULLIF(a.daily_active_users, 0)
        AS average_events_per_user,
    a.sessions::DECIMAL(18,4) / NULLIF(a.daily_active_users, 0)
        AS average_sessions_per_user,
    COALESCE(a.progressive_starts, 0) AS progressive_starts,
    COALESCE(a.progressive_completions, 0) AS progressive_completions,
    COALESCE(a.progressive_failures, 0) AS progressive_failures,
    COALESCE(a.progressive_retries, 0) AS progressive_retries,
    COALESCE(a.progressive_resets, 0) AS progressive_resets,
    COALESCE(a.progressive_players, 0) AS progressive_players,
    100.0 * a.progressive_completions / NULLIF(a.progressive_starts, 0)
        AS progressive_completion_event_ratio_pct,
    COALESCE(a.quickplay_starts, 0) AS quickplay_starts,
    COALESCE(a.quickplay_completions, 0) AS quickplay_completions,
    COALESCE(a.quickplay_failures, 0) AS quickplay_failures,
    COALESCE(a.quickplay_retries, 0) AS quickplay_retries,
    COALESCE(a.quickplay_resets, 0) AS quickplay_resets,
    COALESCE(a.quickplay_players, 0) AS quickplay_players,
    100.0 * a.quickplay_completions / NULLIF(a.quickplay_starts, 0)
        AS quickplay_completion_event_ratio_pct,
    COALESCE(a.scores_posted, 0) AS scores_posted,
    a.average_score,
    a.highest_score,
    COALESCE(a.extra_step_events, 0) AS extra_step_events,
    COALESCE(a.total_extra_steps_used, 0) AS total_extra_steps_used,
    COALESCE(a.ad_reward_events, 0) AS ad_reward_events,
    COALESCE(a.ad_reward_users, 0) AS ad_reward_users,
    COALESCE(a.purchase_events, 0) AS purchase_events,
    COALESCE(a.purchasing_users, 0) AS purchasing_users,
    COALESCE(a.validated_purchase_events, 0) AS validated_purchase_events,
    100.0 * a.purchasing_users / NULLIF(a.daily_active_users, 0)
        AS purchaser_rate_pct,
    COALESCE(a.virtual_currency_spend_events, 0)
        AS virtual_currency_spend_events
FROM mart.dim_date AS d
LEFT JOIN daily_activity AS a
    ON d.calendar_date = a.event_date;

-- Grain validation
SELECT
    COUNT(*) AS daily_rows,
    COUNT(DISTINCT date_key) AS distinct_date_keys,
    MIN(calendar_date) AS first_date,
    MAX(calendar_date) AS last_date
FROM mart.daily_kpis;

-- Reconciliation
SELECT
    (SELECT COUNT(*) FROM mart.fact_events) AS fact_total_events,
    SUM(total_events) AS kpi_total_events,
    (SELECT COUNT(*) FROM mart.fact_events
     WHERE event_name = 'level_complete') AS fact_progressive_completions,
    SUM(progressive_completions) AS kpi_progressive_completions,
    (SELECT COUNT(*) FROM mart.fact_events
     WHERE event_name = 'level_complete_quickplay')
        AS fact_quickplay_completions,
    SUM(quickplay_completions) AS kpi_quickplay_completions
FROM mart.daily_kpis;

