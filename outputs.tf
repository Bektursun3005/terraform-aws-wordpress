output "ec2_public_ip" {
  description = "Public IP of the WordPress EC2 instance."
  value       = module.webserver.public_ip
}

output "wordpress_url" {
  description = "URL of the WordPress installation page."
  value       = "http://${module.webserver.public_ip}/blog"
}

output "rds_endpoint" {
  description = "Endpoint of the RDS MySQL instance (reachable only from wordpress-sg)."
  value       = module.rds.endpoint
}
