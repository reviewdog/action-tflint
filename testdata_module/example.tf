module "random_name" {
  source = "./random"
}

resource "aws_instance" "foo" {
  ami           = "ami-0ff8a91507f77f867"
  instance_type = "t1.2xlarge" # invalid type!

  tags = {
    Name = module.random_name.result
  }
}
