output "vpc1_details" {
  value = aws_vpc.vpc1
}

output "subnet1_details" {
  value = aws_subnet.subnet1
}

#output "private_key_details" {
#  value = tls_private_key.myec2_KP_priv_Key.private_key_pem
#  sensitive = true
#}