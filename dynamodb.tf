resource "aws_dynamodb_table" "state_table" {
  name         = "eks-demo-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
