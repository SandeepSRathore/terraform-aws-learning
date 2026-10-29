# Generate an SSH key pair, upload the PUBLIC half to AWS,
# and save the PRIVATE half to a local file so you can SSH in.
#
# Heads-up: the private key is also stored in terraform.tfstate.
# That's fine for learning, but it's one reason state files must
# never be committed to git or shared.

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "ssh" {
  key_name   = "${var.name}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = "${path.module}/${var.name}-key.pem"
  file_permission = "0400" # ssh refuses keys that others can read
}
