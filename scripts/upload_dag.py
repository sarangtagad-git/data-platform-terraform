import sys
import os
import boto3
sys.path.insert(0, os.path.dirname(__file__))
from validate_dag import validate_syntax, validate_dag_definition


def upload_to_s3(filepath, bucket_name):
    """
    Uploads a DAG file to the dags/ prefix in the specified S3 bucket.
    Returns True on success, False on failure.
    """
    s3 = boto3.client("s3")
    filename = os.path.basename(filepath)   # extract just the filename from full path
    s3_key = f"dags/{filename}"             # upload under dags/ folder in S3

    try:
        s3.upload_file(filepath, bucket_name, s3_key)
        print(f"Uploaded {filename} to s3://{bucket_name}/{s3_key}")
        return True
    except Exception as e:
        print(f"Upload failed: {str(e)}")
        return False


def main(filepath, bucket_name):
    """
    Validates the DAG file first — only uploads if all checks pass.
    Exits with code 1 on any failure to stop CI/CD pipeline.
    """
    print(f"Validating {filepath}...")

    # run syntax check — catches Python syntax errors before upload
    syntax_okay, syntax_error = validate_syntax(filepath)
    if not syntax_okay:
        print(f"Syntax error: {syntax_error}")
        sys.exit(1)

    # run DAG definition check — ensures file has Airflow DAG defined
    dag_def_okay, dag_def_error = validate_dag_definition(filepath)
    if not dag_def_okay:
        print(f"DAG definition error: {dag_def_error}")
        sys.exit(1)

    print("Validation passed — uploading to S3...")

    # upload only after all validations pass
    success = upload_to_s3(filepath, bucket_name)
    if not success:
        sys.exit(1)


if __name__ == "__main__":
    # expects exactly 2 arguments: dag file path and bucket name
    if len(sys.argv) != 3:
        print("Usage: python upload_dag.py <filepath> <bucket_name>")
        sys.exit(1)

    filepath = sys.argv[1]
    bucket_name = sys.argv[2]
    main(filepath, bucket_name)
