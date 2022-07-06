variable "aws_region" {
  default     = "ap-northeast-3"
  description = "The AWS region to create things in."
}

variable "file_name_get_user" {
  default = "./dist/getUser.zip"
}

variable "file_name_put_user" {
  default = "./dist/putUser.zip"
}