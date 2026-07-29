-- Internal Redshift schemas used by the transformation pipeline.
-- The Spectrum external schema `spectrum_raw` must be created separately
-- after configuring the AWS Glue Data Catalog and Redshift IAM role.

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS mart;
