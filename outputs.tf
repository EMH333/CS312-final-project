output "minecraft_public_ip" {
  description = "Public IP address of the Minecraft Server"
  value       = aws_instance.minecraft_server.public_ip
}
