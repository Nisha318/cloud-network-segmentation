data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = var.app_subnet_ids[0]
  vpc_security_group_ids      = [var.app_sg_id]
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y httpd
              echo "Cloud Network Segmentation: App Tier" > /var/www/html/index.html
              systemctl enable httpd
              systemctl start httpd
              EOF

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app"
  })
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.app.id
  port             = 80
}
