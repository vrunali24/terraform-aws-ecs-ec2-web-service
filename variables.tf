variable "region" {
  default = "eu-west-1"
}

variable "environment" {
  description = "Name of the environment."
}

variable "vpc_id" {
  description = "ID of the VPC in AWS"
}

variable "service_name" {
  description = "Name of the Service"
}

variable "container_name" {
  description = "Name of the container as defined in the task definition."
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
}

variable "task_definition_arn" {
  description = "Task Definition ARN."
}

variable "alb_listener_rule_arns" {
  type = list(string)
  default = []
}

variable "rule_type" {
  default     = "path-pattern"
  description = "Must be one of path-pattern for path based routing or host-header for host based routing."
}

variable "rule_value" {
  description = "The path pattern or host header pattern to match."
}

variable "rule_priority" {
  description = "Priority of the rule."
}

# Scaling related variables
variable "min_count" {
  default     = 1
  description = "Minimum number of tasks that should be running in the service."
}

variable "max_count" {
  default     = 3
  description = "Maximum number of tasks that can run in the service."
}

variable "desired_count" {
  default     = 2
  description = "Number of instances of tasks that should be running in the service."
}

variable "deployment_min_healthy_percent" {
  default     = 100
  description = "The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment."
}

variable "deployment_max_percent" {
  default     = 200
  description = "The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment."
}

variable "health_check_grace_period" {
  default     = 60
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers."
}

variable "healthy_threshold" {
  default     = 3
  description = "Number of times the healthcheck should pass to mark the task as Healthy."
}

variable "healthcheck_interval" {
  default     = "30"
  description = "Number of seconds after which the ALB should query for the health of the service."
}

variable "healthcheck_protocol" {
  default = "HTTP"
}

variable "health_check_path" {
  description = "The path the ALB should query to check the health status."
}

variable "unhealthy_threshold" {
  default     = 3
  description = "Number of times the healthcheck should fail to mark the task as Unhealthy."
}

variable "port" {
  description = "Port that is exposed on the container."
}

variable "scale_up_cooldown_seconds" {
  default     = 60
  description = "Number of seconds after the alarm that the scale UP should happen."
}

variable "scale_down_cooldown_seconds" {
  default     = 60
  description = "Number of seconds after the alarm that the scale DOWN should happen."
}

variable "ordered_placement_strategies" {
  type = list(object(
    {
      type = string,
      field = string
    }
  ))
  default = [
    {
      type  = "binpack"
      field = "memory"
    },
  ]
}

variable "placement_constraints" {
  type = list(object({
    type       = string
    expression = string
  }))

  default = [
    {
      type       = "memberOf"
      expression = "attribute:ecs.os-type == linux"
    },
  ]
}

variable "disable_auto_scaling" {
  description = "Setting this setting to true will result in not creating auto scaling policies for the service"
  default = false
}

variable "alb_target_group_id_override" {
  description = "User has the option to provide a AWS Target Group ID"
  default = ""
}