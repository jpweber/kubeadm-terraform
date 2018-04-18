# Kubedadm Kubernetes cluster with Terraform

Create test kubernetes cluster using kubeadm and terraform on AWS.  
**Not prodcution safe** This cluster has pretty lax security groups to make things for testing easiser. It is meant to create short lived clusters that will be torn down and not live longer than a day so security is not as great of a concern. It is not HA, etcd runs as a single self hosted pod. 

## Getting Started

The tfvars file has a kubeadm token in it. If you wish to generate your own fresh token a small go program is included that can provide this for you. 

```shell
# Generate the token required by kubeadm
$ go run token.go
```
then take the output and place it in your tfvars file. 

```shell 
# Apply the terraform configuration
$ terraform apply
```

For tear down:

```shell
$ terraform destroy
```

After the terraform plan has been executed successful, the ip of your control plane node will be in the output.  You can then  `ssh` to the control plane node. Assuming an ubuntu ami was used for this example the ssh user will be `ubuntu`

```shell
ssh ubuntu@18.180.130.30

```


After this, you can visit the http://kubernetes.io/docs/user-guide/, to learn more.

## What do you need

- [Terraform](https://www.terraform.io) v0.7 or higher
- AWS API credentials through the `AWS_PROFILE` environment variable. [See here](https://www.terraform.io/docs/providers/aws/index.html) environment variables and shared credentials file sections
- Go 1.5 or higher

#### Mac OS, you can install all the dependencies as follow:

```
brew install terraform awscli go
```

## Description

This will create:

- a new VPC at AWS `us-east-2` (this is the default, can be overridden) using with 3 public subnets, one for each availability zone.
- an autoscaling group to hold the Kubernetes control plane.
- an autoscaling group to hold the nodes (by default just 2 nodes).

All instances are setup with docker and kubeadm using cloud init.

## Configuration

Look at variables.tf to see all the variables that can be overriden via your tfvars file. The defaults are good for a basic setup. Please note, this plan assumes the use of route53 to create dns entries for Load balancers. It can work with out that but areas that use route53 will need to be commented outor removed