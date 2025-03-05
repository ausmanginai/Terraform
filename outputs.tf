output "ec2_public_ip" {
    value = module.myapp-server.instance.public_ip   // first need configure output in the child module, then reference here
}