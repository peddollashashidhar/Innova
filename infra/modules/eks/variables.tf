variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.27"
}

variable "subnets" {
  type = list(string)
}

variable "node_groups" {
  type = map(any)
}
