# Day 3: VPC Hands-On Exercise

## Objective
Create a VPC with public and private subnets, internet gateway, NAT gateway, launch an EC2 instance in private subnet, and configure bastion host in public subnet.

## Prerequisites
- AWS CLI installed and configured
- EC2 Key Pair created (download the .pem file)
- Basic Linux knowledge
- Text editor
- Understanding of networking fundamentals

## Estimated Time: 60 minutes

## Step-by-Step Instructions

### Step 1: Create VPC
```bash
# Create VPC
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=aws-interview-vpc}]' \
    --query 'Vpc.VpcId' \
    --output text)

echo "VPC ID: $VPC_ID"

# Enable DNS hostnames and resolution (important for EC2)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "true"
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "true"
```

### Step 2: Create Internet Gateway
```bash
# Create and attach Internet Gateway
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

echo "Internet Gateway ID: $IGW_ID"

# Attach IGW to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID

echo "Internet Gateway attached to VPC"
```

### Step 3: Create Subnets
```bash
# Get Availability Zones for region
AZS=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0:2].ZoneName' --output text)
AZ1=$(echo $AZS | cut -d' ' -f1)
AZ2=$(echo $AZS | cut -d' ' -f2)

echo "Using AZs: $AZ1 and $AZ2"

# Create Public Subnet (AZ-a)
echo "Creating Public Subnet..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone $AZ1 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-az1}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Public Subnet ID: $PUBLIC_SUBNET_ID"

# Create Private Subnet (AZ-a)
echo "Creating Private Subnet..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone $AZ1 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-az1}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Private Subnet ID: $PRIVATE_SUBNET_ID"

# Create Public Subnet (AZ-b) for HA
echo "Creating Second Public Subnet..."
PUBLIC_SUBNET_ID_2=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.3.0/24 \
    --availability-zone $AZ2 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-az2}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Public Subnet ID 2: $PUBLIC_SUBNET_ID_2"

# Create Private Subnet (AZ-b) for HA
echo "Creating Second Private Subnet..."
PRIVATE_SUBNET_ID_2=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.4.0/24 \
    --availability-zone $AZ2 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet-az2}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Private Subnet ID 2: $PRIVATE_SUBNET_ID_2"
```

### Step 4: Create Route Tables
```bash
# Create Public Route Table
echo "Creating Public Route Table..."
PUBLIC_RTB_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo "Public Route Table ID: $PUBLIC_RTB_ID"

# Add route to Internet Gateway
aws ec2 create-route \
    --route-table-id $PUBLIC_RTB_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID

echo "Added route to Internet Gateway in public route table"

# Associate public route table with public subnets
aws ec2 associate-route-table \
    --route-table-id $PUBLIC_RTB_ID \
    --subnet-id $PUBLIC_SUBNET_ID

aws ec2 associate-route-table \
    --route-table-id $PUBLIC_RTB_ID \
    --subnet-id $PUBLIC_SUBNET_ID_2

echo "Associated public route table with public subnets"

# Create Private Route Table
echo "Creating Private Route Table..."
PRIVATE_RTB_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo "Private Route Table ID: $PRIVATE_RTB_ID"
```

### Step 5: Create NAT Gateway
```bash
# Allocate Elastic IP for NAT Gateway
echo "Allocating Elastic IP for NAT Gateway..."
EIP_ALLOC_ID=$(aws ec2 allocate-address \
    --domain vpc \
    --query 'AllocationId' \
    --output text)

echo "Elastic IP Allocation ID: $EIP_ALLOC_ID"

# Create NAT Gateway in public subnet AZ-a
echo "Creating NAT Gateway..."
NATGW_ID=$(aws ec2 create-nat-gateway \
    --subnet-id $PUBLIC_SUBNET_ID \
    --allocation-id $EIP_ALLOC_ID \
    --query 'NatGateway.NatGatewayId' \
    --output text)

echo "NAT Gateway ID: $NATGW_ID"

# Wait for NAT Gateway to be available
echo "Waiting for NAT Gateway to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NATGW_ID
echo "NAT Gateway is now available"

# Add route to NAT Gateway in private route table
aws ec2 create-route \
    --route-table-id $PRIVATE_RTB_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id $NATGW_ID

echo "Added route to NAT Gateway in private route table"

# Associate private route table with private subnets
aws ec2 associate-route-table \
    --route-table-id $PRIVATE_RTB_ID \
    --subnet-id $PRIVATE_SUBNET_ID

aws ec2 associate-route-table \
    --route-table-id $PRIVATE_RTB_ID \
    --subnet-id $PRIVATE_SUBNET_ID_2

echo "Associated private route table with private subnets"
```

### Step 6: Create Security Groups
```bash
# Create Bastion Host Security Group
echo "Creating Bastion Host Security Group..."
BASTION_SG_ID=$(aws ec2 create-security-group \
    --group-name bastion-sg \
    --description "Security group for bastion host" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)

echo "Bastion SG ID: $BASTION_SG_ID"

# Allow SSH from anywhere (for lab - restrict in production!)
MY_IP=$(curl -s http://checkip.amazonaws.com)/32
aws ec2 authorize-security-group-ingress \
    --group-id $BASTION_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr $MY_IP

echo "Bastion SG: SSH access from your IP ($MY_IP)"

# Create Private Instance Security Group
echo "Creating Private Instance Security Group..."
PRIVATE_SG_ID=$(aws ec2 create-security-group \
    --group-name private-instance-sg \
    --description "Security group for private instances" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)

echo "Private SG ID: $PRIVATE_SG_ID"

# Allow SSH from bastion security group
aws ec2 authorize-security-group-ingress \
    --group-id $PRIVATE_SG_ID \
    --protocol tcp \
    --port 22 \
    --source-group $BASTION_SG_ID

# Allow HTTP/HTTPS from anywhere (for testing web server)
aws ec2 authorize-security-group-ingress \
    --group-id $PRIVATE_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $PRIVATE_SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

echo "Private SG: SSH from bastion, HTTP/HTTPS from anywhere"
```

### Step 7: Launch Bastion Host (Public Subnet)
```bash
# Find Amazon Linux 2 AMI
echo "Finding Amazon Linux 2 AMI..."
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-2.0.????????-x86_64-gp2" "Name=state,Values=available" \
    --query 'Images[0].ImageId' \
    --output text)

echo "AMI ID: $AMI_ID"

# Launch Bastion Host
echo "Launching Bastion Host in public subnet..."
BASTION_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name aws-interview-key \
    --subnet-id $PUBLIC_SUBNET_ID \
    --security-group-ids $BASTION_SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=bastion-host}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Bastion Instance ID: $BASTION_INSTANCE_ID"

# Wait for instance to be running
echo "Waiting for bastion host to be running..."
aws ec2 wait instance-running --instance-ids $BASTION_INSTANCE_ID
echo "Bastion host is running"

# Get bastion host public IP
BASTION_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $BASTION_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Bastion Host Public IP: $BASTION_PUBLIC_IP"
```

### Step 8: Launch Private Instance (Private Subnet)
```bash
# Launch Private Instance
echo "Launching Private Instance in private subnet..."
PRIVATE_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name aws-interview-key \
    --subnet-id $PRIVATE_SUBNET_ID \
    --security-group-ids $PRIVATE_SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=private-instance}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Private Instance ID: $PRIVATE_INSTANCE_ID"

# Wait for instance to be running
echo "Waiting for private instance to be running..."
aws ec2 wait instance-running --instance-ids $PRIVATE_INSTANCE_ID
echo "Private instance is running"

# Get private instance private IP
PRIVATE_INSTANCE_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids $PRIVATE_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

echo "Private Instance Private IP: $PRIVATE_INSTANCE_PRIVATE_IP"
```

### Step 9: Test Connectivity
```bash
# Test 1: SSH to Bastion Host
echo "Testing SSH to bastion host..."
echo "Run this command in another terminal:"
echo "ssh -i \"aws-interview-key.pem\" ec2-user@$BASTION_PUBLIC_IP"

# Test 2: From Bastion, SSH to Private Instance
echo ""
echo "Once connected to bastion, test connectivity to private instance:"
echo "ssh -i \"aws-interview-key.pem\" ec2-user@$PRIVATE_INSTANCE_PRIVATE_IP"

# Test 3: From Private Instance, test internet access (via NAT Gateway)
echo ""
echo "From the private instance, test internet access:"
echo "curl http://httpbin.org/ip"
echo "This should show the NAT Gateway's Elastic IP"

# Test 4: From Private Instance, test AWS metadata service
echo ""
echo "From the private instance, test AWS connectivity:"
echo "curl http://169.254.169.254/latest/meta-data/"
echo "Should return instance metadata"

# Test 5: Verify routing
echo ""
echo "From private instance, check default route:"
echo "ip route show"
echo "Default route should point to NAT Gateway"
```

### Step 10: Install Web Server on Private Instance (Optional)
```bash
# These commands would be run FROM the private instance after SSH-ing in
echo ""
echo "To install a web server on the private instance (run after SSHing into private instance):"
echo ""
echo "# Update packages"
echo "sudo yum update -y"
echo ""
echo "# Install Apache"
echo "sudo yum install -y httpd"
echo ""
echo "# Start and enable service"
echo "sudo systemctl start httpd"
echo "sudo systemctl enable httpd"
echo ""
echo "# Create test page"
echo "echo '<h1>Hello from Private Instance!</h1><p>Accessed via Bastion Host</p>' | sudo tee /var/www/html/index.html"
echo ""
echo "# Test locally"
echo "curl http://localhost"
echo ""
echo "# Then from your local machine, test via bastion:"
echo "ssh -i \"aws-interview-key.pem\" -L 8080:ec2-user@$PRIVATE_INSTANCE_PRIVATE_IP:80 ec2-user@$BASTION_PUBLIC_IP"
echo "# Then browse to http://localhost:8080 in your browser"
```

### Step 11: Clean Up (Optional - for cost saving)
```bash
# To avoid charges, terminate instances and delete resources
echo ""
echo "To clean up and avoid charges, run these commands in order:"
echo ""
echo "# 1. Terminate instances"
echo "aws ec2 terminate-instances --instance-ids $BASTION_INSTANCE_ID,$PRIVATE_INSTANCE_ID"
echo ""
echo "# 2. Wait for termination"
echo "aws ec2 wait instance-terminated --instance-ids $BASTION_INSTANCE_ID,$PRIVATE_INSTANCE_ID"
echo ""
echo "# 3. Delete NAT Gateway"
echo "aws ec2 delete-nat-gateway --nat-gateway-id $NATGW_ID"
echo ""
echo "# 4. Wait for NAT Gateway deletion"
echo "aws ec2 wait nat-gateway-deleted --nat-gateway-id $NATGW_ID"
echo ""
echo "# 5. Release Elastic IP"
echo "aws ec2 release-address --allocation-id $EIP_ALLOC_ID"
echo ""
echo "# 6. Delete Internet Gateway"
echo "aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID"
echo "aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID"
echo ""
echo "# 7. Delete Subnets"
echo "aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID"
echo "aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID"
echo "aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID_2"
echo "aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID_2"
echo ""
echo "# 8. Delete Route Tables"
echo "aws ec2 delete-route-table --route-table-id $PUBLIC_RTB_ID"
echo "aws ec2 delete-route-table --route-table-id $PRIVATE_RTB_ID"
echo ""
echo "# 9. Delete Security Groups"
echo "aws ec2 delete-security-group --group-id $BASTION_SG_ID"
echo "aws ec2 delete-security-group --group-id $PRIVATE_SG_ID"
echo ""
echo "# 10. Delete VPC"
echo "aws ec2 delete-vpc --vpc-id $VPC_ID"
echo ""
echo "Or simply delete the entire VPC (if no dependencies):"
echo "aws ec2 delete-vpc --vpc-id $VPC_ID"
```

## Verification Checklist
- [ ] VPC created with CIDR 10.0.0.0/16
- [ ] Internet Gateway created and attached to VPC
- [ ] Public and private subnets created in two AZs
- [ ] Public route table with route to Internet Gateway
- [ ] Private route table with route to NAT Gateway
- [ ] NAT Gateway created in public subnet with Elastic IP
- [ ] Bastion host security group allowing SSH from your IP
- [ ] Private instance security group allowing SSH from bastion SG
- [ ] Bastion host launched in public subnet
- [ ] Private instance launched in private subnet
- [ ] Able to SSH to bastion host from local machine
- [ ] Able to SSH from bastion host to private instance
- [ ] Private instance has internet access via NAT Gateway
- [ ] Private instance can access AWS metadata service
- [ ] Routing tables configured correctly

## Troubleshooting Tips

### VPC Creation Issues
- **CIDR overlap**: Ensure your VPC CIDR doesn't overlap with other VPCs or on-premises networks
- **Invalid CIDR**: Use valid CIDR notation (e.g., 10.0.0.0/16, not 10.0.0.0/256)
- **Quota exceeded**: Check VPC limits in your region (can request increase)

### Internet Gateway Issues
- **Not attached**: Verify IGW is both created and attached to VPC
- **Missing route**: Ensure route table has 0.0.0.0/0 → IGW for public subnets
- **DNS issues**: Enable enableDnsHostnames and enableDnsSupport on VPC

### NAT Gateway Issues
- **Not available**: NAT Gateways take a few minutes to become available
- **No EIP**: Must allocate and associate Elastic IP before creating NAT Gateway
- **Wrong AZ**: NAT Gateway must be in same AZ as resources using it
- **High costs**: Monitor NAT Gateway usage - unexpected charges may indicate misconfiguration

### Security Group Issues
- **SSH timeout**: 
  - Check bastion SG allows port 22 from your IP
  - Check private SG allows port 22 from bastion SG
  - Verify key pair permissions (chmod 400)
  - Ensure you're using correct key pair name
- **Cannot reach private instance**:
  - Verify you're SSHing via bastion host (not direct)
  - Check private instance security group rules
  - Verify NACLs aren't blocking traffic

### Routing Issues
- **No internet from private instance**:
  - Verify private route table has 0.0.0.0/0 → NAT Gateway
  - Check NAT Gateway status (available, not failed)
  - Confirm Elastic IP is still associated with NAT Gateway
  - Test from bastion host first to isolate issue
- **Asymmetric routing**: Ensure return path is properly configured

### Connectivity Testing
- **Use tcpdump**: For advanced troubleshooting on instances
- **VPC Flow Logs**: Enable to see allowed/blocked traffic
- **Reachability Analyzer**: AWS tool to test connectivity between resources
- **Security Group References**: Much easier than managing IP lists in SGs

## Documentation to Review
- [Amazon VPC Documentation](https://docs.aws.amazon.com/vpc/index.html)
- [VPC and Subnets](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)
- [Internet Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html)
- [NAT Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [Route Tables](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html)
- [Security Groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html)
- [Network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)

## GitHub Activity Preparation
After completing this exercise, you should:
1. Document your VPC architecture with a diagram (text-based is fine)
2. Save all the commands/scripts you used
3. Note any challenges you faced and how you resolved them
4. Prepare to push to GitHub as described in Day 3 activities

## Extension Activities (Optional)
1. Add a second NAT Gateway in the second AZ for HA
2. Set up VPC Flow Logs to CloudWatch Logs
3. Create a VPN connection to simulate on-premises connectivity
4. Set up VPC peering with another VPC
5. Implement AWS PrivateLink for accessing AWS services privately
6. Use Transit Gateway for more complex VPC architectures
7. Set up Network Manager for centralized network monitoring
8. Implement IPv6 addressing in your VPC