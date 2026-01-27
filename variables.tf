 
variable "mwaa_environment_name" {
  description = "Name of the MWAA environment"
  type        = string
  default     = "my-airflow-env"
}

variable "mwaa_dags_bucket_name" {
  description = "S3 bucket name for MWAA DAGs and logs"
  type        = string
  default     = ""
}

variable "mwaa_max_workers" {
  description = "Maximum number of workers for MWAA"
  type        = number
  default     = 2
}

variable "mwaa_min_workers" {
  description = "Minimum number of workers for MWAA"
  type        = number
  default     = 1
}

variable "environment_tag" {
  description = "Environment tag for resources"
  type        = string
  default     = "dev"
}

