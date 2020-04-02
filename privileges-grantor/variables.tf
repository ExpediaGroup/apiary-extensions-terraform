/**
 * Copyright (C) 2019 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

variable "instance_name" {
  description = "Privilege Grantor instance name to identify resources in multi-instance deployments."
  type        = "string"
  default     = ""
}

variable "subnets" {
  description = "Subnets in which Lambda will have access to."
  type        = "list"
}

variable "security_groups" {
  description = "Security groups in which Lambda will have access to."
  type        = "list"
}

variable "pg_lambda_bucket" {
  description = "Bucket where the Lambda zip can be found, for example 'bucket_name'. Used together with `pg_lambda_s3_key`."
  type        = "string"
}

variable "pg_lambda_s3_key" {
  description = "S3 key where zip file is located."
  type        = "string"
}

variable "pg_metastore_uri" {
  description = "Thrift URI of the metastore to which Lambda will connect to."
  type        = "string"
}

variable "metastore_events_sns_topic" {
  description = "SNS Topic for Hive Metastore events."
  type        = "string"
}

variable "metastore_events_sns_filter" {
  description = <<EOF
  SNS filter policy
  The Metastore events message attributes enable filtering of the SNS events. 
  This can be done by applying a filter policy in a subscription receiver. 
  The following messages attributes are supported:

  -----------------------------------------------------------------------------------
  | Field Name          | Type   | Possible Description
  -----------------------------------------------------------------------------------
  | eventType           | String | One of: CREATE_TABLE, DROP_TABLE, ALTER_TABLE, ADD_PARTITION, DROP_PARTITION, ALTER_PARTITION
  | dbName              | String | Database name of the Hive table from which the event is emitted.
  | tableName           | String | Name of the Hive table from which the event is emitted.
  | qualifiedTableName  | String | Combined version of dbName and tableName: my_db.my_table.
  -----------------------------------------------------------------------------------

  Check https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html on how to construct a filter
EOF
  type        = "string"
  default     = <<JSON
{
  "eventType": [ 
 	"CREATE_TABLE", 
	"ALTER_TABLE" 
  ]
}
JSON
}

# Tags
variable "tags" {
  description = "A map of tags to apply to resources."
  type        = "map"

  default = {
    Environment = ""
    Application = ""
    Team        = ""
  }
}

variable "memory" {
  description = "The amount of memory (in MiB) to be used by Lambda"
  type        = "string"
  default     = "512"
}

variable "lambda_timeout" {
  description = "The time after which the lambda execution stops."
  type        = "string"
  default     = "200"
}
