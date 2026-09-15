# Day 1: EC2 Fundamentals

## Learning Objectives
By the end of this day, you should be able to:
- Understand EC2 instance types and their use cases
- Explain AMIs and how to create/customize them
- Configure security groups and key pairs properly
- Launch, connect to, and manage EC2 instances via AWS CLI and Console
- Install and configure web servers on EC2 instances

## Key Concepts to Study

### EC2 Instance Types
- **General Purpose**: T3, T3a, M5, M5a (balanced compute, memory, networking)
- **Compute Optimized**: C5, C5a, C6i (compute-intensive applications)
- **Memory Optimized**: R5, R5a, X1 (memory-intensive applications like databases)
- **Storage Optimized**: I3, D3, H1 (high sequential read/write access to large datasets)
- **Accelerated Computing**: P3, G4, Inf1 (GPUs, FPGAs for ML, graphics processing)

### Amazon Machine Images (AMIs)
- **Types**: Amazon Linux, Ubuntu, Windows Server, RHEL, SUSE
- **Sources**: AWS provided, Marketplace, Community, Custom
- **Lifecycle**: Creation, copying between regions, deregistration
- **Best Practices**: Regular updates, minimal installations, security hardening

### Security Groups
- **Stateful Firewall**: Return traffic automatically allowed
- **Rules**: Inbound and outbound rules separately configured
- **Default Rules**: No inbound access allowed, all outbound allowed
- **Best Practices**: Principle of least privilege, use specific IP ranges

### Key Pairs
- **Purpose**: Secure SSH access to Linux instances
- **Components**: Public key (stored on instance), Private key (kept by user)
- **Management**: Creation, rotation, revocation
- **Alternatives**: Systems Manager Session Manager, EC2 Instance Connect

### Elastic IP Addresses
- **Static IPv4**: Designed for dynamic cloud computing
- **Remappable**: Can be moved between instances
- **Charges**: Free when associated with running instance, hourly when not
- **Limits**: Default limit of 5 EIPs per region

## Important CLI Commands

### Instance Management
```bash
# List instances
aws ec2 describe-instances

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
```

### Security Groups
```bash
# Create security group
aws ec2 create-security-group \
    --group-name my-sg \
    --description "My security group" \
    --vpc-id vpc-1a2b3c4d

# Authorize inbound rules
aws ec2 authorize-security-group-ingress \
    --group-id sg-903004f8 \
    --protocol tcp \
    --port 22 \
    --cidr 203.0.113.0/24

# Authorize HTTP/HTTPS
aws ec2 authorize-security-group-ingress \
    --group-id sg-903004f8 \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id sg-903004f8 \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0
```

### Key Pairs
```bash
# Create key pair
aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > MyKeyPair.pem

# Import key pair
aws ec2 import-key-pair --key-name MyKeyPair --public-key-material file://MyKeyPair.pub

# Delete key pair
aws ec2 delete-key-pair --key-name MyKeyPair
```

## Best Practices

### Instance Lifecycle Management
1. Use Auto Scaling groups for fault tolerance and scalability
2. Implement health checks and replacement policies
3. Use launch templates/configurations for consistency
4. Tag instances for cost allocation and management
5. Consider Spot Instances for fault-tolerant, flexible workloads

### Security
1. Never use the default security group
2. Apply the principle of least privilege
3. Regularly audit security group rules
4. Use VPC Flow Logs for monitoring
5. Enable detailed monitoring for critical instances

### Cost Optimization
1. Right-size instances based on utilization metrics
2. Use Reserved Instances for predictable workloads
3. Consider Savings Plans for flexibility
4. Terminate unused instances promptly
5. Use EC2 Instance Scheduler for dev/test environments

## Hands-On Exercise Preparation
Tomorrow's hands-on exercise will involve:
1. Launching a t2.micro EC2 instance
2. Configuring security group for SSH and HTTP access
3. Connecting via SSH
4. Installing Apache web server
5. Creating a simple HTML page
6. Testing the web server accessibility

Make sure you have:
- AWS CLI installed and configured
- A key pair ready for use
- Basic Linux command knowledge