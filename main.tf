provider "aws" {
  region = "ap-northeast-2"  # 서울 리전
}

#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "whs" {
  bucket = "cloudfence-bucket"
}

