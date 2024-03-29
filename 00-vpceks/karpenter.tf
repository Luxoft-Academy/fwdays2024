resource "aws_iam_policy" "karpenter" {
  name   = "KarpenterPolicy-${var.tag}"
  path   = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:GetParameter",
        "ec2:DescribeImages",
        "ec2:RunInstances",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeInstanceTypeOfferings",
        "ec2:DescribeAvailabilityZones",
        "ec2:DeleteLaunchTemplate",
        "ec2:CreateTags",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateFleet",
        "ec2:DescribeSpotPriceHistory",
        "pricing:GetProducts"
      ],
      "Effect": "Allow",
      "Resource": "*",
      "Sid": "Karpenter"
    },
    {
      "Action": "ec2:TerminateInstances",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/karpenter.sh/nodepool": "*"
        }
      },
      "Effect": "Allow",
      "Resource": "*",
      "Sid": "ConditionalEC2Termination"
    },
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "*",
      "Sid": "PassNodeIAMRole"
    },
    {
      "Effect": "Allow",
      "Action": "eks:DescribeCluster",
      "Resource": "arn:aws:eks:${local.region}:${local.account_id}:cluster/${var.tag}",
      "Sid": "EKSClusterEndpointLookup"
    },
    {
      "Sid": "AllowScopedInstanceProfileCreationActions",
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "iam:CreateInstanceProfile"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/kubernetes.io/cluster/${var.tag}": "owned",
          "aws:RequestTag/topology.kubernetes.io/region": "${local.region}"
        },
        "StringLike": {
          "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
        }
      }
    },
    {
      "Sid": "AllowScopedInstanceProfileTagActions",
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "iam:TagInstanceProfile"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/kubernetes.io/cluster/${var.tag}": "owned",
          "aws:ResourceTag/topology.kubernetes.io/region": "${local.region}",
          "aws:RequestTag/kubernetes.io/cluster/${var.tag}": "owned",
          "aws:RequestTag/topology.kubernetes.io/region": "${local.region}"
        },
        "StringLike": {
          "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*",
          "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass": "*"
        }
      }
    },
    {
      "Sid": "AllowScopedInstanceProfileActions",
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:DeleteInstanceProfile"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/kubernetes.io/cluster/${var.tag}": "owned",
          "aws:ResourceTag/topology.kubernetes.io/region": "${local.region}"
        },
        "StringLike": {
          "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass": "*"
        }
      }
    },
    {
      "Sid": "AllowInstanceProfileReadActions",
      "Effect": "Allow",
      "Resource": "*",
      "Action": "iam:GetInstanceProfile"
    }
  ]
}
EOF
}

resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name                      = module.eks.cluster_name
  message_retention_seconds = 300
  kms_master_key_id         = "alias/aws/sqs"
}

resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.id

  policy = jsonencode({
    Id      = "EC2InterruptionPolicy",
    Version = "2008-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "scheduled_change_rule" {
  name = "ScheduledChangeRule"
  event_pattern = jsonencode({
    source = [
      "aws.health"
    ],
    "detail-type" = [
      "AWS Health Event"
    ]
  })
}

resource "aws_cloudwatch_event_target" "scheduled_change_target" {
  rule      = aws_cloudwatch_event_rule.scheduled_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}
