provider "aws" {
  region = var.region
}

#
# ECS resources
#

resource "aws_ecs_service" "main" {
  lifecycle {
    ignore_changes = [desired_count]
  }

  name                               = "${var.environment}-${var.service_name}"
  cluster                            = var.cluster_name
  task_definition                    = var.task_definition_arn
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_min_healthy_percent
  deployment_maximum_percent         = var.deployment_max_percent

  health_check_grace_period_seconds = var.health_check_grace_period
  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategies
    content {
      field = ordered_placement_strategy.value.field
      type  = ordered_placement_strategy.value.type
    }
  }
  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      expression = placement_constraints.value.expression
      type       = placement_constraints.value.type
    }
  }

  load_balancer {
    target_group_arn = var.alb_target_group_id_override == "" ? aws_alb_target_group.main[0].id : var.alb_target_group_id_override
    container_name   = var.container_name
    container_port   = var.port
  }
}

resource "aws_alb_target_group" "main" {
  count = var.alb_target_group_id_override == "" ? 1 : 0
  name = "tg${var.environment}${var.service_name}"

  health_check {
    healthy_threshold   = var.healthy_threshold
    interval            = var.healthcheck_interval
    protocol            = var.healthcheck_protocol
    matcher             = "200-209"
    timeout             = "5"
    path                = var.health_check_path
    unhealthy_threshold = var.unhealthy_threshold
  }

  port     = var.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name        = "tg${var.environment}${var.service_name}"
    Service     = var.service_name
    Environment = var.environment
  }
}

resource "aws_alb_listener_rule" "attach_listener" {
  count = var.alb_target_group_id_override == "" ? length(var.alb_listener_rule_arns) : 0

  priority = var.rule_priority

  action {
    target_group_arn = aws_alb_target_group.main[0].arn
    type             = "forward"
  }

 condition {
    path_pattern {
      values = var.path_pattern_values
    }
  }

  listener_arn = var.alb_listener_rule_arns[count.index]
}

#
# Application AutoScaling resources
#

resource "aws_appautoscaling_target" "main" {
  count = var.disable_auto_scaling ? 0 : 1
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_count
  max_capacity       = var.max_count

  depends_on = [aws_ecs_service.main]
}

resource "aws_appautoscaling_policy" "up" {
  count = var.disable_auto_scaling ? 0 : 1
  name               = "appScalingPolicy${var.environment}${title(var.service_name)}ScaleUp"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scale_up_cooldown_seconds
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.main]
}

resource "aws_appautoscaling_policy" "down" {
  count = var.disable_auto_scaling ? 0 : 1
  name               = "appScalingPolicy${title(var.environment)}${title(var.service_name)}ScaleDown"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scale_down_cooldown_seconds
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.main]
}
