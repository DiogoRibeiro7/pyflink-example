resource "aws_kinesisanalyticsv2_application" "app" {

  name                   = local.service_tag
  description            = "Python flink ${local.service_tag} application."
  runtime_environment    = var.runtime_environment
  service_execution_role = aws_iam_role.app.arn
  start_application      = true
  force_stop             = false


  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.app.arn
  }

  application_configuration {
    application_code_configuration {
      code_content_type = "ZIPFILE"

      code_content {
        s3_content_location {
          bucket_arn = var.cicd ? "arn:aws:s3:::${var.app_bucket}" : module.app_bucket.bucket_arn
          file_key   = var.cicd ? var.app_version : data.external.dev_app[0].result.app_version
        }
      }
    }

    environment_properties {

      dynamic "property_group" {
        for_each = var.environment_properties

        content {
          property_group_id = property_group.key
          property_map      = property_group.value
        }
      }
    }

    application_snapshot_configuration {
      snapshots_enabled = var.snapshots_enabled
    }

    run_configuration {

      application_restore_configuration {
        application_restore_type = var.application_restore_type
        snapshot_name            = var.snapshot_name == "" ? null : var.snapshot_name
      }

      flink_run_configuration {
        allow_non_restored_state = var.allow_non_restored_state
      }
    }

    flink_application_configuration {

      checkpoint_configuration {
        checkpoint_interval           = var.checkpoint_interval
        checkpointing_enabled         = var.checkpoints_enabled
        configuration_type            = var.checkpoint_configuration_type
        min_pause_between_checkpoints = var.checkpoint_min_pause_between
      }

      monitoring_configuration {
        configuration_type = var.monitoring_configuration_type
        log_level          = var.monitoring_log_level
        metrics_level      = var.monitoring_metrics_level
      }

      parallelism_configuration {
        configuration_type   = var.parallelism_configuration_type
        auto_scaling_enabled = var.parallelism_auto_scaling_enabled
        parallelism          = var.parallelism_amount
        parallelism_per_kpu  = var.parallelism_amount_per_kpu
      }
    }

    vpc_configuration {
      # Do not set vpc_id, KDA determines from subnets.
      subnet_ids = var.app_subnet_ids
      security_group_ids = [
        aws_security_group.app.id
      ]
    }
  }
}
