# Jenkins sunucusu icin guvenlik grubu
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Jenkins sunucusu icin guvenlik kurallari"

  # SSH (22) - sunucuya baglanmak icin
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins web arayuzu (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Cikis trafigine tam izin
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jenkins sunucusu 
resource "aws_instance" "jenkins_server" {
  ami                    = "ami-0a87a69d69fa289be"
  instance_type          = "t3.small"
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  tags = {
    Name = "jenkins-server"
  }
}

# Jenkins sunucusunun IP'sini ciktida goster
output "jenkins_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}