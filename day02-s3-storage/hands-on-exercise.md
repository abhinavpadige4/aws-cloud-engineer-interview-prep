# Day 2: S3 Hands-On Exercise

## Objective
Create an S3 bucket, enable versioning, upload files, set lifecycle policy to transition to Glacier after 30 days, and configure static website hosting.

## Prerequisites
- AWS CLI installed and configured
- Some test files to upload (create a few text files, images, etc.)
- Basic Linux knowledge
- Text editor

## Estimated Time: 60 minutes

## Step-by-Step Instructions

### Step 1: Create Test Files
```bash
# Create a directory for our test files
mkdir -p s3-test-files
cd s3-test-files

# Create various test files
echo "This is a test text file for S3 exercise" > document1.txt
echo "Another document with different content" > document2.txt
echo "{\"name\": \"John\", \"age\": 30, \"city\": \"New York\"}" > data.json
echo "<!DOCTYPE html>
<html>
<head>
    <title>Test Website</title>
</head>
<body>
    <h1>Welcome to our test website!</h1>
    <p>This is hosted on Amazon S3.</p>
</body>
</html>" > index.html

echo "<!DOCTYPE html>
<html>
<head>
    <title>Error Page</title>
</head>
<body>
    <h1>Page Not Found</h1>
    <p>The requested page could not be found.</p>
</body>
</html>" > error.html

# Create a dummy image file (small binary file)
dd if=/dev/zero of=test-image.jpg bs=1K count=10

# List created files
ls -la
cd ..
```

### Step 2: Create S3 Bucket
```bash
# Generate a unique bucket name (must be globally unique)
TIMESTAMP=$(date +%s)
BUCKET_NAME="aws-interview-prep-s3-${TIMESTAMP}"
echo "Creating bucket: $BUCKET_NAME"

# Create bucket (us-east-1 doesn't need LocationConstraint)
aws s3api create-bucket --bucket $BUCKET_NAME --region us-east-1

# For other regions, use:
# aws s3api create-bucket --bucket $BUCKET_NAME --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1

# Verify bucket creation
aws s3api list-buckets --query "Buckets[?Name=='$BUCKET_NAME']"
```

### Step 3: Enable Versioning
```bash
# Enable versioning on the bucket
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

# Verify versioning is enabled
aws s3api get-bucket-versioning --bucket $BUCKET_NAME
```

### Step 4: Upload Files to S3
```bash
# Upload individual files
aws s3 cp s3-test-files/document1.txt s3://$BUCKET_NAME/documents/
aws s3 cp s3-test-files/document2.txt s3://$BUCKET_NAME/documents/
aws s3 cp s3-test-files/data.json s3://$BUCKET_NAME/data/
aws s3 cp s3-test-files/test-image.jpg s3://$BUCKET_NAME/images/

# Upload website files
aws s3 cp s3-test-files/index.html s3://$BUCKET_NAME/
aws s3 cp s3-test-files/error.html s3://$BUCKET_NAME/

# Sync entire directory (alternative method)
# aws s3 sync s3-test-files/ s3://$BUCKET_NAME/ --exclude "*" --include "*.txt" --include "*.json" --include "*.html" --include "*.jpg"

# List uploaded objects
aws s3 ls s3://$BUCKET_NAME/ --recursive
```

### Step 5: Create and Apply Lifecycle Policy
```bash
# Create lifecycle policy JSON
cat > lifecycle-policy.json << EOF
{
    "Rules": [
        {
            "ID": "Transition to Glacier after 30 days",
            "Status": "Enabled",
            "Filter": {},
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "GLACIER"
                }
            ],
            "NoncurrentVersionTransitions": [
                {
                    "NoncurrentDays": 30,
                    "StorageClass": "GLACIER"
                }
            ],
            "NoncurrentVersionExpiration": {
                "NoncurrentDays": 90
            }
        }
    ]
}
EOF

# Apply lifecycle policy
aws s3api put-bucket-lifecycle-configuration --bucket $BUCKET_NAME --lifecycle-configuration file://lifecycle-policy.json

# Verify lifecycle policy
aws s3api get-bucket-lifecycle-configuration --bucket $BUCKET_NAME
```

### Step 6: Configure Static Website Hosting
```bash
# Enable static website hosting
aws s3 website s3://$BUCKET_NAME/ --index-document index.html --error-document error.html

# Verify website configuration
aws s3api get-bucket-website --bucket $BUCKET_NAME

# Set bucket policy for public read access (required for website)
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

# Apply bucket policy
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# Get website endpoint
WEBSITE_ENDPOINT=$(aws s3api get-bucket-website --bucket $BUCKET_NAME --query "RedirectAllRequestsTo.HostName" --output text 2>/dev/null || 
                  aws s3api get-bucket-website --bucket $BUCKET_NAME --query "RoutingRules" --output text 2>/dev/null ||
                  echo "$BUCKET_NAME.s3-website.us-east-1.amazonaws.com")

# For us-east-1, the website endpoint format is:
WEBSITE_URL="http://$BUCKET_NAME.s3-website.us-east-1.amazonaws.com"
echo "Website URL: $WEBSITE_URL"
```

### Step 7: Test Website Accessibility
```bash
# Test the website endpoint
echo "Testing website accessibility..."
curl -s $WEBSITE_URL | head -5

# Test error page
curl -s "$WEBSITE_URL/nonexistent-page.html" | head -5

# Test direct object access
echo "Testing direct object access:"
curl -s "https://$BUCKET_NAME.s3.us-east-1.amazonaws.com/index.html" | head -3
```

### Step 8: Test Versioning
```bash
# Upload a new version of an existing file
echo "Updated content for version 2" > s3-test-files/document1-v2.txt
aws s3 cp s3-test-files/document1-v2.txt s3://$BUCKET_NAME/document1.txt

# List all versions of the file
echo "Listing all versions of document1.txt:"
aws s3api list-object-versions --bucket $BUCKET_NAME --prefix "document1.txt"

# Download a specific version (if you want to test)
# VERSION_ID=$(aws s3api list-object-versions --bucket $BUCKET_NAME --prefix "document1.txt" --query "Versions[0].VersionId" --output text)
# aws s3api get-object --bucket $BUCKET_NAME --key document1.txt --version-id $VERSION_ID document1-v1.txt
```

### Step 9: Clean Up (Optional - for cost saving)
```bash
# To delete everything and avoid charges:
# 1. Delete all object versions
# aws s3api list-object-versions --bucket $BUCKET_NAME --output=json |
#   jq -r '.Versions[].Key + " " + .Versions[].VersionId' |
#   while read key version; do
#     aws s3api delete-object --bucket $BUCKET_NAME --key "$key" --version-id "$version"
#   done

# 2. Delete the bucket
# aws s3 rb s3://$BUCKET_NAME --force

echo "To clean up and avoid charges, run:"
echo "aws s3 rb s3://$BUCKET_NAME --force"
```

## Verification Checklist
- [ ] S3 bucket created successfully with unique name
- [ ] Versioning enabled on the bucket
- [ ] Files uploaded to various folders/prefixes
- [ ] Lifecycle policy configured to transition to Glacier after 30 days
- [ ] Static website hosting enabled with index and error documents
- [ ] Bucket policy configured for public read access
- [ ] Website accessible via the S3 website endpoint
- [ ] Versioning working (multiple versions of same object)
- [ ] Lifecycle policy properly applied and visible

## Troubleshooting Tips

### Bucket Creation Issues
- **Bucket name already exists**: S3 bucket names must be globally unique - add timestamp or random string
- **Invalid bucket name**: Bucket names must be lowercase, start with letter/number, 3-63 characters
- **Region mismatch**: Ensure you're using correct region-specific commands

### Versioning Issues
- **Versioning not showing**: Verify you used put-bucket-versioning, not just checking status
- **Cannot list versions**: Ensure you're using list-object-versions, not list-objects-v2

### Website Hosting Issues
- **403 Forbidden**: Missing or incorrect bucket policy for public read access
- **404 Not Found**: Wrong index document name or file not uploaded
- **Website endpoint not working**: Verify static website hosting is enabled correctly

### Lifecycle Policy Issues
- **Policy not applying**: Check JSON syntax and ensure correct bucket name
- **Transitions not working**: Lifecycle policies take effect within 24 hours, not immediate
- **Cannot see transitions**: Use storage class analysis or wait for policy to take effect

### Permission Issues
- **Access Denied**: Verify IAM user has s3:* permissions for the bucket
- **Cannot put bucket policy**: Need s3:PutBucketPermission permission
- **CORS issues**: For web applications, may need to configure CORS rules

## Documentation to Review
- [Amazon S3 Documentation](https://docs.aws.amazon.com/s3/index.html)
- [S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)
- [Versioning Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [Lifecycle Configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html)
- [Bucket Policies Examples](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html)

## GitHub Activity Preparation
After completing this exercise, you should:
1. Document what you learned and any challenges faced
2. Save the scripts/commands you used
3. Consider creating a diagram of your S3 setup
4. Prepare to push to GitHub as described in Day 2 activities

## Extension Activities (Optional)
1. Set up S3 replication to another region
2. Configure S3 Event Notifications to Lambda
3. Implement S3 Object Lock for compliance
4. Use S3 Batch Operations to modify object metadata
5. Set up S3 Access Points for specific applications
6. Enable S3 Storage Lens for usage analytics
7. Configure S3 Intelligent-Tiering monitoring