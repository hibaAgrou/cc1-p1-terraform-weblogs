resource "aws_kinesis_analytics_application" "kinesis_sql_streaming_application" {

  name = "sql-streaming-application"

  # Define the SOURCE of the application
  inputs {
    # Prefix for the source stream name 
    name_prefix = "SOURCE_SQL_STREAM"

    kinesis_stream {
      resource_arn = aws_kinesis_stream.datastream_ingestion.arn
      role_arn     = aws_iam_role.kinesis_analytics_sql_streaming_application.arn
    }

    parallelism {
      count = 1
    }

    schema {
      record_columns {
        mapping  = "$.ticker"
        name     = "ticker"
        sql_type = "VARCHAR(4)"
      }
      record_columns {
        mapping  = "$.price"
        name     = "price"
        sql_type = "REAL"
      }

      record_encoding = "UTF-8"
      record_format {
        mapping_parameters {
          json {
            record_row_path = "$"
          }
        }

      }

    }

    # Starting position in the stream
    starting_position_configuration {
      starting_position = "NOW"
    }

  }

  outputs {
    kinesis_firehose {
      resource_arn = aws_kinesis_firehose_delivery_stream.delivery_stream_summary.arn
      role_arn     = aws_iam_role.kinesis_analytics_sql_streaming_application.arn
    }

    name = "DESTINATION_SQL_STREAM"

    schema {
      record_format_type = "JSON"
    }

  }

  # SQL code of the application 
  code = <<EOF
  CREATE OR REPLACE STREAM "DESTINATION_SQL_STREAM" (ticker VARCHAR(4), price REAL);
  -- Create pump to insert into output
  CREATE OR REPLACE PUMP "STREAM_PUMP" AS INSERT INTO "DESTINATION_SQL_STREAM“
  -- Select all columns from source stream
  SELECT STREAM ticker, max(price) OVER (PARTITION BY ticker ROWS 3 PRECEDING) FROM "SOURCE_SQL_STREAM_001” WHERE ticker SIMILAR TO 'IBM' AND price > 50;
  EOF

  start_application = true

}
