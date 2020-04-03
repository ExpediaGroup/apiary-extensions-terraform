# Overview

Terraform module for setting up infrastructure for [Apiary Privileges Grantor](https://github.com/ExpediaGroup/apiary-extensions/tree/master/apiary-metastore-events/apiary-metastore-consumers/privileges-grantor).

For more information please refer to the main [Apiary](https://github.com/ExpediaInc/apiary) project page.

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| instance\_name | Privileges Grantor instance name to identify resources in multi-instance deployments. | string | `""` | no |
| lambda\_timeout | The time after which the lambda execution stops. | string | `"200"` | no |
| memory | The amount of memory (in MiB) to be used by Lambda | string | `"512"` | no |
| metastore\_events\_sns\_filter | SNS filter of message attributes to the added to the SNS topic subscription. Supported format: SNS filter format. Refer to https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html for more information on how to construct a filter. | string | `{ "eventType": [ "CREATE_TABLE", "ALTER_TABLE" ] }` | no |
| metastore\_events\_sns\_topic | SNS Topic for Hive Metastore events. | string | n/a | yes |
| pg\_lambda\_s3\_key | S3 key where privilege grantor lambda jar/zip file is located. | string | n/a | yes |
| pg\_lambda\_bucket | Bucket where the privilege grantor lambda jar/zip can be found, for example 'bucket\_name'. Used together with `pg_lambda_s3_key` to construct the full S3 path. | string | n/a | yes |
| pg\_metastore\_uri | Thrift URI of the metastore to which Lambda will connect to. | string | n/a | yes |
| security\_groups | Security groups in which Lambda will have access to. | list | n/a | yes |
| subnets | Subnets in which Lambda will have access to. | list | n/a | yes |
| tags | A map of tags to apply to resources. | map | `<map>` | no |

## Usage

Example module invocation:
```
module "apiary-privileges-grantor" {
  source = "git@github.com:ExpediaGroup/apiary-extensions-terraform.git/privileges-grantor"
  pg_lambda_bucket           = "pg-s3-bucket"
  pg_lambda_s3_key           = "pg-s3-key"
  pg_metastore_uri           = "thrift://ip-address:9083"
  metastore_events_sns_topic = "arn:aws:sns:us-west-2:1234567:metastore-events-sns-topic"
  metastore_events_sns_filter = <<JSON
{
  "dbName": [
    {"prefix": "db1_"},
    {"prefix": "db2_"},
    "default"
  ],
  "eventType": [
    "CREATE_TABLE",
    "ALTER_TABLE"
  ]
}
JSON
  subnets                    = ["subnet-1", "subnet-2"]
  security_groups            = ["security-group-1", "security-group-2"]
  tags = {
    Name = "Apiary-Privileges-Grantor"
    Team = "Operations"
  }
}

```

The apiary-privileges-grantor lambda can be found in the public [maven repository](https://mvnrepository.com/artifact/com.expediagroup.apiary/apiary-privileges-grantor-lambda).
The jars can be downloaded from the link provided above and uploaded to S3 via terraform as follows:

```
variable "pg_lambda_version" {
  description = "Version of the Privilege Grantor Lambda."
  type        = "string"
  default     = "6.1.0"
}

data "aws_s3_bucket" "apiary-extensions" {
  bucket = "pg-s3-bucket"
}

resource "null_resource" "apiary-privileges-grantor-zip" {
  depends_on = ["data.aws_s3_bucket.apiary_extensions"]

  triggers = {
    lambda_version = "${var.pg_lambda_version}"
  }

  provisioner "local-exec" {
    command = <<CMD
        curl -sLo apiary-privileges-grantor-lambda-${var.pg_lambda_version}.zip https://repo1.maven.org/maven2/com/expediagroup/apiary/apiary-privileges-grantor-lambda/${var.pg_lambda_version}/apiary-privileges-grantor-lambda-${var.pg_lambda_version}.zip
CMD
  }
}

resource "aws_s3_bucket_object" "apiary-privileges-grantor-zip" {
  depends_on = ["null_resource.apiary-privileges-grantor-zip"]

  bucket = "${data.aws_s3_bucket.apiary_extensions.id}"
  key    = "apiary-privileges-grantor-lambda-${var.pg_lambda_version}.zip"
  source = "apiary-privileges-grantor-core-${var.pg_lambda_version}.zip"
}

module "apiary-privileges-grantor" {
  source = "git@github.com:ExpediaGroup/apiary-extensions-terraform.git/privileges-grantor"
  pg_lambda_bucket           = "${data.aws_s3_bucket.apiary-extensions.id}"
  pg_lambda_s3_key           = "${aws_s3_bucket_object.apiary-privileges-grantor-zip.id}"
  pg_metastore_uri           = "thrift://ip-address:9083"
  metastore_events_sns_topic = "arn:aws:sns:us-west-2:1234567:metastore-events-sns-topic"
  metastore_events_sns_filter = <<JSON
{
  "dbName": [
    {"prefix": "db1_"},
    {"prefix": "db2_"},
    "default"
  ],
  "eventType": [
    "CREATE_TABLE",
    "ALTER_TABLE"
  ]
}
  subnets                    = ["subnet-1", "subnet-2"]
  security_groups            = ["security-group-1", "security-group-2"]
  tags = {
    Name = "Apiary-Privileges-Grantor"
    Team = "Operations"
  }
}
``` 

# Contact

## Mailing List
If you would like to ask any questions about or discuss Apiary please join our mailing list at

  [https://groups.google.com/forum/#!forum/apiary-user](https://groups.google.com/forum/#!forum/apiary-user)

# Legal
This project is available under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0.html).

Copyright 2019 Expedia, Inc.
