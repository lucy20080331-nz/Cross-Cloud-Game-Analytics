/*
===============================================================================
File: 03_create_core_tables.sql
Purpose:
    Create the clean Redshift core layer from the source-preserving staging
    tables.

Prerequisites:
    staging.stg_events
    staging.stg_event_params
    staging.stg_user_properties

Core grain:
    core.events          = one row per event_id
    core.event_params    = one row per event_id + parameter_name
    core.user_properties = one row per event_id + property_name

Known source-data decision:
    staging.stg_events contains 206 extra event rows. One duplicated event has
    conflicting country values (Argentina and United States). The deterministic
    ordering below keeps Argentina; the impact is immaterial for this project.
===============================================================================
*/

-- Ensure the target schema exists.
CREATE SCHEMA IF NOT EXISTS core;


-- ============================================================================
-- 1. CORE EVENTS
--    Deduplicate staging events and retain one row per logical event.
-- ============================================================================

DROP TABLE IF EXISTS core.events;

CREATE TABLE core.events
DISTSTYLE AUTO
SORTKEY (event_date, event_name)
AS
SELECT s.*
FROM staging.stg_events AS s
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY s.event_id
    ORDER BY s.country, s.loaded_at
) = 1;


-- ============================================================================
-- 2. CORE EVENT PARAMETERS
--    Keep parameters belonging to valid core events and remove copies caused
--    by duplicated parent events.
-- ============================================================================

DROP TABLE IF EXISTS core.event_params;

CREATE TABLE core.event_params
DISTSTYLE AUTO
SORTKEY (event_date, parameter_name)
AS
SELECT p.*
FROM staging.stg_event_params AS p
INNER JOIN core.events AS e
    ON p.event_id = e.event_id
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY p.event_id, p.parameter_name
    ORDER BY p.loaded_at
) = 1;


-- ============================================================================
-- 3. CORE USER PROPERTIES
--    Keep property snapshots belonging to valid core events and remove copies
--    caused by duplicated parent events.
-- ============================================================================

DROP TABLE IF EXISTS core.user_properties;

CREATE TABLE core.user_properties
DISTSTYLE AUTO
SORTKEY (event_date, property_name)
AS
SELECT up.*
FROM staging.stg_user_properties AS up
INNER JOIN core.events AS e
    ON up.event_id = e.event_id
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY up.event_id, up.property_name
    ORDER BY up.loaded_at
) = 1;


-- ============================================================================
-- 4. VALIDATION
-- ============================================================================

-- 4.1 Validate core.events.
-- Expected:
--   core_rows            = 5,699,794
--   distinct_event_ids   = 5,699,794
--   remaining_duplicates = 0
--   loaded_dates         = 114
--   first_date           = 2018-06-12
--   last_date            = 2018-10-03
--   unique_users         = 15,175
SELECT
    COUNT(*) AS core_rows,
    COUNT(DISTINCT event_id) AS distinct_event_ids,
    COUNT(*) - COUNT(DISTINCT event_id) AS remaining_duplicates,
    COUNT(DISTINCT event_date) AS loaded_dates,
    MIN(event_date) AS first_date,
    MAX(event_date) AS last_date,
    COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM core.events;


-- 4.2 Reconcile staging events with core events.
-- Expected:
--   staging_rows = 5,700,000
--   core_rows    = 5,699,794
--   rows_removed = 206
SELECT
    (SELECT COUNT(*) FROM staging.stg_events) AS staging_rows,
    (SELECT COUNT(*) FROM core.events) AS core_rows,
    (SELECT COUNT(*) FROM staging.stg_events)
        - (SELECT COUNT(*) FROM core.events) AS rows_removed;


-- 4.3 Summarize core.event_params.
SELECT
    COUNT(*) AS core_parameter_rows,
    COUNT(DISTINCT event_id) AS events_with_parameters,
    COUNT(DISTINCT parameter_name) AS parameter_names,
    COUNT(DISTINCT event_date) AS loaded_dates
FROM core.event_params;


-- 4.4 Confirm that core.event_params has no duplicate logical keys.
-- Expected: both results = 0.
SELECT
    COUNT(*) AS duplicated_parameter_keys,
    COALESCE(SUM(copies - 1), 0) AS extra_parameter_rows
FROM (
    SELECT
        event_id,
        parameter_name,
        COUNT(*) AS copies
    FROM core.event_params
    GROUP BY event_id, parameter_name
    HAVING COUNT(*) > 1
) AS duplicates;


-- 4.5 Confirm that every parameter belongs to a valid core event.
-- Expected: 0.
SELECT COUNT(*) AS orphan_parameter_rows
FROM core.event_params AS p
LEFT JOIN core.events AS e
    ON p.event_id = e.event_id
WHERE e.event_id IS NULL;


-- 4.6 Summarize core.user_properties.
SELECT
    COUNT(*) AS core_property_rows,
    COUNT(DISTINCT event_id) AS events_with_properties,
    COUNT(DISTINCT user_pseudo_id) AS users_with_properties,
    COUNT(DISTINCT property_name) AS property_names,
    COUNT(DISTINCT event_date) AS loaded_dates
FROM core.user_properties;


-- 4.7 Confirm that core.user_properties has no duplicate logical keys.
-- Expected: both results = 0.
SELECT
    COUNT(*) AS duplicated_property_keys,
    COALESCE(SUM(copies - 1), 0) AS extra_property_rows
FROM (
    SELECT
        event_id,
        property_name,
        COUNT(*) AS copies
    FROM core.user_properties
    GROUP BY event_id, property_name
    HAVING COUNT(*) > 1
) AS duplicates;


-- 4.8 Confirm that every property belongs to a valid core event.
-- Expected: 0.
SELECT COUNT(*) AS orphan_property_rows
FROM core.user_properties AS up
LEFT JOIN core.events AS e
    ON up.event_id = e.event_id
WHERE e.event_id IS NULL;


-- 4.9 Confirm that important game properties were preserved.
SELECT
    property_name,
    COUNT(*) AS property_rows,
    COUNT(DISTINCT user_pseudo_id) AS users_with_property
FROM core.user_properties
WHERE property_name IN (
    'plays_progressive',
    'plays_quickplay',
    'ad_frequency',
    'initial_extra_steps',
    'num_levels_available'
)
GROUP BY property_name
ORDER BY property_name;


-- CTAS operations are analyzed automatically by Redshift. Run ANALYZE manually
-- later only after substantial INSERT, UPDATE, or DELETE activity.
