provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "sakshith_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "sakshith_key_pair" {
  key_name   = "sakshith_01-key1"
  public_key = tls_private_key.sakshith_key.public_key_openssh
}

resource "local_file" "sakshith_private_key1" {
  filename = "${path.module}/sakshith_01-key1.pem"
  content  = tls_private_key.sakshith_key.private_key_pem
  file_permission = "0600"
}
 locals {
  ssh_key_name = aws_key_pair.sakshith_key_pair.key_name
}
variable "ssh_key_name" {
  description = "Name of the existing SSH key pair"
  type        = string
}

resource "aws_vpc" "sakshith_01_vpc" {
  cidr_block = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sakshith_01-vpc"
  }
}

resource "aws_subnet" "sakshith_01_subnet" {
  count = 2
  vpc_id = aws_vpc.sakshith_01_vpc.id
  cidr_block = cidrsubnet(aws_vpc.sakshith_01_vpc.cidr_block, 8, count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "sakshith_01-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "sakshith_01_igw" {
  vpc_id = aws_vpc.sakshith_01_vpc.id
  tags = {
    Name = "sakshith_01-igw"
  }
}

resource "aws_route_table" "sakshith_01_route_table" {
  vpc_id = aws_vpc.sakshith_01_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sakshith_01_igw.id
  }
  tags = {
    Name = "sakshith_01-route-table"
  }
}

resource "aws_route_table_association" "sakshith_01_association" {
  count = 2
  subnet_id = aws_subnet.sakshith_01_subnet[count.index].id
  route_table_id = aws_route_table.sakshith_01_route_table.id
}

resource "aws_security_group" "sakshith_01_cluster_sg" {
  vpc_id = aws_vpc.sakshith_01_vpc.id
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sakshith_01-cluster-sg"
  }
}

resource "aws_security_group" "sakshith_01_node_sg" {
  vpc_id = aws_vpc.sakshith_01_vpc.id
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sakshith_01-node-sg"
  }
}

resource "aws_eks_cluster" "sakshith_01" {
  name = "sakshith_01-cluster"
  role_arn = aws_iam_role.sakshith_01_cluster_role.arn
  vpc_config {
    subnet_ids = aws_subnet.sakshith_01_subnet[*].id
    security_group_ids = [aws_security_group.sakshith_01_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "sakshith_01" {
  cluster_name = aws_eks_cluster.sakshith_01.name
  node_group_name = "sakshith_01-node-group"
  node_role_arn = aws_iam_role.sakshith_01_node_group_role.arn
  subnet_ids = aws_subnet.sakshith_01_subnet[*].id
  scaling_config {
    desired_size = 3
    max_size = 3
    min_size = 3
  }
  instance_types = ["t3.small"]
  remote_access {
  ec2_ssh_key = local.ssh_key_name
  source_security_group_ids = [aws_security_group.sakshith_01_node_sg.id]
}
    tags = {
        Name = "sakshith_01-node-group"
  }
}

resource "aws_iam_role" "sakshith_01_cluster_role" {
  name = "sakshith_01-cluster-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "eks.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sakshith_01_cluster_role_policy" {
  role = aws_iam_role.sakshith_01_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "sakshith_01_node_group_role" {
  name = "sakshith_01-node-group-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sakshith_01_node_group_role_policy" {
  role = aws_iam_role.sakshith_01_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "sakshith_01_node_group_cni_policy" {
  role = aws_iam_role.sakshith_01_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "sakshith_01_node_group_registry_policy" {
  role = aws_iam_role.sakshith_01_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_instance" "server_01" {
  ami =  "ami-0360c520857e3138f"
  instance_type = "m7i-flex.large"
  subnet_id = aws_subnet.sakshith_01_subnet[0].id
  vpc_security_group_ids = [aws_security_group.sakshith_01_node_sg.id]
  key_name = local.ssh_key_name
  associate_public_ip_address = true
  user_data = file("userdata.sh")
  tags = {
    Name = "server-01"
  }
}

