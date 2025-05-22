terraform {
  backend "s3" {
    bucket = "whs-terraform-statebucket"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
