terraform {
  backend "s3" {
    bucket         = "demoapp-terraform-state"
    region         = "ap-southeast-1"
    dynamodb_table = "TikalTerraformStatelock"
    key            = "main/terraform-tikal.tfstate"
  }
}
