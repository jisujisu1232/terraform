resource "aws_codecommit_repository" "service" {
  repository_name = "${local.name_prefix}-codecommit"
  description     = "This is the ${var.service_name} App Repository"
  default_branch  = "master"
}



resource "aws_iam_role" "build" {
  name = "${local.name_prefix}-codebuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "build" {
  role = "${aws_iam_role.build.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::codepipeline-${var.region}-*"
      ],
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "${aws_codecommit_repository.service.arn}"
      ],
      "Action": [
        "codecommit:GitPull"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.service_bucket_name}",
        "arn:aws:s3:::${var.service_bucket_name}/*"
      ],
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ]
    },
    {
      "Action": "ssm:GetParameters",
      "Effect": "Allow",
      "Resource": "arn:aws:ssm:*:*:parameter/*"
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "service" {
  name          = "${local.name_prefix}-codebuild"
  description   = "${local.name_prefix} ${var.service_name} CodeBuild Project"
  build_timeout = "5"
  service_role  = "${aws_iam_role.build.arn}"

  artifacts {
    type      = "S3"
    packaging = "ZIP"
    location  = "${var.service_bucket_name}"
    path      = "${var.deploy_s3_key_prefix}/"
  }

  # cache {
  #   type     = "S3"
  #   location = "${var.service_bucket_name}"
  # }

  source {
    type            = "CODECOMMIT"
    location        = "${aws_codecommit_repository.service.clone_url_http}"
    git_clone_depth = 1
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # environment_variable {
    #   name  = "SOME_KEY1"
    #   value = "SOME_VALUE1"
    # }
    #
    # environment_variable {
    #   name  = "SOME_KEY2"
    #   value = "SOME_VALUE2"
    #   type  = "PARAMETER_STORE"
    # }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${local.name_prefix}-codebuild"
      stream_name = "codebuild"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${var.service_bucket_name}/build-log"
    }
  }

  tags = "${local.custom_tags}"
}

resource "aws_codedeploy_app" "service" {
  compute_platform = "Server"
  name             = "${local.name_prefix}-codedeploy"
}

resource "aws_iam_role" "deploy" {
  name = "${local.name_prefix}-codedeploy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = "${aws_iam_role.deploy.name}"
}

resource "aws_codedeploy_deployment_group" "service" {
  app_name              = "${aws_codedeploy_app.service.name}"
  deployment_group_name = "${terraform.workspace}"
  service_role_arn      = "${aws_iam_role.deploy.arn}"
  autoscaling_groups    = ["${aws_autoscaling_group.this.name}"]

  trigger_configuration {
    trigger_events     = ["DeploymentStart", "DeploymentSuccess", "DeploymentFailure"]
    trigger_name       = "deploy-trigger"
    trigger_target_arn = "${aws_sns_topic.admin.arn}"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  load_balancer_info {
    target_group_info {
      name = "${aws_lb_target_group.service_alb.name}"
    }
  }
  #
  # alarm_configuration {
  #   alarms  = ["my-alarm-name"]
  #   enabled = true
  # }
}

#pipeline
resource "aws_iam_role" "pipeline" {
  name = "${local.name_prefix}-pipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "pipeline" {
  name = "${local.name_prefix}-pipeline_policy"
  role = "${aws_iam_role.pipeline.id}"

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetApplicationRevision",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "devicefarm:ListProjects",
                "devicefarm:ListDevicePools",
                "devicefarm:GetRun",
                "devicefarm:GetUpload",
                "devicefarm:CreateUpload",
                "devicefarm:ScheduleRun"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "servicecatalog:ListProvisioningArtifacts",
                "servicecatalog:CreateProvisioningArtifact",
                "servicecatalog:DescribeProvisioningArtifact",
                "servicecatalog:DeleteProvisioningArtifact",
                "servicecatalog:UpdateProduct"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:ValidateTemplate"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeImages"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
}
EOF
}

# data "aws_kms_alias" "s3kmskey" {
#   name = "alias/myKmsKey"
# }

resource "aws_codepipeline" "codepipeline" {
  name     = "${local.name_prefix}-pipeline"
  role_arn = "${aws_iam_role.pipeline.arn}"

  artifact_store {
    location = "${var.service_bucket_name}"
    type     = "S3"

    # encryption_key {
    #   id   = "${data.aws_kms_alias.s3kmskey.arn}"
    #   type = "KMS"
    # }
  }

  stage {
    name = "${var.service_name}_Source"

    action {
      name             = "${var.service_name}_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_${var.service_name}"]

      configuration = {
        RepositoryName = "${local.name_prefix}-codecommit"
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "${var.service_name}_Build"

    action {
      name             = "${var.service_name}_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_${var.service_name}"]
      output_artifacts = ["output_${var.service_name}"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.service.name}"
      }
    }
  }

  stage {
    name = "${var.service_name}_Deploy"

    action {
      name            = "${var.service_name}_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["output_${var.service_name}"]
      version         = "1"

      configuration = {
        ApplicationName     = "${aws_codedeploy_app.service.name}"
        DeploymentGroupName = "${aws_codedeploy_deployment_group.service.deployment_group_name}"
      }
    }
  }
}

#CodeCommit Event -> CloudWatch Event Rule -> CodePipeline Start
resource "aws_iam_role" "event" {
  name = "${local.name_prefix}-event-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "event" {
  role = "${aws_iam_role.event.name}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "${aws_codepipeline.codepipeline.arn}"
            ]
        }
    ]
}
POLICY
}

resource "aws_cloudwatch_event_rule" "event" {
  name        = "${local.name_prefix}-event-rule"
  description = "codepipeline trigger"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.codecommit"
  ],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "resources": [
    "${aws_codecommit_repository.service.arn}"
  ],
  "detail": {
    "event": [
      "referenceCreated",
      "referenceUpdated"
    ],
    "referenceType": [
      "branch"
    ],
    "referenceName": [
      "master"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "event" {
  target_id = "${var.service_name}-codepipeline-target"
  arn       = "${aws_codepipeline.codepipeline.arn}"
  rule      = "${aws_cloudwatch_event_rule.event.name}"
  role_arn  = "${aws_iam_role.event.arn}"
}

resource "aws_iam_user" "codecommit_master" {
  name = "${var.service_name}-codecommit-master"
  path = "/"
}

resource "aws_iam_access_key" "codecommit_master" {
  user    = "${aws_iam_user.codecommit_master.name}"
}

resource "aws_iam_user_policy" "codecommit_master" {
  name = "${var.service_name}-codecommit-master-policy"
  user = "${aws_iam_user.codecommit_master.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codecommit:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_codecommit_repository.service.arn}"
    },
    {
      "Action": [
        "codecommit:DeleteRepository"
      ],
      "Effect": "Deny",
      "Resource": "${aws_codecommit_repository.service.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_user" "codecommit_normal_user" {
  name = "${var.service_name}-codecommit-user"
  path = "/"
}

resource "aws_iam_user_policy" "codecommit_normal_user" {
  name = "${var.service_name}-codecommit-user-policy"
  user = "${aws_iam_user.codecommit_normal_user.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codecommit:GitPull",
        "codecommit:GitPush"
      ],
      "Effect": "Allow",
      "Resource": "${aws_codecommit_repository.service.arn}"
    }
  ]
}
EOF
}
