"""
ETL Job — runs inside an EKS pod, triggered by MWAA KubernetesPodOperator.

What it does:
  1. Reads sample source data (simulated inline — no upstream dependency needed)
  2. Transforms it (adds a timestamp and job metadata)
  3. Writes the result to the S3 data lake under processed/etl-results/

Environment variables (injected by KubernetesPodOperator):
  DATA_LAKE_BUCKET    — S3 bucket name (e.g. data-platform-dev-data-lake)
  AWS_DEFAULT_REGION  — AWS region (e.g. ap-south-1)
"""

import json
import os
import boto3
from datetime import datetime, timezone


def extract():
    """Simulate extracting source data."""
    return [
        {"user_id": 1, "event": "login",    "value": 1},
        {"user_id": 2, "event": "purchase",  "value": 250},
        {"user_id": 3, "event": "logout",    "value": 0},
    ]


def transform(records):
    """Add job metadata to each record."""
    run_ts = datetime.now(timezone.utc).isoformat()
    return [
        {**record, "processed_at": run_ts, "job": "etl-job", "source": "eks-pod"}
        for record in records
    ]


def load(records, bucket, region):
    """Write transformed records to S3 data lake."""
    s3 = boto3.client("s3", region_name=region)

    run_id  = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    s3_key  = f"processed/etl-results/run-{run_id}.json"
    payload = json.dumps(records, indent=2)

    s3.put_object(
        Bucket=bucket,
        Key=s3_key,
        Body=payload,
        ContentType="application/json",
    )

    print(f"[ETL] Wrote {len(records)} records to s3://{bucket}/{s3_key}")


def main():
    region = os.environ.get("AWS_DEFAULT_REGION", "ap-south-1")
    bucket = os.environ.get("DATA_LAKE_BUCKET", "data-platform-dev-data-lake")

    print("[ETL] Starting job")
    records = extract()
    print(f"[ETL] Extracted {len(records)} records")

    records = transform(records)
    print(f"[ETL] Transformation complete")

    load(records, bucket, region)
    print("[ETL] Job completed successfully")


if __name__ == "__main__":
    main()
