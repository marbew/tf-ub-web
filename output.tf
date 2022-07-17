output "web_instance_ip" {
    value = aws_instance.tf-ubuntu.public_ip
}
