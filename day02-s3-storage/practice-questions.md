# Day 2: S3 Practice Questions

## Multiple Choice Questions

### Question 1: What is the default storage class for S3?
A) S3 Standard-IA
B) S3 Standard
C) S3 One Zone-IA
D) S3 Intelligent-Tiering

<details>
<summary>Answer</summary>
B) S3 Standard is the default storage class for newly created objects unless explicitly specified otherwise
</details>
</p>

### Question 2: How does S3 provide read-after-write consistency?
A) Through immediate propagation to all regions
B) By locking the object during write operations
C) For PUTS of new objects in all regions
D) Using eventual consistency with short propagation delay

<details>
<summary>Answer</summary>
C) S3 provides read-after-write consistency for PUTS of new objects in all regions (since December 2020, S3 provides strong consistency for all operations)
</details>
</p>

### Question 3: What is the maximum size of a single S3 object?
A) 5 GB
B) 10 GB
C) 5 TB
D) Unlimited

<details>
<summary>Answer</summary>
C) 5 TB is the maximum size for a single S3 object uploaded in a single PUT operation. For larger objects, use multipart upload (up to 5TB per part, max 10,000 parts)
</details>
</p>

### Question 4: Which S3 feature protects against accidental deletion?
A) S3 Versioning
B) S3 Replication
C) S3 Object Lock
D) All of the above

<details>
<summary>Answer</summary>
D) All of the above - Versioning protects against overwrites, Replication provides geographic redundancy, Object Lock provides WORM protection
</details>
</p>

### Question 5: How can you serve static website content from S3?
A) Enable static website hosting on the bucket
B) Configure CloudFront distribution pointing to S3
C) Set bucket policy to allow public read access
D) All of the above

<details>
<summary>Answer</summary>
D) All of the above - You need static website hosting enabled, public read access via bucket policy or ACL, and optionally CloudFront for HTTPS and custom domains
</details>
</p>

## Scenario-Based Questions

### Scenario 1: Media Storage Solution
You need to store user-uploaded media files (photos, videos) with the following requirements:
- Files accessed frequently in first 30 days
- After 30 days, accessed less frequently but still needed
- After 365 days, rarely accessed but must be retained for compliance
- Need to protect against accidental deletion
- Cost optimization is important

What S3 configuration would you recommend?

<details>
<summary>Answer</summary>
1. **Storage Class**: Use S3 Intelligent-Tiering for automatic optimization OR implement lifecycle policy:
   - Days 0-30: S3 Standard
   - Days 31-365: S3 Standard-IA
   - Day 366+: S3 Glacier Deep Archive
2. **Protection**: Enable S3 Versioning to protect against accidental deletion/overwrite
3. **Security**: 
   - Block public access by default
   - Use bucket policies for specific application access
   - Consider S3 Object Lock in compliance mode for regulatory requirements
4. **Performance**: 
   - Use S3 Transfer Acceleration for global uploads
   - Implement multipart upload for large files
5. **Monitoring**: Enable S3 Server Access Logging and CloudWatch metrics
</details>
</p>

### Scenario 2: Static Website with Global Audience
You need to host a static website that will serve users globally with requirements for:
- HTTPS support
- Custom domain (www.example.com)
- Low latency worldwide
- Cost-effective for variable traffic
- Ability to update content frequently

What AWS services would you use and how would you configure them?

<details>
<summary>Answer</summary>
1. **S3 Bucket**: 
   - Create bucket for static website hosting
   - Enable static website hosting (index.html, error.html)
   - Configure bucket policy for public read access
2. **CloudFront CDN**:
   - Create CloudFront distribution with S3 bucket as origin
   - Configure Alternate Domain Names (CNAMEs) for www.example.com
   - Request or import SSL certificate via ACM for HTTPS
   - Configure default cache behavior (TTL, compression)
   - Set up geographic restrictions if needed
3. **Route 53** (optional but recommended):
   - Create alias record pointing to CloudFront distribution
   - Configure for www.example.com and example.com
4. **Additional Considerations**:
   - Enable compression in CloudFront for CSS/JS
   - Set appropriate cache TTL values
   - Use Lambda@Edge for header manipulation or redirects
   - Enable CloudFront logging for analytics
</details>
</p>

### Scenario 3: Data Lake Architecture
You're building a data lake on S3 for analytics with these requirements:
- Raw data ingested from multiple sources
- Need to process data with Spark/EMR
- Require ACID transactions for certain datasets
- Data accessed by multiple analytics tools (Athena, Redshift, QuickSight)
- Need to track data lineage and versioning
- Cost optimization for different access patterns

How would you structure your S3 data lake?

<details>
<summary>Answer</summary>
1. **Bucket Structure**:
   - s3://company-data-lake/raw/ (ingested data, partitioned by source/date)
   - s3://company-data-lake/processed/ (cleaned, transformed data)
   - s3://company-data-lake/curated/ (business-ready datasets)
   - s3://company-data-lake/models/ (ML models)
   - s3://company-data-lake/analytics/ (query results, reports)

2. **Storage Classes**:
   - Raw: S3 Standard-IA (infrequent access after ingestion)
   - Processed/Curated: S3 Intelligent-Tiering (variable access patterns)
   - Models/Analytics: S3 Standard (frequent access)

3. **Data Format & Organization**:
   - Use Apache Parquet or ORC for columnar storage
   - Partition data by date, region, or other common query filters
   - Use Apache Iceberg or Delta Lake for ACID transactions
   - Implement AWS Glue Data Catalog for metadata management

4. **Governance & Security**:
   - Enable S3 Versioning on all buckets
   - Use S3 Bucket Keys for SSE-KMS to reduce encryption costs
   - Implement fine-grained access with IAM roles and bucket policies
   - Use S3 Object Lambda for row/column level security
   - Enable S3 Audit Logging and CloudTrail for compliance

5. **Cost Optimization**:
   - Implement lifecycle policies to move older data to Glacier
   - Use S3 Analytics to optimize storage class transitions
   - Consider S3 Batch Operations for large-scale data transformations
   - Use S3 Requester Pays for shared datasets
</details>
</p>

## Hands-On Exercise Preparation Checklist

Before starting the hands-on exercise, ensure you have:
- [ ] AWS CLI installed and configured
- [ ] Some test files ready (e.g., test.txt, image.jpg, document.pdf)
- [ ] Basic understanding of JSON syntax
- [ ] Text editor available
- [ ] Understanding of HTTP status codes (200, 403, 404)
- [ ] Knowledge of basic HTML for website testing

## Next Steps
Complete the hands-on exercise in `hands-on-exercise.md` and then proceed to add your work to GitHub as described in the GitHub activity.