# Day 1: EC2 Hands-On Exercise

## Objective
Launch a t2.micro EC2 instance, configure security group, connect via SSH, install Apache, and create a simple HTML page.

## Prerequisites
- AWS CLI installed and configured
- EC2 Key Pair created (download the .pem file)
- Basic Linux knowledge
- Text editor

## Estimated Time: 60 minutes

## Step-by-Step Instructions

### Step 1: Create Key Pair (if not already done)
```bash
# Create a new key pair
aws ec2 create-key-pair --key-name aws-interview-key --query 'KeyMaterial' --output text > aws-interview-key.pem

# Set proper permissions (important for SSH)
chmod 400 aws-interview-key.pem

# Verify the key pair was created
aws ec2 describe-key-pairs --key-names aws-interview-key
```

### Step 2: Create Security Group
```bash
# Get your default VPC ID (you'll need this)
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text

# Create security group for web server
aws ec2 create-security-group \
    --group-name web-server-sg \
    --description "Security group for web server - SSH and HTTP access" \
    --vpc-id YOUR_VPC_ID_HERE

# Authorize SSH access (replace YOUR_IP with your actual IP)
MY_IP=$(curl -s http://checkip.amazonaws.com)/32
aws ec2 authorize-security-group-ingress \
    --group-name web-server-sg \
    --protocol tcp \
    --port 22 \
    --cidr $MY_IP

# Authorize HTTP access from anywhere (for testing)
aws ec2 authorize-security-group-ingress \
    --group-name web-server-sg \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Verify security group rules
aws ec2 describe-security-groups --group-names web-server-sg
```

### Step 3: Launch EC2 Instance
```bash
# Find Amazon Linux 2 AMI ID (this may vary by region)
aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-2.0.????????-x86_64-gp2" "Name=state,Values=available" \
    --query 'Images[0].ImageId' --output text

# Launch the instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0hx67zsRmqz0ag9dj1 \  # Amazon Linux 2 AMI (us-east-1) - verify for your region
    --count 1 \
    --instance-type t2.micro \
    --key-name aws-interview-key \
    --security-groups web-server-sg \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=aws-interview-web-server}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Launched instance: $INSTANCE_ID"

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get public IP address
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Instance public IP: $PUBLIC_IP"
```

### Step 4: Connect via SSH and Install Apache
```bash
# Connect to the instance
ssh -i "aws-interview-key.pem" ec2-user@$PUBLIC_IP

# Once connected, update packages and install Apache
sudo yum update -y
sudo yum install -y httpd

# Start and enable Apache service
sudo systemctl start httpd
sudo systemctl enable httpd

# Verify Apache is running
sudo systemctl status httpd

# Create a simple HTML page
echo "<!DOCTYPE html>
<html>
<head>
    <title>AWS Interview Prep Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { color: #ff9900; text-align: center; }
        .content { background: #f4f4f4; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">AWS Cloud Engineer Interview Preparation</h1>
        <div class="content">
            <h2>EC2 Web Server Successfully Deployed!</h2>
            <p>This server was launched as part of Day 1 hands-on exercise for AWS interview preparation.</p>
            <ul>
                <li>Instance Type: t2.micro</li>
                <li>OS: Amazon Linux 2</li>
                <li>Web Server: Apache HTTPD</li>
                <li>Security: Custom security group with SSH and HTTP access</li>
            </ul>
            <p><strong>Next Steps:</strong> Continue with Day 2 (S3 Storage) in your AWS interview preparation plan.</p>
        </div>
    </div>
</body>
</html>" | sudo tee /var/www/html/index.html

# Set proper permissions
sudo chmod 644 /var/www/html/index.html

# Test the web server locally
curl http://localhost

# Exit SSH session
exit
```

### Step 5: Test Web Server Accessibility
```bash
# From your local machine, test the web server
curl http://$PUBLIC_IP

# You should see the HTML content we created above
# Alternatively, open in a web browser: http://$PUBLIC_IP
```

### Step 6: Clean Up (Optional - for cost saving)
```bash
# Terminate the instance when done
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Wait for termination
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

# Optional: Delete security group and key pair
# aws ec2 delete-security-group --group-name web-server-sg
# aws ec2 delete-key-pair --key-name aws-interview-key
# rm aws-interview-key.pem
```

## Verification Checklist
- [ ] Instance launched successfully (t2.micro)
- [ ] Security group configured with SSH (port 22) and HTTP (port 80) access
- [ ] Connected to instance via SSH using key pair
- [ ] Apache web server installed and running
- [ ] Custom HTML page created and served
- [ ] Web server accessible via public IP on port 80
- [ ] Instance properly tagged for identification

## Troubleshooting Tips

### Connection Issues
- **Timeout connecting**: Check security group inbound rules for port 22
- **Permission denied (publickey)**: Verify .pem file permissions (chmod 400) and correct key pair name
- **Host key verification**: Remove old entry from ~/.ssh/known_hosts if IP changed

### Web Server Issues
- **Connection refused**: Verify Apache is running (sudo systemctl status httpd)
- **Permission denied accessing /var/www/html**: Check file permissions and SELinux context
- **Default Apache page showing**: Verify your index.html is in /var/www/html/ directory

### AWS CLI Issues
- **Command not found**: Ensure AWS CLI is installed and in PATH
- **Unable to locate credentials**: Run aws configure to set up credentials
- **Invalid region**: Set default region with aws configure set region us-east-1

## Documentation to Review
- [Amazon EC2 Documentation](https://docs.aws.amazon.com/ec2/index.html)
- [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [Security Groups Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html)
- [Connecting to Linux Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html)

## GitHub Activity Preparation
After completing this exercise, you should:
1. Take notes on what you learned and any issues encountered
2. Save the scripts/commands you used
3. Prepare to push to GitHub as described in Day 1 activities
4. Consider creating a README or summary of your work

## Extension Activities (Optional)
1. Create a CloudWatch alarm for CPU utilization
2. Create an AMI from your configured instance
3. Set up auto-recovery for the instance
4. Experiment with different Amazon Linux versions
5. Try installing NGINX instead of Apache