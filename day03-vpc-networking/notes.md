# Day 3: VPC Networking

## Learning Objectives
By the end of this day, you should be able to:
- Design and implement VPC architectures with public and private subnets
- Configure Internet Gateways, NAT Gateways, and VPN connections
- Set up routing tables and network ACLs correctly
- Implement security groups for layered security
- Establish VPC peering and VPN connections
- Troubleshoot common VPC connectivity issues

## Key Concepts to Study

### VPC Fundamentals
- **CIDR Blocks**: Private IP address ranges (RFC 1918)
  - 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
- **VPC Size Limits**: /16 (65,536 IPs) to /28 (16 IPs)
- **Subnets**: subdivisions of VPC CIDR, must reside in single AZ
- **Tenancy**: Default (shared hardware) or Dedicated (single-tenant hardware)
- **DNS Support**: enableDnsHostnames and enableDnsSupport attributes

### Internet Gateway (IGW)
- **Purpose**: Enables communication between VPC and internet
- **Attributes**: Horizontally scaled, highly available, redundant
- **Attachment**: One IGW per VPC, VPC can have only one IGW attached
- **Routing**: Requires route table entry pointing to IGW for internet access
- **Limitations**: Only supports IPv4 and IPv6, no bandwidth limits

### NAT Gateway vs NAT Instance
- **NAT Gateway** (Managed):
  - Highly available within AZ
  - Scales automatically up to 45 Gbps
  - No patching or maintenance required
  - Charged per hour and per GB processed
- **NAT Instance** (Self-managed):
  - Requires EC2 instance management
  - Need to configure failover and scaling manually
  - Charged for EC2 instance + data processing
  - Deprecated in favor of NAT Gateway

### Route Tables
- **Main Route Table**: Automatically created with VPC
- **Custom Route Tables**: User-defined for specific subnet routing
- **Routes**: Destination CIDR -> Target (IGW, NAT, VPC peering, etc.)
- **Priority**: Most specific route wins (longest prefix match)
- **Blackhole Routes**: Routes to deleted targets (show as blackhole status)

### Network ACLs (NACLs)
- **Stateless**: Return traffic must be explicitly allowed by rules
- **Numbered Rules**: Processed in order (lowest number first)
- **Default NACL**: Allows all inbound and outbound traffic
- **Custom NACL**: Denies all inbound and outbound traffic by default
- **Limits**: 20 inbound + 20 outbound rules per NACL
- **Association**: One NACL per subnet, subnet can have only one NACL

### Security Groups
- **Stateful**: Return traffic automatically allowed
- **Evaluation**: All rules evaluated, permissive model
- **Limits**: Up to 60 rules per security group (ingress + egress)
- **References**: Can reference other security groups in same VPC
- **Default**: No inbound access allowed, all outbound allowed

### VPC Peering
- **Purpose**: Connect two VPCs for private communication
- **Limitations**: 
  - Non-transitive (A peered with B, B peered with C ≠ A peered with C)
  - No overlapping CIDR blocks
  - Maximum 125 peering connections per VPC
- **Routing**: Requires route table updates in both VPCs
- **Security**: Still governed by security groups and NACLs
- **Encryption**: Not encrypted (use VPN or Direct Connect for encryption)

### VPN Connections
- **Types**: 
  - AWS Site-to-Site VPN (IPsec)
  - AWS Client VPN (SSL/TLS for remote users)
- **Components**:
  - Virtual Private Gateway (VGW) or Transit Gateway (TGW)
  - Customer Gateway (CGW) - represents customer device
  - VPN Connection - links VGW/TGW to CGW
- **Routing**: Static or dynamic (BGP)
- **Encryption**: IPsec encryption for data in transit

### Transit Gateway
- **Purpose**: Hub-and-spoke model for connecting VPCs and on-premises
- **Advantages over Peering**:
  - Transitive routing (spoke A can reach spoke B via hub)
  - Centralized management
  - Supports thousands of attachments
  - Multicast support
- **Components**: Transit Gateway, VPC attachments, VPN/Direct Connect attachments, route tables

## Important CLI Commands

### VPC Creation
```bash
# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=my-vpc}]'

# Get VPC ID
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

# Attach IGW to VPC
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Create Subnets
# Public subnet
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' --output text)

# Private subnet
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone us-east-1a \
    --query 'Subnet.SubnetId' --output text)
```

### Route Tables
```bash
# Create custom route table
RTB_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)

# Add route to Internet Gateway
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# Associate route table with subnet
aws ec2 associate-route-table --route-table-id $RTB_ID --subnet-id $PUBLIC_SUBNET_ID

# Get main route table
MAIN_RTB_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=true" --query 'RouteTables[0].RouteTableId' --output text)
```

### NAT Gateway
```bash
# Allocate Elastic IP for NAT Gateway
EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

# Create NAT Gateway
NATGW_ID=$(aws ec2 create-nat-gateway \
    --subnet-id $PUBLIC_SUBNET_ID \
    --allocation-id $EIP_ALLOC_ID \
    --query 'NatGateway.NatGatewayId' --output text)

# Wait for NAT Gateway to be available
aws ec2 wait nat-gateway-available --nat-gateway-ids $NATGW_ID

# Create route table for private subnet
PRIVATE_RTB_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)

# Add route to NAT Gateway
aws ec2 create-route --route-table-id $PRIVATE_RTB_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NATGW_ID

# Associate with private subnet
aws ec2 associate-route-table --route-table-id $PRIVATE_RTB_ID --subnet-id $PRIVATE_SUBNET_ID
```

### Network ACLs
```bash
# Create custom NACL
NACL_ID=$(aws ec2 create-network-acl --vpc-id $VPC_ID --query 'NetworkAcl.NetworkAclId' --output text)

# Add inbound rule (allow HTTP)
aws ec2 create-network-acl-entry \
    --network-acl-id $NACL_ID \
    --ingress \
    --rule-number 100 \
    --protocol tcp \
    --port-range From=80,To=80 \
    --cidr-block 0.0.0.0/0 \
    --rule-action allow

# Add outbound rule (allow response)
aws ec2 create-network-acl-entry \
    --network-acl-id $NACL_ID \
    --egress \
    --rule-number 100 \
    --protocol tcp \
    --port-range From=1024,To=65535 \
    --cidr-block 0.0.0.0/0 \
    --rule-action allow

# Associate NACL with subnet
aws ec2 associate-network-acl --network-acl-id $NACL_ID --subnet-id $PRIVATE_SUBNET_ID
```

### Security Groups
```bash
# Create security group
SG_ID=$(aws ec2 create-security-group \
    --group-name web-server-sg \
    --description "Security group for web servers" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text)

# Authorize inbound SSH
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 203.0.113.0/24

# Authorize inbound HTTP/HTTPS
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# Authorize outbound (default allows all, but explicit is clearer)
aws ec2 authorize-security-group-egress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 0 \
    --port-range From=0,To=65535 \
    --cidr-block 0.0.0.0/0
```

### VPC Peering
```bash
# Create VPC peering connection
PEERING_ID=$(aws ec2 create-vpc-peering-connection \
    --vpc-id $VPC_ID \
    --peer-vpc-id $PEER_VPC_ID \
    --query 'VpcPeeringConnection.VpcPeeringConnectionId' --output text)

# Accept peering connection (in accepter account)
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $PEERING_ID

# Add route in requester VPC
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block $PEER_VPC_CIDR --vpc-peering-connection-id $PEERING_ID

# Add route in accepter VPC
aws ec2 create-route --route-table-id $PEER_RTB_ID --destination-cidr-block $VPC_CIDR --vpc-peering-connection-id $PEERING_ID
```

## Best Practices

### VPC Design
1. **Plan CIDR carefully**: Leave room for growth, avoid overlaps with other networks
2. **AZ Distribution**: Spread resources across multiple AZs for high availability
3. **Subnet Sizing**: Right-size subnets based on expected resource count
4. **Naming Convention**: Use consistent naming for resources (env-app-component)
5. **Tagging Strategy**: Implement comprehensive tagging for cost allocation and management

### Network Security
1. **Layered Security**: Use NACLs (subnet level) + Security Groups (instance level)
2. **Principle of Least Privilege**: Start with deny all, add only necessary rules
3. **Security Group References**: Reference other SGs instead of IP ranges when possible
4. **Regular Audits**: Use AWS Config rules to monitor for insecure configurations
5. **Flow Logs**: Enable VPC Flow Logs for monitoring and troubleshooting

### High Availability
1. **Multi-AZ Resources**: Distribute resources across multiple Availability Zones
2. **Load Balancing**: Use Application Load Balancer or Network Load Balancer
3. **Auto Scaling**: Combine with launch templates for automatic scaling
4. **Route Table Redundancy**: Maintain consistent routing across AZs
5. **NAT Gateway per AZ**: For private subnet internet access in each AZ

### Cost Optimization
1. **Right-size Instances**: Match instance type to workload requirements
2. **Use VPC Endpoints**: For S3, DynamoDB to avoid NAT Gateway costs
3. **Monitor NAT Usage**: High NAT Gateway costs indicate inefficient architecture
4. **Consider Transit Gateway**: For many VPC connections (more cost-effective than peering)
5. **Clean Up Unused Resources**: Detach and delete unused IGWs, NGWs, peerings

### Troubleshooting
1. **Check Route Tables**: Most connectivity issues are routing problems
2. **Verify Security Groups**: Ensure required ports are open
3. **Check NACLs**: Remember they're stateless - need rules in both directions
4. **Use VPC Flow Logs**: To see what traffic is being allowed/blocked
5. **Test with Network Manager**: Use Reachability Analyzer for path testing
6. **Ping/Traceroute**: From EC2 instances to test connectivity
7. **DNS Resolution**: Verify enableDnsHostnames and enableDnsSupport

## Hands-On Exercise Preparation
Tomorrow's hands-on exercise will involve:
1. Creating a VPC with public and private subnets
2. Setting up Internet Gateway and NAT Gateway
3. Configuring route tables for proper traffic flow
4. Launching EC2 instances in public and private subnets
5. Setting up a bastion host for private subnet access
6. Testing connectivity between subnets

Make sure you have:
- AWS CLI installed and configured
- Key pair ready for EC2 instances
- Basic understanding of networking concepts (subnets, routing, NAT)