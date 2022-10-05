# inframod101

[1] Run 'base' for initial terraform foundation for each project
$ cd base
$ terraform init
$ terraform plan
$ terraform apply

[2] run 'main' for your aws services workload (as need)

$ terraform init
$ terraform workspace new tf-demoapp-dev
$ terraform workspace list
$ terraform workspace show                #current workspace 'select' to change from list
$ terraform init
$ terraform plan
$ terraform apply
$ terraform destroy