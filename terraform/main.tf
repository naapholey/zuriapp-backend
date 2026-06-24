provider "aws" {
  region = "us-east-1"
}

# Security Group for K3s
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-security-group"
  description = "Allow Kubernetes traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Limit this in production
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # K3s API Server
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTP Web Traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch Template for ASG
resource "aws_launch_template" "k3s_tpl" {
  name_prefix   = "k3s-tpl-"
  image_id      = "ami-0b6d9d3d33ba97d99" # Ubuntu 22.04 LTS AMI (Update for your region)
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.k3s_sg.id]
  }

  # Self-healing & Auto-provisioning via User Data
  user_data = base64encode(<<-EOF
              #!/bin/bash
              curl -sfL https://k3s.io | sh -s - --write-kubeconfig-mode 644
              EOF
  )
}

# Auto Scaling Group for Self-Healing
resource "aws_autoscaling_group" "k3s_asg" {
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = ["subnet-0b4ecf06e513c8d0d", "subnet-0f31392a0f9b0932a"] # Replace with your subnet IDs

  launch_template {
    id      = aws_launch_template.k3s_tpl.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "k3s-cluster-node"
    propagate_at_launch = true
  }
}
