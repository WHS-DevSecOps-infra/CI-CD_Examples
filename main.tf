provider "aws" {
  region = "ap-northeast-2"
}

# EC2 인스턴스
resource "aws_instance" "web_server" {
  ami           = "ami-0c9c942bd7bf113a2"  # Amazon Linux 2 AMI (서울 리전 예시)
  instance_type = "t2.micro"

  tags = {
    Name = "web-server-2"
  }
}

# S3 버킷 (이름에 고유값 추가)
resource "aws_s3_bucket" "artifact" {
  bucket = "tiltil-2-artifact-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# IAM Role (권한 부족했던 부분)
resource "aws_iam_role" "codedeploy_role" {
  name = "yujin3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Role에 정책 연결
resource "aws_iam_role_policy_attachment" "codedeploy_attach" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# CodeDeploy App (중복된 이름에서 변경)
resource "aws_codedeploy_app" "my_app" {
  name              = "yujin3"
  compute_platform  = "Server"
}

# CodeDeploy 배포 그룹
resource "aws_codedeploy_deployment_group" "my_group" {
  app_name               = aws_codedeploy_app.my_app.name
  deployment_group_name  = "yujin3-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
}
