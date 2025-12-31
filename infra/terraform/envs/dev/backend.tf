terraform {
  backend "s3" {
    bucket         = "tfstate-cloud-network-segmentation-nisha-01"
    key            = "cloud-network-segmentation/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}