resource "aws_subnet" "example" {
  count = 2

  availability_zone = ap-south-1-a[count.index]
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  vpc_id            = aws_vpc.main.id
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

#3 security group

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# attach aws-security group to eks node group
resource "aws_launch_template" "eks_node_group_template" {
  name          = "eks-node-group-template"
  image_id      = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 EKS AMI ID, replace with the correct AMI
  instance_type = "t3.medium"  # Set your instance type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_tls.id]  # Attach the security group
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node-group-instance"
    }
  }
}

# securitygroup to nodegroup