data "aws_ami" "coockieAmi" {
  most_recent = true
  filter {
    name = "name"
    values = [ "myAmi" ]
  }
}

data "aws_security_group" "coockieSg" {
  filter {
    name = "group-name"
    values = [ "myGroup" ]
  }
}

resource "aws_lb" "myLb" {
  name = "coockieLb"
  load_balancer_type = "application"
  
}