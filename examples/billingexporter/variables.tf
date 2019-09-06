variable "aws_region" {
    type = "string"
    default = "us-east-1"
}

variable "aws_access_key" {
    type = "string"
}

variable "aws_secret_key" {
    type = "string"
}

variable "project" {
    type = "string"
}

variable "cloud_function_bucket" {
    type = "string"
}

variable "report_destination_bucket" {
    type = "string"
}