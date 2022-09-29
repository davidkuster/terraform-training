# O'Reilly Terraform Training

Raju Gandhi
@looselytyped
raju.gandhi@gmail.com
https://github.com/looselytyped/terraform-workshop/

[Slides](terraformcloud719221663171366112.pdf)



## Notes

Providers are compilers for your TF code, specific to the cloud you're working with
- AWS provider
- GCP provider
- etc

Providers translate your code into something the client understands
- this then uses the client SDK that already exists for that client/provider/target/etc


TF is written in HCL (Hashicorp Configuration Language)


https://github.com/hashicorp/terraform-provider-aws/ - OSS
- 3.4k issues and 409 open PRs (eek!)



### Variables

Env vars are case sensitive.
```bash
export TF_VAR_aws_access_key=xyz123etc
export TF_VAR_aws_secret_key=etc321xyz
```
In a TF file:
```hcl
variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"
}
```
(Note that `terraform plan` can't run disconnected from AWS - it will hang.)

```hcl
variable "port" {
  description = "port to expose"
  type        = number
  default     = 8080
}
```

### Multiple files / directories

TF reads all `*.tf` files in a current dir. The contents can be organized in any way you like.

Apparently the ordering of resource definitions don't matter.

TF only runs in the dir you run in. It doesn't read subdirectories or parent dirs. This is a feature and not a bug.

### Structuring directories

Recommends having a folder per env
- base
  - base.tf
  - outputs.tf
- dev
  - main.tf
  - outputs.tf
  - providers.tf
  - variables.tf
  - **dev-specific terraform.tfstate file**
- modules
  - main.tf
  - outputs.tf
  - variables.tf
- prod
  - main.tf
  - outputs.tf
  - providers.tf
  - variables.tf
  - **prod-specific terraform.tfstate file**

Can then do an apply and a destroy per env, and not worry about touching your other env.

For instance, dev might get blown away and recreated weekly. Prod env is only touched when blue/green deploys happen, and never fully blown away.

Can also manage this differently:
- dev
  - networking
    - `*.tf`
  - services
    - `*.tf`
  - storage
    - `*.tf`

^ set up networking and storage because those are pretty consistent and don't change often. Whereas services are likely to churn often.

But now it's on you to manually remember what to run when. (Presumably could be automated.) But it's more surgical so you're touching less at a time.




### Tagging

His practices is to replicate the resource identifier as a tag for debugging purposes in the AWS console UI if needed. (Aka `exercise_0020` below.)

```hcl
resource "aws_instance" "exercise_0020" {
  ami           = "ami-085925f297f89fce1"
  instance_type = "t2.micro"

  tags = {
    Name      = "exercise_0020"
    Terraform = true
  }
}
```

### Outputs

Can return values from `terraform apply`.

```hcl
output "ip_addr" {
  value = aws_instance.exercise_0020.public_ip
}
```

### Data

Able to do lookups of things that already exist with `data` blocks.

Example of not hard-coding AMI value:

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    // note the wildcard at the end to ignore the publishing date ^
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical's AWS account ID
}
```
Then reference it:
```hcl
resource "aws_instance" "example" {
  ami = data.aws_ami.ubuntu.id
}
```

Note to use the "data sources" part of the doc, not the "resources" part:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami


### Static analysis tools

- terraform fmt
- terraform plan
- terraform validate
- [tflint](https://github.com/terraform-linters/tflint)
  - does deeper investigation than `validate` but it's slower since it's actually interacting with AWS

^ can use these in ci pipelines (maybe fail if `terraform fmt` needs to be run...)


### Testing

- terratest
  - https://terratest.gruntwork.io
  - https://github.com/gruntwork-io/terratest
  - steps
    - write unit tests in Go
    - apply
    - verify/assert
    - destroy
  - only do this in a sandbox env!
  - there is a cost associated to this
- Sentinel
  - commercial tool from Hashicorp

### Other tools

- Terragrunt
  - CLI usage is easier
  - multi-AWS (regions?) gets easier
  - retries
  - don't start with this, wait unti you feel the pain of scale

- Ansible
  - can orchestrate TF


### Workflow

Only one branch can reflect reality
- don't have a branch for dev and a branch for prod
- only trunk should be deploying any infra (to dev/QA/prod/etc)
- saying 1 branch because "state file", but different envs have different state files... :thinking_face:

Testing should run against sandbox env
- with a separate state file
- every branch gets its own state file

When done testing merge to trunk
- that uses the real state files (aka "golden master"?) to update the real envs
