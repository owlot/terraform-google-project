#------------------------------------------------------------------------------------------------------------------------
#
# Generic variables
#
#------------------------------------------------------------------------------------------------------------------------
variable "prefix" {
  description = "Company naming prefix, ensures uniqueness of project ids"
  type        = string
}

#------------------------------------------------------------------------------------------------------------------------
#
# Project variables
#
#------------------------------------------------------------------------------------------------------------------------

variable "projects" {
  description = "Map of projects to be created. The key will be used as project id (in combination with the provided prefix)"
  type = map(object({
    cicd_project_id     = string
    gcp_project_name    = string
    gcp_billing_account = string
    gcp_folder_id       = optional(string, null)
    can_delete          = optional(bool, false)
    shared_vpc_host     = optional(bool, false)
    shared_vpc_service  = optional(string, null)
    roles               = optional(map(list(map(string))), {})
    services            = optional(list(string), [])
    labels              = optional(map(string), {})
    audit_log_config    = optional(map(map(map(map(string)))), {})
  }))
}

variable "default_services" {
  description = "Map of default services to be enabled for created projects. Will be merged with project specific provided services"
  type        = list(string)

  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudkms.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "default_labels" {
  description = "Map of default labels to be attached to created projects. Will be merged with project specific provided labels"
  type        = map(string)
  default     = {}
}
