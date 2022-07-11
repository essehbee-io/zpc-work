## Create AWS EC2 Instance

resource "aws_instance" "webserver" {

  ami = "ami-09d56f8956ab235b3"
  instance_type = var.instance_type
  tags {
    Name = "tf-ec2-open-internet"
  }
  key_name = "zscc"
 vpc_security_group_ids = [aws_security_group.web-sg.id]
associate_public_ip_address = true
  root_block_device {
    volume_type = "gp2"
    volume_size = "30"
    delete_on_termination = false

}

 

  user_data = <<EOF

#!/bin/bash

sudo apt-get update

sudo apt-get upgrade -y

sudo apt-get install apache2 -y

sudo systemctl restart apache2

sudo chmod 777 -R /var/www/html/

cd /var/www/html/

sudo echo "<h1>This is our test website deployed using Terraform.</h1>" > index.html

EOF

  tags = {
    Name = "ExampleEC2Instance"
  }
}

output "IPAddress" {
  value = "${aws_instance.webserver.public_ip}"
}


resource "aws_security_group" "web-sg" {
  name = "badsg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
        from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}