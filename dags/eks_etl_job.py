"""
eks_etl_job — DAG that runs an ETL container on EKS via KubernetesPodOperator.

Flow:
    run_etl_on_eks  (single task)

How it works:
    1. MWAAKubernetesPodOperator.execute() fetches the EKS kubeconfig from
       Secrets Manager and writes it to /tmp on the Airflow worker.
    2. KubernetesPodOperator connects to EKS using that kubeconfig.
    3. EKS creates a pod in the 'airflow' namespace, pulls the etl-job image
       from ECR, and runs it.
    4. The pod writes results to S3 data lake and exits.
    5. Airflow streams pod logs and cleans up the pod on completion.

Prerequisites (one-time setup):
    kubectl apply -f kubernetes/airflow-rbac.yaml
    (creates the 'airflow' namespace + RBAC for mwaa-user on EKS)
"""

import json
import yaml
import boto3
from datetime import datetime

from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from kubernetes.client import models as k8s

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
REGION            = "ap-south-1"
KUBECONFIG_SECRET = "data-platform-dev-eks-kubeconfig"
KUBECONFIG_PATH   = "/tmp/eks-kubeconfig.yaml"

# Resolve account ID at parse time using STS (runs on the scheduler)
_account_id      = boto3.client("sts", region_name=REGION).get_caller_identity()["Account"]
ECR_IMAGE        = f"{_account_id}.dkr.ecr.{REGION}.amazonaws.com/data-platform-dev-etl-job:latest"
DATA_LAKE_BUCKET = f"data-platform-dev-data-lake-{_account_id}"


# ---------------------------------------------------------------------------
# Custom operator — fetches kubeconfig inside execute() so it runs on the
# same Celery worker that submits the pod (no cross-worker file sharing issue)
# ---------------------------------------------------------------------------
class MWAAKubernetesPodOperator(KubernetesPodOperator):
    """
    Extends KubernetesPodOperator to fetch the EKS kubeconfig from Secrets
    Manager before each execution. The kubeconfig is written to /tmp on the
    worker that runs this task, then the standard KubernetesPodOperator
    logic takes over to submit and monitor the pod on EKS.
    """

    def execute(self, context):
        sm = boto3.client("secretsmanager", region_name=REGION)
        secret = sm.get_secret_value(SecretId=KUBECONFIG_SECRET)
        kubeconfig = json.loads(secret["SecretString"])

        with open(KUBECONFIG_PATH, "w") as f:
            yaml.dump(kubeconfig, f)

        print(f"[MWAAKubernetesPodOperator] Kubeconfig written to {KUBECONFIG_PATH}")
        return super().execute(context)


# ---------------------------------------------------------------------------
# DAG
# ---------------------------------------------------------------------------
with DAG(
    dag_id="eks_etl_job",
    description="Run ETL container on EKS via KubernetesPodOperator",
    start_date=datetime(2024, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["eks", "etl", "kubernetes"],
) as dag:

    run_etl = MWAAKubernetesPodOperator(
        task_id="run_etl_on_eks",
        name="etl-job",
        namespace="airflow",
        image=ECR_IMAGE,
        image_pull_policy="Always",
        config_file=KUBECONFIG_PATH,
        service_account_name="etl-job-sa",
        env_vars=[
            k8s.V1EnvVar(name="DATA_LAKE_BUCKET", value=DATA_LAKE_BUCKET),
            k8s.V1EnvVar(name="AWS_DEFAULT_REGION", value=REGION),
        ],
        is_delete_operator_pod=True,   # clean up pod after completion
        get_logs=True,                 # stream pod logs to Airflow task logs
    )
