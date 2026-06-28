# k3s sunucusu icin guvenlik grubu
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-sg"
  description = "k3s sunucusu icin guvenlik kurallari"

  # SSH (22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Uygulama portu (NodePort araligi - Kubernetes disari bu araliktan acar)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # k3s API portu (6443) - ileride lazim olabilir
  ingress {
    from_port   = 6443
    to_port     = 6443
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

# k3s sunucusu
resource "aws_instance" "k3s_server" {
  ami                    = "ami-0a87a69d69fa289be"
  instance_type          = "t3.small"
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]

  tags = {
    Name = "k3s-server"
  }
}

output "k3s_public_ip" {
  value = aws_instance.k3s_server.public_ip
}