variable "location" {
  description = "The Azure location where to deploy your resources too"
  type        = string
  default     = "East US 2"
}

variable "postfix" {
  description = "A postfix string to centrally mitigate resource name collisions"
  type        = string
  default     = "resource"
}

variable "username" {
  description = "The username to be provisioned into your VM"
  type        = string
  default     = "coder"
}

