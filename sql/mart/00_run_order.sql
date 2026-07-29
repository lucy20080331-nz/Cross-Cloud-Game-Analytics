/*
Redshift Game Analytics — Mart Layer

Run these files in order:
  1. 01_dimensions.sql
  2. 02_fact_events.sql
  3. 03_daily_kpis.sql
  4. 04_gameplay_performance.sql

Source tables required:
  core.events
  core.event_params

Target tables:
  mart.dim_event
  mart.dim_date
  mart.dim_user
  mart.dim_game_content
  mart.fact_events
  mart.daily_kpis
  mart.gameplay_performance
*/

-- Final mart inventory
SELECT 'mart.dim_event' AS table_name, COUNT(*) AS row_count FROM mart.dim_event
UNION ALL
SELECT 'mart.dim_date', COUNT(*) FROM mart.dim_date
UNION ALL
SELECT 'mart.dim_user', COUNT(*) FROM mart.dim_user
UNION ALL
SELECT 'mart.dim_game_content', COUNT(*) FROM mart.dim_game_content
UNION ALL
SELECT 'mart.fact_events', COUNT(*) FROM mart.fact_events
UNION ALL
SELECT 'mart.daily_kpis', COUNT(*) FROM mart.daily_kpis
UNION ALL
SELECT 'mart.gameplay_performance', COUNT(*) FROM mart.gameplay_performance
ORDER BY table_name;

-- Final fact-to-source reconciliation
SELECT
    (SELECT COUNT(*) FROM core.events) AS core_event_rows,
    (SELECT COUNT(*) FROM mart.fact_events) AS fact_event_rows,
    (SELECT SUM(total_events) FROM mart.daily_kpis) AS daily_kpi_event_rows;

