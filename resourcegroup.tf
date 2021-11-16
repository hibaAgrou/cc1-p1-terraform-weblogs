resource "aws_resourcegroups_group" "my_resource_group" {
  name = "my-resource-group"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": [
    {
      "Key": "student",
      "Values": ["${var.student_email}"]
    }
  ]
}
JSON
  }
}

# First resource needed
resource "aws_s3_bucket" "summary_destination" {
  bucket = "hiba-cc-bucket"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "default"
  }
}

# Second resource needed
resource "aws_kinesis_stream" "datastream_ingestion" {
  name             = "terraform-kinesis-test"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = {
    Environment = "default"
  }
}