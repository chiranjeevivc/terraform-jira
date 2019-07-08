terraform {
  backend "s3" {
    bucket = "bucket_name"
    key    = "folder_name/terraform.tfstate"
    region = "region"
  }
}