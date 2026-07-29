"""Extract Firebase BigQuery tables to nested Parquet in S3 RAW.

This uses the BigQuery Storage Read API rather than a SQL query, preserving
ARRAY/STRUCT fields in Arrow and Parquet. It validates row counts locally
before uploading, verifies S3 metadata afterward, and safely skips previously
validated objects when a batch is resumed.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import tempfile
from pathlib import Path

import boto3
import pyarrow.parquet as pq
from botocore.exceptions import ClientError
from dotenv import load_dotenv
from google.cloud import bigquery


TABLE_PATTERN = re.compile(r"^events_(\d{4})(\d{2})(\d{2})$")
load_dotenv()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Copy Firebase BigQuery event tables to S3 as nested Parquet."
    )
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--table", help="One table, for example events_20180613")
    selection.add_argument(
        "--all-tables",
        action="store_true",
        help="Process every events_YYYYMMDD table in the source dataset.",
    )
    parser.add_argument(
        "--bucket",
        default=os.getenv("GAME_ANALYTICS_S3_BUCKET"),
        help=(
            "Target S3 bucket. Defaults to GAME_ANALYTICS_S3_BUCKET "
            "from the environment."
        ),
    )
    parser.add_argument(
        "--billing-project",
        default=os.getenv("GOOGLE_CLOUD_PROJECT"),
        help=(
            "Google Cloud billing project. Defaults to GOOGLE_CLOUD_PROJECT "
            "from the environment."
        ),
    )
    parser.add_argument(
        "--source-dataset",
        default=os.getenv(
            "GAME_ANALYTICS_SOURCE_DATASET",
            "firebase-public-project.analytics_153293282",
        ),
    )
    parser.add_argument(
        "--s3-prefix",
        default=os.getenv("GAME_ANALYTICS_S3_PREFIX", "raw/firebase/events"),
    )
    parser.add_argument(
        "--aws-region",
        default=os.getenv("AWS_REGION", "us-east-1"),
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Replace an existing object whose validation metadata does not match.",
    )
    args = parser.parse_args()
    if not args.bucket:
        parser.error(
            "Provide --bucket or set GAME_ANALYTICS_S3_BUCKET in the environment."
        )
    if not args.billing_project:
        parser.error(
            "Provide --billing-project or set GOOGLE_CLOUD_PROJECT "
            "in the environment."
        )
    if not args.table and not args.all_tables:
        args.table = "events_20180612"
    return args


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file_handle:
        for block in iter(lambda: file_handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def event_date_from_table(table_name: str) -> str:
    match = TABLE_PATTERN.fullmatch(table_name)
    if not match:
        raise ValueError(
            f"Expected a table name such as events_20180612; received {table_name!r}"
        )
    year, month, day = match.groups()
    return f"{year}-{month}-{day}"


def s3_key_for(table_name: str, s3_prefix: str) -> str:
    event_date = event_date_from_table(table_name)
    return (
        f"{s3_prefix.rstrip('/')}/event_date={event_date}/{table_name}.parquet"
    )


def existing_object_is_valid(
    s3_client,
    bucket: str,
    key: str,
    source_table_id: str,
    source_rows: int,
) -> bool:
    try:
        existing = s3_client.head_object(Bucket=bucket, Key=key)
    except ClientError as error:
        error_code = str(error.response.get("Error", {}).get("Code", ""))
        if error_code in {"404", "NoSuchKey", "NotFound"}:
            return False
        raise

    metadata = existing.get("Metadata", {})
    return (
        metadata.get("source-table") == source_table_id
        and metadata.get("source-rows") == str(source_rows)
        and bool(metadata.get("sha256"))
        and int(existing.get("ContentLength", 0)) > 0
    )


def extract_table(
    *,
    table_name: str,
    args: argparse.Namespace,
    bq_client: bigquery.Client,
    s3_client,
) -> str:
    source_table_id = f"{args.source_dataset}.{table_name}"
    s3_key = s3_key_for(table_name, args.s3_prefix)
    source_table = bq_client.get_table(source_table_id)
    source_rows = int(source_table.num_rows)

    print()
    print(f"Source: {source_table_id}")
    print(f"Target: s3://{args.bucket}/{s3_key}")
    print(f"BigQuery metadata rows: {source_rows:,}")

    if existing_object_is_valid(
        s3_client, args.bucket, s3_key, source_table_id, source_rows
    ):
        print("SKIPPED: existing S3 object has valid source metadata.")
        return "skipped"

    if not args.overwrite:
        try:
            s3_client.head_object(Bucket=args.bucket, Key=s3_key)
        except ClientError as error:
            error_code = str(error.response.get("Error", {}).get("Code", ""))
            if error_code not in {"404", "NoSuchKey", "NotFound"}:
                raise
        else:
            raise RuntimeError(
                f"S3 object exists but validation metadata does not match: "
                f"s3://{args.bucket}/{s3_key}. Review it or rerun with --overwrite."
            )

    # list_rows + BigQuery Storage API reads the table directly. It does not run
    # a SELECT query, and Arrow preserves repeated/nested fields.
    arrow_table = bq_client.list_rows(source_table).to_arrow(
        create_bqstorage_client=True
    )
    if arrow_table.num_rows != source_rows:
        raise RuntimeError(
            f"Row-count mismatch: BigQuery={source_rows:,}, Arrow={arrow_table.num_rows:,}"
        )

    with tempfile.TemporaryDirectory(prefix="game_analytics_raw_") as temp_dir:
        parquet_path = Path(temp_dir) / f"{table_name}.parquet"
        pq.write_table(
            arrow_table,
            parquet_path,
            compression="snappy",
            use_dictionary=True,
        )

        # Explicitly close ParquetFile before TemporaryDirectory cleanup.
        # Windows will not delete a file while PyArrow still holds its handle.
        parquet_file = pq.ParquetFile(parquet_path)
        try:
            parquet_rows = parquet_file.metadata.num_rows
        finally:
            parquet_file.close()
        if parquet_rows != source_rows:
            raise RuntimeError(
                f"Row-count mismatch: BigQuery={source_rows:,}, Parquet={parquet_rows:,}"
            )

        file_size = parquet_path.stat().st_size
        checksum = sha256_file(parquet_path)
        print(f"Parquet rows: {parquet_rows:,}")
        print(f"Parquet size: {file_size / (1024 * 1024):,.2f} MiB")
        print(f"SHA-256: {checksum}")

        s3_client.upload_file(
            str(parquet_path),
            args.bucket,
            s3_key,
            ExtraArgs={
                "Metadata": {
                    "source-table": source_table_id,
                    "source-rows": str(source_rows),
                    "sha256": checksum,
                }
            },
        )

        uploaded = s3_client.head_object(Bucket=args.bucket, Key=s3_key)
        if uploaded["ContentLength"] != file_size:
            raise RuntimeError(
                "S3 size mismatch: "
                f"local={file_size:,}, S3={uploaded['ContentLength']:,}"
            )

        uploaded_metadata = uploaded.get("Metadata", {})
        if uploaded_metadata.get("sha256") != checksum:
            raise RuntimeError("S3 checksum metadata does not match the local file.")

    print("Upload and validation completed successfully.")
    print(f"S3 URI: s3://{args.bucket}/{s3_key}")
    return "uploaded"


def main() -> None:
    args = parse_args()
    bq_client = bigquery.Client(project=args.billing_project)
    s3_client = boto3.client("s3", region_name=args.aws_region)

    if args.all_tables:
        table_names = sorted(
            table.table_id
            for table in bq_client.list_tables(args.source_dataset)
            if TABLE_PATTERN.fullmatch(table.table_id)
        )
    else:
        table_names = [args.table]

    if not table_names:
        raise RuntimeError("No events_YYYYMMDD tables were found.")

    print(f"Tables selected: {len(table_names)}")
    uploaded_count = 0
    skipped_count = 0

    for index, table_name in enumerate(table_names, start=1):
        print(f"\n[{index}/{len(table_names)}] {table_name}")
        result = extract_table(
            table_name=table_name,
            args=args,
            bq_client=bq_client,
            s3_client=s3_client,
        )
        if result == "uploaded":
            uploaded_count += 1
        else:
            skipped_count += 1

    print()
    print("Batch completed successfully.")
    print(f"Uploaded: {uploaded_count}")
    print(f"Skipped as already valid: {skipped_count}")


if __name__ == "__main__":
    main()
