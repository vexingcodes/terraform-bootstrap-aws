variable "iam_group" {
  type    = string
  default = "terraform"
}

variable "iam_user" {
  type    = string
  default = "terraform"
}

variable "secret" {
  type    = string
  default = "terraform"
}

variable "dynamodb" {
  type    = string
  default = "terraform"
}

variable "s3_bucket" {
  type = string
}
