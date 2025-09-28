terraform {
  backend "s3" {
    bucket         = "samuel-desafio-acs-tfstate-833565098889"
    key            = "atlantis/eks.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
