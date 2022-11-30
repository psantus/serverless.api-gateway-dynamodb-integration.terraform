variable "aws_region" {
  description = "Default region where to deploy resources"
  type        = string
}

variable "profile" {
  description = "AWS credentials/profile"
  type        = string
}

variable "enable_logging" {
  description = "Whether to enable logging. Because logging can be expensive, we may need to restrict API logging"
  type        = bool
}

