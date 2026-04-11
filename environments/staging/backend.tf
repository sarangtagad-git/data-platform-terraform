terraform {
  backend "s3" {
    bucket = "data-platform-tf-state-sarang"
    key    = "staging/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}
