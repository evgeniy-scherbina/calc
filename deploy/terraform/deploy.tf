provider "aws" {
  profile    = "terraform"
  region     = var.region
}

resource "aws_key_pair" "ssh-login-key" {
  key_name   = "ssh-login-key"
  public_key = "${file("/Users/evgeniyscherbina/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "allow-ssh-login" {
  name        = "allow-ssh-login"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
  }

  ingress {
    from_port   = 8070
    to_port     = 8073
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami             = var.amis[var.region]
  instance_type   = "t2.micro"
  key_name        = "ssh-login-key"
  security_groups = ["allow-ssh-login"]

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.example.public_ip
      agent       = "false"
      private_key = "${file("/Users/evgeniyscherbina/.ssh/id_rsa")}"
    }

    source      = "haproxy.cfg"
    destination = "/tmp/haproxy.cfg"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.example.public_ip
      agent       = "false"
      private_key = "${file("/Users/evgeniyscherbina/.ssh/id_rsa")}"
    }

    inline = [
      # Install Golang
      "wget https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz",
      "tar -xzf go1.12.7.linux-amd64.tar.gz",
      "sudo mv go /usr/local",
      "echo 'export GOROOT=/usr/local/go' >> ~/.bash_profile",
      "echo 'export GOPATH=$HOME/go' >> ~/.bash_profile",
      "echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> ~/.bash_profile",
      "source ~/.bash_profile",

      # Clone and compile project
      "sudo yum install -y git",
      "git clone https://github.com/evgeniy-scherbina/calc.git /home/ec2-user/go/src/github.com/evgeniy-scherbina/calc",
      "go get -u github.com/golang/dep/cmd/dep",
      "cd /home/ec2-user/go/src/github.com/evgeniy-scherbina/calc && dep ensure",

      # Install docker and docker-compose
      "sudo yum install -y docker",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
      "sudo service docker start",

      # "sudo docker-compose up -d",

      "curl -L https://releases.hashicorp.com/nomad/0.9.3/nomad_0.9.3_linux_amd64.zip > nomad.zip",
      "sudo unzip nomad.zip -d /usr/bin",
      "curl -L https://releases.hashicorp.com/consul/1.4.4/consul_1.4.4_linux_amd64.zip > consul.zip",
      "sudo unzip consul.zip -d /usr/bin",

      "sudo yum install -y haproxy",
      # "echo ${file("haproxy.cfg")} >> /etc/haproxy/haproxy.cfg",
      # "cat /tmp/haproxy.cfg >> /etc/haproxy/haproxy.cfg",
      "sudo bash -c 'cat /tmp/haproxy.cfg >> /etc/haproxy/haproxy.cfg'",
      "sudo service haproxy start",

      "sudo nomad agent -dev &",
      "sudo consul agent -dev &",
      "sleep 5",
      "cd deploy/nomad && sudo nomad job run calc.nomad",
    ]
  }
}

output "debug" {
  value = "${file("haproxy.cfg")}"
}