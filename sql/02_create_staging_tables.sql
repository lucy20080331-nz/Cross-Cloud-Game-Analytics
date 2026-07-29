/*
Redshift Game Analytics
Production staging tables for all 114 Firebase event partitions

Source: spectrum_raw.firebase_events
Targets:
  1. staging.stg_events
  2. staging.stg_event_params
  3. staging.stg_user_properties

The staging layer preserves source duplicates. Deduplication belongs in core.
Run one CTAS section at a time to control Redshift Serverless usage.
*/

SET json_serialization_enable TO false;


-- ============================================================
-- 1. EVENTS: one row per source event
-- ============================================================

DROP TABLE IF EXISTS staging.stg_events;

CREATE TABLE staging.stg_events
DISTSTYLE AUTO
SORTKEY (event_date, event_name)
AS
SELECT
    MD5(
        COALESCE(r.user_pseudo_id, '') || '|' ||
        r.event_timestamp::VARCHAR || '|' ||
        COALESCE(r.event_name, '') || '|' ||
        COALESCE(r.event_previous_timestamp::VARCHAR, '')
    ) AS event_id,

    r.event_date,
    r.event_timestamp,

    DATEADD(
        microsecond,
        r.event_timestamp,
        TIMESTAMP '1970-01-01 00:00:00'
    ) AS event_datetime,

    r.event_name,
    r.event_previous_timestamp,

    DATEADD(
        microsecond,
        r.event_previous_timestamp,
        TIMESTAMP '1970-01-01 00:00:00'
    ) AS event_previous_datetime,

    r.user_id,
    r.user_pseudo_id,
    r.user_first_touch_timestamp,

    DATEADD(
        microsecond,
        r.user_first_touch_timestamp,
        TIMESTAMP '1970-01-01 00:00:00'
    ) AS user_first_touch_datetime,

    r.user_ltv.revenue AS user_ltv_revenue,
    r.user_ltv.currency AS user_ltv_currency,

    r.device.category AS device_category,
    r.device.mobile_brand_name AS mobile_brand_name,
    r.device.mobile_model_name AS mobile_model_name,
    r.device.mobile_marketing_name AS mobile_marketing_name,
    r.device.mobile_os_hardware_model AS mobile_os_hardware_model,
    r.device.operating_system AS operating_system,
    r.device.operating_system_version AS operating_system_version,
    r.device.vendor_id AS vendor_id,
    r.device.advertising_id AS advertising_id,
    r.device.language AS device_language,
    r.device.is_limited_ad_tracking AS is_limited_ad_tracking,
    r.device.time_zone_offset_seconds AS time_zone_offset_seconds,

    r.geo.continent AS continent,
    r.geo.country AS country,
    r.geo.region AS region,
    r.geo.city AS city,

    r.app_info.id AS app_id,
    r.app_info.version AS app_version,
    r.app_info.install_store AS install_store,
    r.app_info.firebase_app_id AS firebase_app_id,
    r.app_info.install_source AS install_source,

    r.traffic_source.name AS traffic_campaign,
    r.traffic_source.medium AS traffic_medium,
    r.traffic_source.source AS traffic_source,

    r.stream_id,
    r."platform" AS event_platform,

    GETDATE() AS loaded_at

FROM spectrum_raw.firebase_events r;


-- Validate stg_events.
SELECT
    COUNT(*) AS staging_rows,
    COUNT(DISTINCT event_id) AS distinct_event_ids,
    COUNT(*) - COUNT(DISTINCT event_id) AS extra_duplicate_rows,
    COUNT(DISTINCT event_date) AS loaded_dates,
    MIN(event_date) AS first_date,
    MAX(event_date) AS last_date,
    COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM staging.stg_events;

-- Expected:
-- staging_rows = 5,700,000
-- distinct_event_ids = 5,699,794
-- extra_duplicate_rows = 206
-- loaded_dates = 114
-- first_date = 2018-06-12
-- last_date = 2018-10-03
-- unique_users = 15,175


-- ============================================================
-- 2. EVENT PARAMETERS: one row per source event parameter
-- ============================================================

DROP TABLE IF EXISTS staging.stg_event_params;

CREATE TABLE staging.stg_event_params
DISTSTYLE AUTO
SORTKEY (event_date, parameter_name)
AS
SELECT
    MD5(
        COALESCE(r.user_pseudo_id, '') || '|' ||
        r.event_timestamp::VARCHAR || '|' ||
        COALESCE(r.event_name, '') || '|' ||
        COALESCE(r.event_previous_timestamp::VARCHAR, '')
    ) AS event_id,

    r.event_date,
    r.event_timestamp,

    DATEADD(
        microsecond,
        r.event_timestamp,
        TIMESTAMP '1970-01-01 00:00:00'
    ) AS event_datetime,

    r.event_name,
    r.user_pseudo_id,

    ep.key AS parameter_name,

    ep.value.string_value AS string_value,
    ep.value.int_value AS int_value,
    ep.value.float_value AS float_value,
    ep.value.double_value AS double_value,

    COALESCE(
        ep.value.string_value,
        ep.value.int_value::VARCHAR,
        ep.value.float_value::VARCHAR,
        ep.value.double_value::VARCHAR
    ) AS parameter_value,

    GETDATE() AS loaded_at

FROM spectrum_raw.firebase_events r,
     r.event_params ep;


-- Validate stg_event_params.
SELECT
    COUNT(*) AS parameter_rows,
    COUNT(DISTINCT event_id) AS events_with_parameters,
    COUNT(DISTINCT parameter_name) AS distinct_parameters,
    COUNT(DISTINCT event_date) AS loaded_dates,
    COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM staging.stg_event_params;

SELECT
    SUM(
        CASE
            WHEN string_value IS NULL
             AND int_value IS NULL
             AND float_value IS NULL
             AND double_value IS NULL
            THEN 1 ELSE 0
        END
    ) AS parameters_without_value,
    SUM(
        CASE
            WHEN
                (CASE WHEN string_value IS NOT NULL THEN 1 ELSE 0 END) +
                (CASE WHEN int_value IS NOT NULL THEN 1 ELSE 0 END) +
                (CASE WHEN float_value IS NOT NULL THEN 1 ELSE 0 END) +
                (CASE WHEN double_value IS NOT NULL THEN 1 ELSE 0 END) > 1
            THEN 1 ELSE 0
        END
    ) AS parameters_with_multiple_typed_values
FROM staging.stg_event_params;


-- ============================================================
-- 3. USER PROPERTIES: one row per source property snapshot
-- ============================================================

DROP TABLE IF EXISTS staging.stg_user_properties;

CREATE TABLE staging.stg_user_properties
DISTSTYLE AUTO
SORTKEY (event_date, property_name)
AS
SELECT
    MD5(
        COALESCE(r.user_pseudo_id, '') || '|' ||
        r.event_timestamp::VARCHAR || '|' ||
        COALESCE(r.event_name, '') || '|' ||
        COALESCE(r.event_previous_timestamp::VARCHAR, '')
    ) AS event_id,

    r.event_date,
    r.event_timestamp,

    DATEADD(
        microsecond,
        r.event_timestamp,
        TIMESTAMP '1970-01-01 00:00:00'
    ) AS event_datetime,

    r.event_name,
    r.user_pseudo_id,

    up.key AS property_name,

    up.value.string_value AS string_value,
    up.value.int_value AS int_value,
    up.value.float_value AS float_value,
    up.value.double_value AS double_value,

    COALESCE(
        up.value.string_value,
        up.value.int_value::VARCHAR,
        up.value.float_value::VARCHAR,
        up.value.double_value::VARCHAR
    ) AS property_value,

    up.value.set_timestamp_micros,

    DATEADD(
        microsecond,
        up.value.set_timestamp_micros,
        TIMESTAMP '1970-01-01 00:00:00'
    ) AS property_set_datetime,

    GETDATE() AS loaded_at

FROM spectrum_raw.firebase_events r,
     r.user_properties up;


-- Validate stg_user_properties.
SELECT
    COUNT(*) AS property_rows,
    COUNT(DISTINCT event_id) AS events_with_properties,
    COUNT(DISTINCT property_name) AS distinct_properties,
    COUNT(DISTINCT event_date) AS loaded_dates,
    COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM staging.stg_user_properties;

SELECT
    SUM(
        CASE
            WHEN string_value IS NULL
             AND int_value IS NULL
             AND float_value IS NULL
             AND double_value IS NULL
            THEN 1 ELSE 0
        END
    ) AS properties_without_value,
    SUM(
        CASE
            WHEN
                (CASE WHEN string_value IS NOT NULL THEN 1 ELSE 0 END) +
                (CASE WHEN int_value IS NOT NULL THEN 1 ELSE 0 END) +
                (CASE WHEN float_value IS NOT NULL THEN 1 ELSE 0 END) +
                (CASE WHEN double_value IS NOT NULL THEN 1 ELSE 0 END) > 1
            THEN 1 ELSE 0
        END
    ) AS properties_with_multiple_typed_values
FROM staging.stg_user_properties;


-- ============================================================
-- 4. CROSS-TABLE RECONCILIATION
-- ============================================================

SELECT
    (SELECT COUNT(DISTINCT event_id) FROM staging.stg_events)
        AS distinct_staged_events,
    (SELECT COUNT(DISTINCT event_id) FROM staging.stg_event_params)
        AS events_with_parameters,
    (SELECT COUNT(DISTINCT event_id) FROM staging.stg_user_properties)
        AS events_with_properties;

-- The event_id is intentionally generated with the same expression in all
-- three tables so the repeated records can connect back to their parent event.
