resource "aws_iam_role" "iam_for_privilege_grantor" {
  name = "${local.instance_alias}_iam_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "privilege_grantor_lambda_vpc_access" {
  name        = "${local.instance_alias}-lambda-vpc-access"
  description = "VPC and CloudWatch access for Privilege Grantor Lambda function"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "privilege_grantor_role_policy_attach" {
  role       = "${aws_iam_role.iam_for_privilege_grantor.name}"
  policy_arn = "${aws_iam_policy.privilege_grantor_lambda_vpc_access.arn}"
}

resource "aws_sqs_queue" "privilege_grantor_sqs_queue" {
  name                       = "${local.instance_alias}-sqs-queue"
  visibility_timeout_seconds = "${var.lambda_timeout}"
}

resource "aws_sqs_queue_policy" "privilege_grantor_sqs_queue_policy" {
  queue_url = "${aws_sqs_queue.privilege_grantor_sqs_queue.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "AllowSNSSendMessage",
  "Statement": [
    {
      "Sid": "Allow Apiary Metadata Events",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.privilege_grantor_sqs_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${var.metastore_events_sns_topic}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "sqs_for_privilege_grantor" {
  name = "${local.instance_alias}-sqs-policy"
  role = "${aws_iam_role.iam_for_privilege_grantor.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Resource": "${aws_sqs_queue.privilege_grantor_sqs_queue.arn}"
    }
}
EOF
}

resource "aws_sns_topic_subscription" "sqs_hive_metastore_sns_subscription" {
  topic_arn = "${var.metastore_events_sns_topic}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.privilege_grantor_sqs_queue.arn}"

  filter_policy = "${var.metastore_events_sns_filter}"
}

resource "aws_lambda_function" "privilege_grantor_fn" {
  s3_bucket     = "${var.pg_lambda_bucket}"
  s3_key        = "${var.pg_lambda_s3_key}"
  function_name = "${local.instance_alias}-fn"
  role          = "${aws_iam_role.iam_for_privilege_grantor.arn}"
  handler       = "com.expediagroup.apiary.extensions.events.metastore.consumer.privilegesgrantor.lambda.PrivilegesGrantorLambda::handleRequest"
  runtime       = "java8"
  memory_size   = "${var.memory}"
  timeout       = "${var.lambda_timeout}"
  publish       = true

  environment {
    variables = {
      THRIFT_CONNECTION_URI = "${var.pg_metastore_uri}"
    }
  }

  vpc_config {
    subnet_ids         = ["${var.subnets}"]
    security_group_ids = ["${var.security_groups}"]
  }

  tags = "${var.tags}"
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_mapping" {
  batch_size       = 1
  event_source_arn = "${aws_sqs_queue.privilege_grantor_sqs_queue.arn}"
  function_name    = "${aws_lambda_function.privilege_grantor_fn.arn}"
  enabled          = true
}
