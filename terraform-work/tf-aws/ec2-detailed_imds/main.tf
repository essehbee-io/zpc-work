## AWS Create Instance with no Detailed monitoring and no IMDSv2

resource "aws_instance" "bar" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  name          = "tf-test-instance"
  instance_type = "t2.micro"
  monitoring    = false
  tags = {
    Name = "tf-test-instance"
  }

  metadata_options {
      http_endpoint = "disabled"    
      http_tokens = "required"
  }
}

