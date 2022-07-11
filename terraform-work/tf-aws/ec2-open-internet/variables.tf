variable "aws_region" {
  description = "The AWS region to deploy the EC2 instance in."
  default   = "us-east-1"
}


variable "instance_type" {
  description = "instance type for ec2"
  default   =  "t2.micro"
}