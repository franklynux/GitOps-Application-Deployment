# GitOps-Application-Deployment

## Troubleshooting WordPress Connection to RDS

If you're seeing connection errors from WordPress to RDS, it's likely because the RDS instance is not publicly accessible and proper networking is not configured between your EKS cluster and RDS instance.

### Solution Options:

1. **Configure VPC Networking (Recommended)**:
   - Ensure EKS and RDS are in the same VPC
   - Configure RDS security group to allow traffic from EKS nodes
   - Use the provided script `check-rds-eks-connectivity.sh` to diagnose and fix

2. **Make RDS Publicly Accessible (Not Recommended for Production)**:
   - In the AWS Console, modify your RDS instance
   - Enable "Publicly Accessible" option
   - Configure security group to allow traffic from your EKS cluster's IP range

### Using the Connectivity Check Script:

1. Edit the script to include your EKS cluster name and RDS instance identifier
2. Run the script with AWS CLI configured
3. Follow the recommendations provided by the script

```bash
# Make the script executable
chmod +x check-rds-eks-connectivity.sh

# Run the script
./check-rds-eks-connectivity.sh
```