provider "aws" {
  region     = "us-east-2"
}

# 1. توليد الـ Private Key (ملف الـ .pem)
resource "tls_private_key" "marwan_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. إنشاء الـ Key Pair في AWS باستخدام الـ Public Key المولد
resource "aws_key_pair" "generated_key" {
  key_name   = "marwan-automation-key"
  public_key = tls_private_key.marwan_key.public_key_openssh
}

# 3. حفظ الـ Private Key على جهازك عشان تقدر تدخل SSH
resource "local_file" "ssh_key" {
  filename = "${path.module}/marwan-automation-key.pem"
  content  = tls_private_key.marwan_key.private_key_pem
}

# 4. Security Group (Corrected Version)
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg_marwan"
  description = "Allow SSH, HTTP, and Jenkins"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. EC2 Instance
resource "aws_instance" "jenkins_master" {
  ami           = "ami-09040d770ffe2224f" # Ubuntu 22.04 LTS for us-east-2
  instance_type = "t3.micro" # <--- غير دي لـ t3.micro عشان الـ Free Tier في Ohio
  key_name      = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  tags = { Name = "Jenkins-Master-Marwan" }
}
output "jenkins_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}