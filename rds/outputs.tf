output "endpoint" {
  description = "Connection endpoint of the RDS instance."
  value       = aws_db_instance.mysql.endpoint
}
