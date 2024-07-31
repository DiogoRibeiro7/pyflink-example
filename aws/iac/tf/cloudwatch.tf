resource "aws_cloudwatch_log_group" "app" {
  name              = "${var.env}-flink-${local.service_tag}"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_stream" "app" {
  name           = "${var.env}-flink-${local.service_tag}"
  log_group_name = aws_cloudwatch_log_group.app.name
}
