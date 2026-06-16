output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "backend_ventas_ecr_url" {
  value = aws_ecr_repository.backend_ventas.repository_url
}

output "backend_despachos_ecr_url" {
  value = aws_ecr_repository.backend_despachos.repository_url
}

output "frontend_ecr_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.eks.name
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}
