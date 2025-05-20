provider "aws" {
  region  = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

#[1] 1 references
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name= "production"
  }
}

#[2] create internet GATEWAY
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

}

#[3] create custom route table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0" #모든 트래픽이 이 경로(IPv4)로 지나감
    gateway_id = aws_internet_gateway.gw.id 
  }

  route {
    ipv6_cidr_block        = "::/0" #IPv6
    egress_only_gateway_id = aws_internet_gateway.gw.id  
  }

  tags = {
    Name = "prod"
  }
}

#[4] create a subnet
resource "aws_subnet" "subnet-1" {
    vpc_id     = aws_vpc.prod-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
      Name= "prod-subnet"
    }
}

#[5] subnet을 routing table과 연결
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#[6] security group 설정(allow port 22,80,443) 
# 웹 트래픽만 허용하는 보안설정
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #누구나 접근할 수 있는 웹 서버/ 1.1.1.1/32로 설정하면 특정 ip만 접근가능한 것 
  }
    ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #누구나 접근할 수 있는 웹 서버/ 1.1.1.1/32로 설정하면 특정 ip만 접근가능한 것 
  }
    ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #누구나 접근할 수 있는 웹 서버/ 1.1.1.1/32로 설정하면 특정 ip만 접근가능한 것 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #모든 프로토콜을 의미 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


# [7] network interface with an ip int the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id  #서브넷에 할당
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

#[8] assign an elastic ip to the network interface created in step 7
# 공용 ip 에 모든 사용자가 접근할 수 있도록 함/ internet gw가 먼저 있어야 함(모든 공용 ip는 게이트웨이를 지나기 땨문문) 
resource "aws_eip" "one" {
  domain = "vpc"
  network_interface         =aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw] #전체 객체를 참조하므로 id를 붙이지 않아도됨됨
}

#[9] create ubuntu server 

resource "aws_instance" "web-server-instance" {
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a" #서브넷에 적용한 가용영역과 동일한 것으로 입력 
  key_name= "main-key"  #실제로 장치에 엑세스할 수 있도록 해당 키 쌍을 참조해야함
  
  network_interface {
    device_index = 0 # 이 장치와 연결된 첫 번째 네트워크 인터페이스(인덱스는 0부터 시작하니까)
    network_interface_id = aws_network_interface.web-server-nic.id
    }

    # 설치하려는 것들 명령어를 적어두면 설치함 
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
                
    tags={
        Name="web-server"
    } 
}
