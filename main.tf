resource "aws_instance" "web_server" {
	ami = "i-0f98975e92e7b49f7"
	instance_type = "t2.micro"
	tags = {
		Name = "web-server"}

}

resource "aws_s3_bucket" "artifact" {
	bucket = "tiltil-2"

}

resource "aws_iam_role" "codedeploy_role" {
  name = "IAM_CODE_DEPLOY"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "codedeploy_attach" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}


resource "aws_codedeploy_app" "my_app" {
  name = "tiltil-2-code-deploy"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "my_group" {
  app_name              = aws_codedeploy_app.my_app.name
  deployment_group_name = "tiltile-2-code-deploy" # 실제 콘솔 기준

  service_role_arn = "arn:aws:iam::461536490333:role/IAM_CODE_DEPLOY"

  deployment_config_name = "CodeDeployDefault.AllAtOnce"
 }


