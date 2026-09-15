# Day 2: S3 Storage

## Learning Objectives
By the end of this day, you should be able to:
- Understand S3 storage classes and their use cases
- Explain S3 consistency model and durability guarantees
- Configure bucket policies, versioning, and lifecycle rules
- Host static websites on S3
- Implement cross-region replication and transfer acceleration
- Use S3 CLI and SDKs effectively

## Key Concepts to Study

### S3 Storage Classes
- **S3 Standard**: General purpose, 99.99% availability, 99.999999999% durability
- **S3 Standard-IA**: Infrequent Access, lower storage cost, higher retrieval cost
- **S3 One Zone-IA**: Single AZ, 20% cheaper than Standard-IA
- **S3 Intelligent-Tiering**: Automatic tiering based on access patterns
- **S3 Glacier**: Archival, low cost, minutes to hours retrieval
- **S3 Glacier Deep Archive**: Lowest cost, 12+ hours retrieval
- **S3 Outposts**: On-premises S3 storage

### S3 Consistency Model
- **Read-After-Write Consistency**: For PUTS of new objects
- **Eventual Consistency**: For overwrite PUTS and DELETES
- **Strong Consistency**: For all operations in all regions (since Dec 2020)
- **Consistency Factors**: Region, object key, versioning status

### Bucket Policies vs ACLs
- **Bucket Policies**: IAM-based, JSON format, bucket-level or object-level
- **ACLs**: Legacy, XML-based, granular object-level control
- **Recommendation**: Use bucket policies for most use cases

### Versioning
- **Purpose**: Protect against accidental deletion/overwrite
- **How it works**: Each version gets unique version ID
- **Null version**: Current version when versioning suspended
- **Cost**: You pay for storage of all versions
- **Best Practices**: Enable for critical data, combine with lifecycle rules

### Lifecycle Policies
- **Transition Actions**: Move objects between storage classes
- **Expiration Actions**: Automatically delete objects
- **Filtering**: By prefix, tags, or object size
- **Examples**: 
  - Move to IA after 30 days, Glacier after 90 days
  - Delete non-current versions after 30 days
  - Expire logs after 365 days

### Static Website Hosting
- **Requirements**: Bucket must be public, configure index/error documents
- **Endpoint Format**: bucket-name.s3-website-region.amazonaws.com
- **Limitations**: No server-side processing, HTTPS requires CloudFront
- **Best Practices**: Use CloudFront for HTTPS, caching, and custom domains

### Cross-Region Replication (CRR)
- **Requirements**: Versioning enabled on source and destination
- **What's replicated**: New objects, updates, deletes (with delete markers)
- **What's not replicated**: Existing objects (unless using S3 Batch), bucket-level operations
- **Use Cases**: Disaster recovery, compliance, lower latency access

### Transfer Acceleration
- **How it works**: Uses CloudFront edge locations for faster uploads
- **Best for**: Long distance transfers, large files
- **Cost**: Additional charge for data transfer
- **Endpoint**: bucket-name.s3-accelerate.amazonaws.com

## Important CLI Commands

### Bucket Operations
```bash
# Create bucket
aws s3api create-bucket --bucket my-interview-bucket --region us-east-1
# For other regions, need LocationConstraint
aws s3api create-bucket --bucket my-interview-bucket --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1

# List buckets
aws s3 ls

# Delete bucket (must be empty first)
aws s3 rb s3://my-interview-bucket --force

# Copy objects
aws s3 cp local-file.txt s3://my-bucket/
aws s3 cp s3://source-bucket/file.txt s3://dest-bucket/file.txt

# Sync directories
aws s3 sync ./local-dir s3://my-bucket/ --exclude "*.tmp" --include "*.txt"
```

### Versioning
```bash
# Enable versioning
aws s3api put-bucket-versioning --bucket my-bucket --versioning-configuration Status=Enabled

# Check versioning status
aws s3api get-bucket-versioning --bucket my-bucket

# List object versions
aws s3api list-object-versions --bucket my-bucket

# Restore previous version (by copying)
aws s3 cp s3://my-bucket/my-file.txt?versionId=EXAMPLE s3://my-bucket/my-file.txt
```

### Lifecycle Policies
```bash
# Create lifecycle policy JSON
cat > lifecycle.json << 'EOF'
{
    "Rules": [
        {
            "ID": "Move to IA after 30 days",
            "Status": "Enabled",
            "Filter": {},
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                }
            ],
            "Expiration": {
                "Days": 365
            }
        }
    ]
}
EOF

# Apply lifecycle policy
aws s3api put-bucket-lifecycle-configuration --bucket my-bucket --lifecycle-configuration file://lifecycle.json

# Get lifecycle policy
aws s3api get-bucket-lifecycle-configuration --bucket my-bucket
```

### Static Website Hosting
```bash
# Enable website hosting
aws s3 website s3://my-bucket/ --index-document index.html --error-document error.html

# Get website configuration
aws s3api get-bucket-website --bucket my-bucket

# Disable website hosting
aws s3api delete-bucket-website --bucket my-bucket
```

### Bucket Policies
```bash
# Public read policy (for website)
cat > public-read-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::my-bucket/*"
        }
    ]
}
EOF

# Apply bucket policy
aws s3api put-bucket-policy --bucket my-bucket --policy file://public-read-policy.json

# Get bucket policy
aws s3api get-bucket-policy --bucket my-bucket
```

## Best Practices

### Data Organization
1. Use logical naming conventions for buckets and objects
2. Implement folder-like structure using prefixes
3. Use S3 Batch Operations for large-scale changes
4. Consider S3 Object Lambda for real-time data transformation
5. Use S3 Inventory for auditing and reporting

### Security
1. Block public access by default (S3 Block Public Access)
2. Use bucket policies for least privilege access
3. Enable S3 server access logging for audit trails
4. Use S3 Object Lock for WORM (Write Once Read Many) storage
5. Encrypt data at rest (SSE-S3, SSE-KMS, SSE-C) and in transit

### Performance Optimization
1. Use S3 Transfer Acceleration for long-distance uploads
2. Implement multipart upload for large files (>100MB)
3. Use S3 Byte-Range fetches for partial downloads
4. Consider S3 Access Points for managing data access at scale
5. Monitor with CloudWatch metrics and S3 Storage Lens

### Cost Optimization
1. Use S3 Intelligent-Tiering for unpredictable access patterns
2. Implement lifecycle policies to move data to cheaper storage
3. Regularly review and delete incomplete multipart uploads
4. Use S3 Analytics to optimize storage class choices
5. Consider S3 Batch Operations for large-scale cost-saving operations

## Hands-On Exercise Preparation
Tomorrow's hands-on exercise will involve:
1. Creating an S3 bucket
2. Enabling versioning
3. Uploading files
4. Setting lifecycle policy to transition to Glacier
5. Configuring static website hosting

Make sure you have:
- AWS CLI installed and configured
- Some test files to upload (text, images, etc.)
- Basic understanding of JSON for policies