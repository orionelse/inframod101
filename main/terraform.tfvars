profile                 = "Orion"
vendor_name             = "Orion"
region                  = "ap-southeast-1"
bucket                  = "demoapp-terraform-state"
primary_domain          = "orionelse.io"
dynamodb_table          = "DemoAppTerraformStatelock"
env                     = "tf-customer1"
instance_count          = 1
key_name                = "client-key"
server1_instance_type   = "t2.micro"
server1_ami_id          = "ami-0b89f7b3f054b957e"
server2_instance_type   = "t2.micro"
server2_ami_id          = "ami-0b89f7b3f054b957e"
cluster_version         = "1.14"
vpc_cidr_block          = "10.0.58.0/23"
profiling_vpc_id        = "vpc-076d4aa84edf987e1"
profiling_vpc_cdir      = "10.16.0.0/16"
operators = [
  "orionuser",
]
WORKSPACE                  = "."
