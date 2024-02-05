locals {
  name_prefix = "jody"
}

# create the queue
resource "aws_sqs_queue" "q" {
  name = "${local.name_prefix}-trigger-queue"
}

# create the policy
data "aws_iam_policy_document" "test" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.q.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.example.arn]
    }
  }
}
 # attach the policy to SQS
resource "aws_sqs_queue_policy" "test" {
  queue_url = aws_sqs_queue.q.id
  policy    = data.aws_iam_policy_document.test.json
}

# create the s3 bucket
resource "aws_s3_bucket" "example" {
  bucket = "${local.name_prefix}-sqs-bucket"
}

# attach trigger to s3 bucket notification queue
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.example.id

  queue {
    queue_arn = aws_sqs_queue.q.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}