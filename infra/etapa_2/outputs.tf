output "db_public_ip" {
  value = aws_instance.db.public_ip
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "frontend_ecr" {
  value = aws_ecr_repository.frontend.repository_url
}

output "backend_ventas_ecr" {
  value = aws_ecr_repository.backend_ventas.repository_url
}

output "backend_despachos_ecr" {
  value = aws_ecr_repository.backend_despachos.repository_url
}
