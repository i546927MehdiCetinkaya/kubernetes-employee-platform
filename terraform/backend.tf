terraform {
  backend "gcs" {
    # Configuration should be provided via backend config file or CLI flags
    # Example: terraform init -backend-config="bucket=BUCKET_NAME" -backend-config="prefix=terraform/state"
    # 
    # Required backend configuration:
    # - bucket: GCS bucket name for Terraform state (e.g., PROJECT_ID-terraform-state)
    # - prefix: State file prefix (e.g., terraform/state)
    # 
    # The bucket should be created manually before running terraform init:
    # gsutil mb -p PROJECT_ID -c STANDARD -l europe-west4 gs://PROJECT_ID-terraform-state
    # gsutil versioning set on gs://PROJECT_ID-terraform-state
  }
}
