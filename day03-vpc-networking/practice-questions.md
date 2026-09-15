# Day 3: VPC Practice Questions

## Multiple Choice Questions

### Question 1: What is the CIDR block size limit for a VPC?
A) /16 to /28
B) /8 to /24
C) /12 to /20
D) No limit

<details>
<summary>Answer</summary>
A) VPC CIDR blocks can range from /16 (65,536 IP addresses) to /28 (16 IP addresses)
</details>
</p>

### Question 2: How many subnets can you create per VPC by default?
A) 50 subnets per VPC
B) 100 subnets per VPC
C) 200 subnets per VPC
D) No default limit

<details>
<summary>Answer</summary>
D) There is no default limit on the number of subnets per VPC (limited by IP address availability in your CIDR block)
</details>
</p>

### Question 3: What is the purpose of a NAT gateway?
A) To allow instances in private subnets to initiate outbound IPv4 traffic to the internet
B) To allow inbound internet traffic to instances in private subnets
C) To provide DNS resolution for VPC resources
D) To encrypt traffic between VPC and on-premises networks

<details>
<summary>Answer</summary>
A) NAT gateway enables instances in private subnets to initiate outbound IPv4 traffic to the internet (or other AWS services), but prevents the internet from initiating connections with those instances
</details>
</p>

### Question 4: Difference between network ACL and security group?
A) NACL is stateless, SG is stateful; NACL operates at subnet level, SG at instance level
B) NACL is stateful, SG is stateless; NACL operates at instance level, SG at subnet level
C) Both are stateful and operate at the same level
D) Both are stateless and operate at different levels

<details>
<summary>Answer</summary>
A) Network ACLs are stateless (require explicit allow rules for return traffic) and operate at subnet level. Security groups are stateful (return traffic automatically allowed) and operate at instance level
</details>
</p>

### Question 5: How does VPC peering work?
A) Creates a direct network route between two VPCs using private IP addresses
B) Uses the public internet to connect VPCs through encrypted tunnels
C) Requires a VPN gateway in each VPC to establish the connection
D) Transfers data through AWS backbone but requires public IP addresses

<details>
<summary>Answer</summary>
A) VPC peering creates a direct network route between two VPCs using private IP addresses, allowing instances in either VPC to communicate as if they were on the same network
</details>
</p>

## Scenario-Based Questions

### Scenario 1: Three-Tier Web Application
You need to design a VPC for a three-tier web application (web, application, database) with these requirements:
- Web tier must be publicly accessible via HTTP/HTTPS
- Application tier should only be accessible from web tier
- Database tier should only be accessible from application tier
- All tiers need to be highly available across multiple AZs
- Instances in private tiers need internet access for updates/patches
- Budget is a consideration

How would you design this VPC?

<details>
<summary>Answer</summary>
1. **VPC CIDR**: 10.0.0.0/16 (provides ample room for growth)
2. **Availability Zones**: Use at least 2 AZs (us-east-1a, us-east-1b) for HA
3. **Subnet Design**:
   - **Public Subnets** (web tier): 10.0.1.0/24 (AZ-a), 10.0.2.0/24 (AZ-b)
   - **Private Subnets** (app tier): 10.0.3.0/24 (AZ-a), 10.0.4.0/24 (AZ-b)
   - **Database Subnets** (db tier): 10.0.5.0/24 (AZ-a), 10.0.6.0/24 (AZ-b)
4. **Internet Access**:
   - **Internet Gateway**: Attached to VPC for public subnet access
   - **NAT Gateways**: One in each AZ (in public subnets) for private subnet internet access
5. **Routing**:
   - **Public Subnet RT**: Route 0.0.0.0/0 → Internet Gateway
   - **Private Subnet RT**: Route 0.0.0.0/0 → NAT Gateway (same AZ)
   - **Database Subnet RT**: No route to 0.0.0.0/0 (isolated for security)
6. **Security**:
   - **Web SG**: Allow HTTP(80)/HTTPS(443) from 0.0.0.0/0, SSH(22) from admin IPs
   - **App SG**: Allow traffic from Web SG on app ports, SSH from admin IPs
   - **DB SG**: Allow traffic from App SG on db port (e.g., 3306 for MySQL)
7. **Cost Optimization**:
   - Use NAT Gateways (managed) instead of NAT Instances
   - Right-size instances based on tier requirements
   - Consider VPC Endpoints for S3/DynamoDB if needed
</details>
</p>

### Scenario 2: Hybrid Cloud Connection
Your company needs to connect their on-premises data center to AWS VPC for:
- Secure access to AWS resources from corporate network
- Ability to extend on-premises applications to AWS
- Compliance requirements for data in transit encryption
- Predictable network performance
- Cost-effective solution for steady bandwidth needs

Which AWS connectivity option would you recommend and why?

<details>
<summary>Answer</summary>
**AWS Site-to-Site VPN** is recommended because:
1. **Security**: Uses IPsec encryption for data in transit
2. **Compatibility**: Works with most existing VPN hardware/software
3. **Cost**: Lower upfront cost than Direct Connect (no port hours)
4. **Setup Time**: Can be provisioned in minutes to hours
5. **Scalability**: Supports up to 1.25 Gbps per tunnel, two tunnels for HA
6. **Management**: AWS manages the VGW side, customer manages CGW
7. **Flexibility**: Supports both static and dynamic (BGP) routing

Consider **AWS Direct Connect** if:
- Need >1.25 Gbps consistent bandwidth
- Require consistent low-latency, low-jitter connection
- Have steady, predictable data transfer patterns
- Can justify higher upfront cost for long-term savings
</details>
</p>

### Scenario 3: VPC Peering Limitations
You have three VPCs: Dev (10.0.0.0/16), Staging (10.1.0.0/16), and Prod (10.2.0.0/16). You need:
- Dev to communicate with Staging
- Staging to communicate with Prod
- But Dev should NOT communicate directly with Prod (security requirement)
- All VPCs are in the same region

What VPC peering strategy would you implement and what are the limitations?

<details>
<summary>Answer</summary>
**Peering Strategy**:
1. Create peering connection: Dev ↔ Staging
2. Create peering connection: Staging ↔ Prod
3. Do NOT create peering connection: Dev ↔ Prod

**Limitations to Address**:
1. **Non-transitive Nature**: Dev cannot reach Prod via Staging (even though both are peered with Staging)
   - **Solution**: If Dev needs to reach Prod resources, must create separate peering or use Transit Gateway
2. **CIDR Overlap**: Ensure no overlapping CIDR blocks between peered VPCs
3. **Route Table Updates**: Each VPC needs route table entries pointing to the peering connection
4. **Security Group References**: Can reference peer VPC security groups in rules
5. **Limit**: Maximum 125 peering connections per VPC (monitor for growth)

**Alternative Solution**: Use **AWS Transit Gateway** for transitive routing and centralized management
</details>
</p>

## Hands-On Exercise Preparation Checklist

Before starting the hands-on exercise, ensure you have:
- [ ] AWS CLI installed and configured
- [ ] EC2 Key Pair created and downloaded (.pem file)
- [ ] Basic understanding of IP addressing and subnetting
- [ ] Familiarity with CIDR notation
- [ ] Text editor available
- [ ] Knowledge of basic TCP/UDP ports (22, 80, 443, 3306, etc.)
- [ ] Understanding of private vs public IP address ranges

## Next Steps
Complete the hands-on exercise in `hands-on-exercise.md` and then proceed to add your work to GitHub as described in the GitHub activity.