
set -e

export AWS_ACCESS_KEY_ID=$BOSH_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$BOSH_AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=us-east-1

elb_name= 
bucket_name=elb-log-${elb_name}

echo "Creating bucket $bucket_name"
aws s3api create-bucket --bucket $bucket_name

echo "Set bucket policy"
aws s3api put-bucket-policy --bucket $bucket_name --policy "\
{\
  \"Statement\":\
  [{\
  \"Effect\": \"Allow\",\
  \"Action\": \"s3:PutObject\",\
  \"Resource\": \"arn:aws:s3:::$bucket_name/*\",\
  \"Principal\": {\"AWS\": \"arn:aws:iam::127311923021:root\"}\
  }]\
}"

echo "Set bucket lifecycle"
aws s3api put-bucket-lifecycle --bucket $bucket_name --lifecycle-configuration "\
{\
  \"Rules\":\
  [{\
  \"Status\": \"Enabled\",\
  \"Prefix\": \"null\",\
  \"Expiration\": {\"Days\": 30},\
  \"ID\":\"delete after 30 days\"\
  }]\
} "

echo "Enabling elb log for $elb_name"
aws elb modify-load-balancer-attributes --load-balancer-name $elb_name --load-balancer-attributes "\
{\
  \"AccessLog\":\
  {\
    \"Enabled\":true,\
    \"S3BucketName\":\"$bucket_name\",\
    \"EmitInterval\":60,\
    \"S3BucketPrefix\":\"$elb_name\"\
  }\
}"



