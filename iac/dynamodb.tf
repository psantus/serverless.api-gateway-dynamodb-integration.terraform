# Create a new DynamoDB table
resource "aws_dynamodb_table" "pets" {
  name         = "pets"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "owner"
  range_key    = "name"

  attribute {
    name = "owner"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }
}

# Create an IAM policy allowing API Gateway to PutItem & Query DynamoDB
resource "aws_iam_policy" "dynamodb_read_write_policy" {
  # Note PutItem and GetItem won't be used in this example
  policy = <<POLICY2
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Action" : [
        "dynamodb:PutItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:GetItem",
        "dynamodb:Query"
      ],
      "Resource" : [ "${aws_dynamodb_table.pets.arn}",
      "${aws_dynamodb_table.pets.arn}/index/*" ]
    }
  ]
}
POLICY2
}