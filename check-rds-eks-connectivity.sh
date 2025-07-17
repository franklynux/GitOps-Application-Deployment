#!/bin/bash

# Get EKS cluster VPC ID
echo "Getting EKS cluster VPC ID..."
EKS_CLUSTER_NAME="your-eks-cluster-name"  # Replace with your EKS cluster name
EKS_VPC_ID=$(aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text)
echo "EKS VPC ID: $EKS_VPC_ID"

# Get RDS instance VPC ID
echo "Getting RDS instance VPC ID..."
RDS_INSTANCE_ID="wordpress-db"  # Replace with your RDS instance identifier
RDS_VPC_ID=$(aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --query "DBInstances[0].DBSubnetGroup.VpcId" --output text)
echo "RDS VPC ID: $RDS_VPC_ID"

# Check if they're in the same VPC
if [ "$EKS_VPC_ID" == "$RDS_VPC_ID" ]; then
    echo "✅ EKS and RDS are in the same VPC. Now checking security group configuration..."
    
    # Get RDS security group
    RDS_SG_ID=$(aws rds describe-db-instances --db-instance-identifier $RDS_INSTANCE_ID --query "DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId" --output text)
    echo "RDS Security Group ID: $RDS_SG_ID"
    
    # Get EKS node security group
    EKS_NODE_SG_ID=$(aws ec2 describe-security-groups --filters "Name=tag:aws:eks:cluster-name,Values=$EKS_CLUSTER_NAME" "Name=tag:aws:cloudformation:logical-id,Values=NodeSecurityGroup" --query "SecurityGroups[0].GroupId" --output text)
    echo "EKS Node Security Group ID: $EKS_NODE_SG_ID"
    
    # Check if RDS security group allows traffic from EKS nodes
    RULE_EXISTS=$(aws ec2 describe-security-groups --group-ids $RDS_SG_ID --query "SecurityGroups[0].IpPermissions[?FromPort==3306 && ToPort==3306 && contains(UserIdGroupPairs[].GroupId, '$EKS_NODE_SG_ID')]" --output text)
    
    if [ -z "$RULE_EXISTS" ]; then
        echo "❌ RDS security group does not allow traffic from EKS nodes. Adding rule..."
        aws ec2 authorize-security-group-ingress --group-id $RDS_SG_ID --protocol tcp --port 3306 --source-group $EKS_NODE_SG_ID
        echo "✅ Security group rule added."
    else
        echo "✅ RDS security group already allows traffic from EKS nodes."
    fi
else
    echo "❌ EKS and RDS are in different VPCs. You need to either:"
    echo "   1. Move RDS to the same VPC as EKS"
    echo "   2. Set up VPC peering between the two VPCs"
    echo "   3. Make RDS publicly accessible (not recommended for production)"
fi