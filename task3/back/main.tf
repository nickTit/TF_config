
 
 resource "aws_s3_bucket" "backend-test" {
     bucket = "backbucket11"
     tags = {
       name = "Storage_bucke"
     }
     force_destroy = true //delete everything when time ll come
 }
 resource "aws_dynamodb_table" "basic-dynamodb-table" {
   name           = "backend"
   billing_mode   = "PROVISIONED"
   read_capacity  = 20
   write_capacity = 20
   hash_key ="LockID" 
   
   attribute {
     name = "LockID"
     type = "S"
   }
   
   tags = {
     Name        = "dynamodb-table-1"
     Environment = "test"
   }
 }
