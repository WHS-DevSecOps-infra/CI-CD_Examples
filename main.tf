provider "aws" {
  region = "ap-northeast-2"  # 서울 리전
}

#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "whs" {
  bucket = "whs-terraform-statebucket"
}


# resource "aws_instance" "example" {
#   ami           = "ami-0d5bb3742db8fc264" 
#   instance_type = "t2.micro"

#   tags = {
#     Name = "WHS-instance"
#   }
# }
