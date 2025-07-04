terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# S3 버킷 생성
resource "aws_s3_bucket" "state_org" {
  bucket = "cloudfence-identity-bucket"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "identity"
  }
}

# 버킷 버전 관리
resource "aws_s3_bucket_versioning" "state_org_versioning" {
  bucket = aws_s3_bucket.state_org.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 버킷 소유권 제어
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.state_org.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

# 퍼블릭 접근 차단
resource "aws_s3_bucket_public_access_block" "state_org_block" {
  bucket                  = aws_s3_bucket.state_org.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 암호화를 위한 KMS 키
resource "aws_kms_key" "s3_key" {
  description         = "KMS key for S3 encryption"
  enable_key_rotation = true
}

# S3 버킷 서버 측 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.state_org.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

# 리소스 단위 Lock Table

locals {
  resources = [
    "cloudwatch",
    "firehose",
    "opensearch",
    "securitylake"
  ]
}

resource "aws_dynamodb_table" "resource_locks" {
  for_each     = toset(local.resources)
  name         = "${each.key}-identity-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID" 

  attribute {
    name = "LockID"
    type = "S"
  }

  # 서버 측 암호화 설정
  server_side_encryption {
    enabled = true # 서버 측 암호화 활성화
  }

  tags = {
    Name        = "${each.key} Lock Table"
    Environment = "identity"
  }
}