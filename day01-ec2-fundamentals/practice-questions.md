# Day 1: EC2 Practice Questions

## Multiple Choice Questions

### Question 1: What is the difference between stop and terminate an EC2 instance?
A) Stopped instances retain EBS volumes, terminated instances delete them by default
B) Stopped instances incur full charges, terminated instances are free
C) Stopped instances lose their public IP, terminated instances keep it
D) Stopped instances cannot be started again, terminated instances can be restarted

<details>
<summary>Answer</summary>
A) Stopped instances retain EBS volumes (unless delete-on-termination is set), terminated instances delete EBS volumes by default
</details>
</p>

### Question 2: How can you assign an Elastic IP to an instance?
A) Through EC2 Console > Elastic IPs > Associate Address
B) Using AWS CLI: aws ec2 associate-address
C) During instance launch in the Network & Security section
D) All of the above

<details>
<summary>Answer</summary>
D) All of the above methods are valid for assigning an Elastic IP to an instance
</details>
</p>

### Question 3: Which EC2 purchasing option offers the highest discount?
A) On-Demand Instances
B) Reserved Instances (1-year, No Upfront)
C) Reserved Instances (3-year, All Upfront)
D) Spot Instances

<details>
<summary>Answer</summary>
C) Reserved Instances (3-year, All Upfront) typically offer up to 72% discount compared to On-Demand
</details>
</p>

### Question 4: What is the default limit for security groups per region?
A) 50 security groups per region
B) 100 security groups per region
C) 250 security groups per region
D) 500 security groups per region

<details>
<summary>Answer</summary>
A) Default limit is 50 security groups per region (can be increased upon request)
</details>
</p>

### Question 5: How do you enable detailed monitoring on an EC2 instance?
A) Through CloudWatch console > Metrics > Enable detailed monitoring
B) Using AWS CLI: aws ec2 monitor-instances --instance-ids i-xxxxxxxx
C) During instance launch in Monitoring section
D) Both B and C

<details>
<summary>Answer</summary>
D) Both B and C - you can enable during launch or after using CLI/console
</details>
</p>

## Scenario-Based Questions

### Scenario 1: Web Application Deployment
You need to deploy a web application that expects steady traffic with occasional spikes. Which EC2 purchasing strategy would you recommend and why?

<details>
<summary>Answer</summary>
Recommend a combination of Reserved Instances for baseline capacity and Spot Instances for handling spikes. This provides cost savings for steady workloads while maintaining flexibility for traffic bursts.
</details>
</p>

### Scenario 2: Security Compliance
Your organization requires that all EC2 instances must have SSH access restricted to specific corporate IP ranges. How would you implement and verify this?

<details>
<summary>Answer</summary>
1. Create security group with inbound SSH rule restricted to corporate IP ranges
2. Apply this security group to all EC2 instances
3. Use AWS Config rules to monitor for non-compliant security group configurations
4. Regularly audit using AWS CLI: aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=22 Name=ip-permission.to-port,Values=22 Name=ip-permission.protocol,Values=tcp
</details>
</p>

### Scenario 3: Cost Optimization
You notice your EC2 costs are 40% higher than expected. What steps would you take to identify and reduce unnecessary spending?

<details>
<summary>Answer</summary>
1. Use AWS Cost Explorer to identify high-cost instances
2. Check CloudWatch metrics for CPU/utilization - look for underutilized instances
3. Review instance types - ensure right-sizing
4. Check for stopped instances still incurring EBS charges
5. Review Reserved Instance utilization and coverage reports
6. Implement automated shutdown schedules for dev/test environments
7. Consider migrating to newer generation instances for better price-performance
</details>
</p>

## Hands-On Exercise Preparation Checklist

Before starting the hands-on exercise, ensure you have:
- [ ] AWS CLI installed (version 2 recommended)
- [ ] AWS credentials configured (aws configure)
- [ ] A key pair created and downloaded (.pem file)
- [ ] Basic understanding of Linux commands (ls, cd, mkdir, etc.)
- [ ] Text editor available (VS Code, vim, nano)
- [ ] Port 22 (SSH) and 80 (HTTP) accessible from your network

## Next Steps
Complete the hands-on exercise in `hands-on-exercise.md` and then proceed to add your work to GitHub as described in the GitHub activity.