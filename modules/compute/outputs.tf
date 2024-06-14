output "app_asg" {
    value = aws_autoscaling_group.app_frontend
}

output "app_backend_asg" {
    value = aws_autoscaling_group.app_backend
}