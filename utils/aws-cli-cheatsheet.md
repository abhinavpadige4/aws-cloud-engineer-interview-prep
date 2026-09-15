# AWS CLI Cheat Sheet

## Basic Configuration
```bash
# Configure AWS CLI
aws configure
# Enter: Access Key ID, Secret Access Key, Default region, Default output format

# List configured profiles
aws configure list

# Get current identity
aws sts get-caller-identity

# Set default region
aws configure set region us-east-1

# Set default output format
aws configure set output json
```

## EC2 Commands
```bash
# List instances
aws ec2 describe-instances

# List instances with filtering
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Launch instance
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --count 1 \
    --instance-type t2.micro \
    --key-name MyKeyPair \
    --security-group-ids sg-903004f8 \
    --subnet-id subnet-6e7f829e

# Start/Stop/Terminate instances
aws ec2 start-instances --instance-ids i-1234567890abcdef0
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# Describe instance status
aws ec2 describe-instance-status --instance-ids i-1234567890abcdef0

# Create AMI from instance
aws ec2 create-image --instance-id i-1234567890abcdef0 --name "my-server-amii"

# Get console output
aws ec2 get-console-output --instance-id i-1234567890abcdef0
```

## S3 Commands
```bash
# List buckets
aws s3 ls

# Create bucket
aws s3 mb s3://my-bucket-name
# For regions other than us-east-1:
aws s3 mb s3://my-bucket-name --region eu-west-1

# List objects
aws s3 ls s3://my-bucket-name/
aws s3 ls s3://my-bucket-name/prefix/ --recursive

# Copy files
aws s3 cp local-file.txt s3://my-bucket-name/
aws s3 cp s3://my-bucket-name/remote-file.txt ./local-copy.txt

# Sync directories
aws s3 sync ./local-dir s3://my-bucket-name/ --exclude "*.tmp" --delete
aws s3 sync s3://source-bucket/ s3://dest-bucket/

# Remove objects
aws s3 rm s3://my-bucket-name/file.txt
aws s3 rm s3://my-bucket-name/prefix/ --recursive

# Bucket operations
aws s3 rb s3://my-bucket-name        # Delete bucket (must be empty)
aws s3 rb s3://my-bucket-name --force # Delete bucket and contents

# Presigned URLs (temporary access)
aws s3 presign s3://my-bucket-name/file.txt --expires-in 3600
```

## VPC Commands
```bash
# List VPCs
aws ec2 describe-vpcs

# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# List subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-12345678"

# Create subnet
aws ec2 create-subnet --vpc-id vpc-12345678 --cidr-block 10.0.1.0/24

# List internet gateways
aws ec2 describe-internet-gateways

# Create and attach internet gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id vpc-12345678

# List route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-12345678"

# Create route table
RTB_ID=$(aws ec2 create-route-table --vpc-id vpc-12345678 --query 'RouteTable.RouteTableId' --output text)

# Add route
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# Associate route table with subnet
aws ec2 associate-route-table --route-table-id $RTB_ID --subnet-id subnet-12345678

# List NAT gateways
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-12345678"

# Create NAT gateway
EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
NATGW_ID=$(aws ec2 create-nat-gateway --subnet-id subnet-12345678 --allocation-id $EIP_ALLOC_ID --query 'NatGateway.NatGatewayId' --output text)

# List security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-12345678"

# Create security group
SG_ID=$(aws ec2 create-security-group --group-name my-sg --description "My security group" --vpc-id vpc-12345678 --query 'GroupId' --output text)

# Authorize inbound rules
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 203.0.113.0/24
```

## IAM Commands
```bash
# List users
aws iam list-users

# Create user
aws iam create-user --user-name my-user

# Create access key
aws iam create-access-key --user-name my-user

# List groups
aws iam list-groups

# Create group
aws iam create-group --group-name admins

# Attach policy to group
aws iam attach-group-policy --group-name admins --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Add user to group
aws iam add-user-to-group --user-name my-user --group-name admins

# List roles
aws iam list-roles

# Create role
aws iam create-role --role-name my-role --assume-role-policy-document file://trust-policy.json

# Attach policy to role
aws iam attach-role-policy --role-name my-role --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# List policies
aws iam list-policies --scope Local

# Create policy
aws iam create-policy --policy-name my-policy --policy-document file://policy.json
```

## CloudFormation Commands
```bash
# List stacks
aws cloudformation list-stacks

# Create stack
aws cloudformation create-stack --stack-name my-stack --template-body file://template.yaml

# Update stack
aws cloudformation update-stack --stack-name my-stack --template-body file://updated-template.yaml

# Delete stack
aws cloudformation delete-stack --stack-name my-stack

# Describe stack resources
aws cloudformation describe-stack-resources --stack-name my-stack

# Validate template
aws cloudformation validate-template --template-body file://template.yaml

# Get template
aws cloudformation get-template --stack-name my-stack

# List change sets
aws cloudformation list-change-sets --stack-name my-stack

# Create change set
aws cloudformation create-change-set --stack-name my-stack --template-body file://template.yaml --change-set-name my-changeset

# Execute change set
aws cloudformation execute-change-set --stack-name my-stack --change-set-name my-changeset
```

## CloudWatch Commands
```bash
# List metrics
aws cloudwatch list-metrics

# Get metric statistics
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
    --start-time 2023-01-01T00:00:00Z \
    --end-time 2023-01-02T00:00:00Z \
    --period 3600 \
    --statistics Average

# Put metric data
aws cloudwatch put-metric-data \
    --namespace CustomApp \
    --metric-name PageViews \
    --value 100 \
    --unit Count

# List alarms
aws cloudwatch describe-alarms

# Create alarm
aws cloudwatch put-metric-alarm \
    --alarm-name HighCPUAlarm \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:sns:us-east-1:123456789012:my-topic \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0

# Describe alarm history
aws cloudwatch describe-alarm-history --alarm-name HighCPUAlarm

# Set alarm state
aws cloudwatch set-alarm-state --alarm-name HighCPUAlarm --state-value ALARM --state-reason "Testing"
```

## Lambda Commands
```bash
# List functions
aws lambda list-functions

# Create function
aws lambda create-function \
    --function-name my-function \
    --runtime python3.8 \
    --role arn:aws:iam::123456789012:role/lambda-role \
    --handler index.handler \
    --zip-file fileb://function.zip

# Invoke function
aws lambda invoke --function-name my-function --payload '{"key": "value"}' response.json

# Update function code
aws lambda update-function-code --function-name my-function --zip-file fileb://new-function.zip

# Update function configuration
aws lambda update-function-configuration --function-name my-function --timeout 30 --memory-size 256

# List versions
aws lambda list-versions-by-function --function-name my-function

# Publish version
aws lambda publish-version --function-name my-function

# Create alias
aws lambda create-alias --function-name my-function --name prod --function-version 1

# List aliases
aws lambda list-aliases --function-name my-function

# Get policy
aws lambda get-policy --function-name my-function

# Add permission
aws lambda add-permission --function-name my-function --statement-id apigateway-access --action lambda:InvokeFunction --principal apigateway.amazonaws.com

# Remove permission
aws lambda remove-permission --function-name my-function --statement-id apigateway-access

# Get function configuration
aws lambda get-function-configuration --function-name my-function

# Get function code location
aws lambda get-function --function-name my-function --query 'Code.Location'
```

## RDS Commands
```bash
# List DB instances
aws rds describe-db-instances

# Create DB instance
aws rds create-db-instance \
    --db-instance-id mydb \
    --db-instance-class db.t2.micro \
    --engine mysql \
    --master-username admin \
    --master-user-password secret123 \
    --allocated-storage 20

# Modify DB instance
aws rds modify-db-instance \
    --db-instance-id mydb \
    --db-instance-class db.t2.medium \
    --apply-immediately

# Reboot DB instance
aws rds reboot-db-instance --db-instance-id mydb

# Delete DB instance
aws rds delete-db-instance \
    --db-instance-id mydb \
    --skip-final-snapshot

# Create DB snapshot
aws rds create-db-snapshot \
    --db-snapshot-id mydbsnapshot \
    --db-instance-id mydb

# Restore DB instance from snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-id mydb-restored \
    --db-snapshot-id mydbsnapshot

# List DB snapshots
aws rds describe-db-snapshots --db-instance-id mydb

# Copy DB snapshot
aws rds copy-db-snapshot \
    --source-db-snapshot-id mydbsnapshot \
    --target-db-snapshot-id mydbsnapshot-copy

# Describe events
aws rds describe-events --source-type db-instance --source-id mydb

# Modify DB parameter group
aws rds create-db-parameter-group \
    --db-parameter-group-name mydbparams \
    --db-parameter-group-family mysql5.7 \
    --description "My custom parameter group"

# Modify parameter group
aws rds modify-db-parameter-group \
    --db-parameter-group-name mydbparams \
    --parameters ParameterName=max_connections,ParameterValue=200,ApplyMethod=immediate

# Describe DB log files
aws rds describe-db-log-files --db-instance-id mydb

# Download DB log file
aws rds download-db-log-file-portion --db-instance-id mydb --log-file-name error/log.gz
```

## General Tips
```bash
# Use --dryroot to test commands without executing
aws ec2 run-instances --dry-run ...

# Use --query for filtering output (JMESPath)
aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name}'

# Use --output format for different formats
aws ec2 describe-instances --output table
aws ec2 describe-instances --output text
aws ec2 describe-instances --output json

# Pagination
aws ec2 describe-instances --max-items 50
aws ec2 describe-instances --starting-token <token>

# Waiters
aws ec2 wait instance-running --instance-ids i-1234567890abcdef0
aws ec2 wait instance-stopped --instance-ids i-1234567890abcdef0
aws ec2 wait instance-terminated --instance-ids i-1234567890abcdef0

# Bulk operations with xargs
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text |
  xargs -n1 aws ec2 stop-instances --instance-ids

# JSON processing with jq
aws ec2 describe-instances --output json |
  jq '.Reservations[].Instances[] | select(.State.Name == "running") | .InstanceId'
```