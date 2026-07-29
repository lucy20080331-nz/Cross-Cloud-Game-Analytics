-- 01_create_spectrum_raw_firebase_events.sql
-- Project: Redshift Game Analysis
-- Purpose: Create the Spectrum external table over nested Firebase Parquet
--          files in S3 and register all 114 daily partitions.
-- Source dates: 2018-06-12 to 2018-10-03
-- Run while connected to the Redshift database: game_analytics
-- Before running, replace `your-game-analytics-bucket` with the S3 bucket
-- configured in GAME_ANALYTICS_S3_BUCKET.

CREATE EXTERNAL TABLE IF NOT EXISTS spectrum_raw.firebase_events (
    event_timestamp BIGINT,
    event_name VARCHAR(100),

    event_params ARRAY<
        STRUCT<
            key: VARCHAR(100),
            value: STRUCT<
                string_value: VARCHAR(65535),
                int_value: BIGINT,
                float_value: REAL,
                double_value: DOUBLE PRECISION
            >
        >
    >,

    event_previous_timestamp BIGINT,
    user_id VARCHAR(256),
    user_pseudo_id VARCHAR(256),

    user_properties ARRAY<
        STRUCT<
            key: VARCHAR(100),
            value: STRUCT<
                string_value: VARCHAR(65535),
                int_value: BIGINT,
                float_value: REAL,
                double_value: DOUBLE PRECISION,
                set_timestamp_micros: BIGINT
            >
        >
    >,

    user_first_touch_timestamp BIGINT,

    user_ltv STRUCT<
        revenue: DOUBLE PRECISION,
        currency: VARCHAR(10)
    >,

    device STRUCT<
        category: VARCHAR(50),
        mobile_brand_name: VARCHAR(200),
        mobile_model_name: VARCHAR(200),
        mobile_marketing_name: VARCHAR(200),
        mobile_os_hardware_model: VARCHAR(200),
        operating_system: VARCHAR(100),
        operating_system_version: VARCHAR(100),
        vendor_id: VARCHAR(256),
        advertising_id: VARCHAR(256),
        language: VARCHAR(50),
        is_limited_ad_tracking: VARCHAR(20),
        time_zone_offset_seconds: BIGINT
    >,

    geo STRUCT<
        continent: VARCHAR(100),
        country: VARCHAR(100),
        region: VARCHAR(200),
        city: VARCHAR(200)
    >,

    app_info STRUCT<
        id: VARCHAR(256),
        version: VARCHAR(100),
        install_store: VARCHAR(200),
        firebase_app_id: VARCHAR(256),
        install_source: VARCHAR(200)
    >,

    traffic_source STRUCT<
        name: VARCHAR(500),
        medium: VARCHAR(200),
        source: VARCHAR(500)
    >,

    stream_id VARCHAR(100),
    platform VARCHAR(50)
)
PARTITIONED BY (
    event_date DATE
)
STORED AS PARQUET
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/';


-- Register the 114 Hive-style event_date partitions.
-- These statements must run as top-level SQL. Redshift does not allow
-- ALTER EXTERNAL TABLE to execute from a stored procedure.

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-12')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-12/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-13')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-13/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-14')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-14/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-15')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-15/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-16')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-16/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-17')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-17/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-18')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-18/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-19')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-19/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-20')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-20/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-21')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-21/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-22')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-22/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-23')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-23/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-24')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-24/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-25')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-25/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-26')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-26/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-27')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-27/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-28')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-28/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-29')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-29/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-06-30')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-06-30/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-01')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-01/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-02')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-02/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-03')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-03/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-04')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-04/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-05')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-05/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-06')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-06/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-07')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-07/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-08')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-08/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-09')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-09/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-10')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-10/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-11')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-11/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-12')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-12/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-13')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-13/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-14')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-14/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-15')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-15/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-16')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-16/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-17')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-17/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-18')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-18/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-19')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-19/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-20')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-20/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-21')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-21/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-22')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-22/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-23')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-23/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-24')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-24/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-25')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-25/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-26')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-26/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-27')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-27/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-28')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-28/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-29')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-29/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-30')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-30/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-07-31')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-07-31/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-01')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-01/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-02')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-02/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-03')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-03/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-04')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-04/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-05')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-05/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-06')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-06/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-07')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-07/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-08')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-08/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-09')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-09/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-10')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-10/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-11')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-11/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-12')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-12/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-13')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-13/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-14')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-14/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-15')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-15/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-16')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-16/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-17')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-17/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-18')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-18/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-19')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-19/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-20')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-20/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-21')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-21/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-22')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-22/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-23')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-23/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-24')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-24/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-25')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-25/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-26')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-26/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-27')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-27/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-28')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-28/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-29')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-29/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-30')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-30/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-08-31')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-08-31/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-01')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-01/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-02')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-02/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-03')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-03/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-04')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-04/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-05')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-05/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-06')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-06/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-07')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-07/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-08')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-08/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-09')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-09/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-10')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-10/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-11')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-11/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-12')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-12/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-13')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-13/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-14')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-14/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-15')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-15/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-16')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-16/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-17')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-17/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-18')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-18/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-19')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-19/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-20')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-20/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-21')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-21/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-22')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-22/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-23')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-23/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-24')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-24/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-25')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-25/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-26')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-26/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-27')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-27/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-28')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-28/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-29')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-29/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-09-30')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-09-30/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-10-01')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-10-01/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-10-02')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-10-02/';

ALTER TABLE spectrum_raw.firebase_events
ADD IF NOT EXISTS PARTITION (event_date='2018-10-03')
LOCATION 's3://your-game-analytics-bucket/raw/firebase/events/event_date=2018-10-03/';

-- Validate partition coverage. Expected: 114 partitions.
SELECT
    COUNT(*) AS registered_partitions
FROM svv_external_partitions
WHERE schemaname = 'spectrum_raw'
  AND tablename = 'firebase_events';


-- Validate the first partition. Expected event_count: 50000.
SELECT
    event_date,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_pseudo_id) AS unique_users,
    MIN(event_timestamp) AS minimum_timestamp,
    MAX(event_timestamp) AS maximum_timestamp
FROM spectrum_raw.firebase_events
WHERE event_date = DATE '2018-06-12'
GROUP BY event_date;


-- Confirm nested fields can be read.
SELECT
    event_date,
    event_name,
    user_pseudo_id,
    device.category AS device_category,
    device.operating_system AS operating_system,
    geo.country AS country,
    app_info.version AS app_version,
    traffic_source.source AS traffic_source,
    platform
FROM spectrum_raw.firebase_events
WHERE event_date = DATE '2018-06-12'
LIMIT 10;
