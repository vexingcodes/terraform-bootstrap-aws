# Terraform Bootstrap AWS

These instructions aim to take you from a fresh AWS account to using Terraform with all state stored in S3. This should
allow you to have 100% infrastructure as code with as few manual steps as possible and without keeping any secrets in
the source code itself.

# Prerequisites

This readme assumes you have installed Terraform and the AWS CLI.

# Bootstrapping Terraform

## Initial Access Credentials

As a general policy you want to do as little as possible as the root user in AWS. Here, the initial resources required
for bootstrapping Terraform will be created using the root acount, but then after that a special `terraform` user will
perform all resource manipulation. First, we need to create access credentials on the root account that Terraform can
use to create the initial resources.

From the [AWS Management Console](https://console.aws.amazon.com), go to
[Manage Security Credentials](https://console.aws.amazon.com/iam/home#/security_credentials), usually available from the
drop-down that says "Delete your root access keys". On that page, expand the area for "Access keys (access key ID and
secret access key)", then click "Create New Access Key" and you will be shown a page with an "Access Key ID" and "Secret
Access Key". These access credentials will be used by Terraform to create the initial resources. Once the resources are
created, we will delete those credentials so they can't be used anymore.
 
## Configure AWS CLI

Issue the command `aws configure`. When prompted, enter the "AWS Access Key ID" and "AWS Secret Access Key" you took
note of earlier when creating the access credentials. Note that even if you've configured MFA on your root account, you
won't actually need to use MFA for the AWS CLI when using these access keys.

Even if you set a default region in `aws configure` Terraform still complains unless you set the `AWS_DEFAULT_REGION`
environment variable, so set it like this from the `dev-env` shell:

```bash
export AWS_DEFUALT_REGION=us-east-2
```

## Set Terraform Variables

Create a Terraform file with a `module` entry, for example `test.tf` would have the following contents:

```
module "bootstrap" {
  source    = "github.com/vexingcodes/terraform-bootstrap-aws"
  s3_bucket = "aaronandjamiephotosterraform"
}
```

Minimally, you must provide your own value for `s3_bucket` since S3 buckets must have globally unique names.

There are additional variables you can change. See `variables.tf` for more information. None of the values entered here
are particularly secret, so this Terraform file is meant to be checked in to source control.

Once your Terraform file is complete, issue the following command to initialize Terraform.

```bash
terraform init
```

## Create Initial Resources

Now we are ready to create the resources in AWS necessary to store the Terraform state. These initial resources include:

* A terraform IAM group and user under which Terraform operations will occur.
* An S3 bucket that stores the state files themselves.
* A DynamoDB that locks the state files so only one entity can be working with them at a time.
* An AWS Secrets Manager secret that can be used to get all of the information to run Terraform as the `terraform` user
  and store the remote state in the S3 backend.

To create these resources run the following command from the `/src/bootstrap` directory in the `dev-env` container shell.

```bash
terraform apply
```

Terraform will determine what needs to be created and show you a list. It will also prompt you to confirm by typing
`yes` before actually creating any resources.

# Tearing Down Bootstrap Resources

Terraform should be able to tear down any resources that it sets up (or that are manually imported). However, Terraform
does not expect to tear down the resources that are currently storing the state remotely, so care needs to be taken when
destroying the bootstrapping resources. Since these resources started life with locally-stored Terraform state, that's
how they'll have to end their life as well. Luckily, Terraform has some built-in commands that make it easy to
transition back to local state:

```bash
terraform state pull > terraform.tfstate
rm config_override.tf
terraform init
```

These commands will pull the state file down from S3 and store it locally in `terraform.tfstate`. Then we remove the
`config_override.tf` file that pointed Terraform to use the S3 backend. Finally, `terraform init` tells Terraform to
reinitialize, and at this point it will notice that we've switched backends from S3 to local state storage.

At this point, the bootstrapping resources can be destroyed using the `terraform destroy` command.
