terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_key_pair" "devops_key" {
  key_name   = "devops-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7fuGaMLymGTNLvo508DAlpVSWCLf/wuv9IpjROdVfzQytOVBzlgaDjmSR+TMew0cQz2qKEBkzblhS2wKNpQ3SsWw7VdRV9V43dHyAzubmA0jzyk/C9xEOTpyjCs9OsDUEADX/eJ39dd5rpJjls3hKfxIl4cQTqEjx9R4O21zEhJ+sn4yomEN1OSEilloacZnfJndedvUY7DSAtKveSS9Sz3iGyN5t4e9dDIKbvpz2K1WEEJ8gMbCi4DdWlBofW0I9lIAT3e7zscs2mlKVM9NEo0Ch2Bmr79kDD2aFh/K1lyDeCsjXnYfs8mG66yeDSJJUbam4qSKPBXwEF+h/p8yPuW/M+yGvKn+ptvW7K4iqSLYif2UpBv8eBlA09gowcETk+dm9FCv9snEOX8rrAdWB3npHHMoMYwrJbptcLSZEZPWCAWR4Wq27s1TDwugB6AHUhjKcMzzFbpAmwQ1dWzMkZWLhmNwVfA8lF2LkSNKM8j29ASN57rnPxtmhiydzg6zpkHeVZ9aW3Sjnm4z0UBN/EjvVluWCa3nx5w5+LfB49mnI0JDnOCF1qOhmsB7dNANaZyHLGwZUyv9q3OqLLpGpZjp/aChy2Vxj8OoZyi9ogyUxCrJlFqbC9xAF2fmcS5NznL3EpFgCW8IyGi9U+QIyh4xpImlbnlHVLH8omJzJHQ== alito@ASUSROG"
}

resource "aws_security_group" "web_sg" {
  name        = "devops-web-sg"
  description = "SSH ve web trafigine izin ver"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
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

resource "aws_instance" "web_server" {
  ami                    = "ami-0a87a69d69fa289be"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "devops-tutorial-server"
  }
}

output "server_public_ip" {
  value = aws_instance.web_server.public_ip
}