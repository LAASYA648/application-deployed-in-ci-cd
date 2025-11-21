output "cluster_id" {
  value = aws_eks_cluster.sakshith_01.id
}

output "node_group_id" {
  value = aws_eks_node_group.sakshith_01.id
}

output "vpc_id" {
  value = aws_vpc.sakshith_01_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.sakshith_01_subnet[*].id
}

output "server_01_public_ip" {
  value = aws_instance.server_01.public_ip
}