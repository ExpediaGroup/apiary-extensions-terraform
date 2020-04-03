# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2020-04-03
### Added
- `metastore_events_sns_filter` map variable that accepts a valid SNS filter.
### Removed
- `database_filter` and `metastore_events_filter` variables.

## [2.0.0] - 2019-10-04
### Added
- SQS permissions policy.
- tags to the lambda.

### Changed
- converting the filter_policy to a template.
- updating filter vars from string to list.
- updating the variable `pg_jars_s3_key` to `pg_lambda_s3_key`.

### Removed
- removed the `pg_lambda_version` module variable (but left an example of using it client-side in the README.md)

## [1.0.0] - 2019-06-27
### Added
- Terraform scripts for Privilege Grantor Apiary Extension.
