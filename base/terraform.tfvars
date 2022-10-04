profile        = "tikal"
vendor_name    = "tikal"
region         = "ap-southeast-1"
bucket         = "demoapp-terraform-state"
primary_domain = "tikal.io"
dynamodb_table = "TikalTerraformStatelock"
env            = "tf-customer1"
operators = [
  "orionuser",
]
