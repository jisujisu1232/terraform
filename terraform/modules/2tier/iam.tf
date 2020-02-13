#service Autoscaling group

resource "aws_iam_role" "service" {
  name = "${local.name_prefix}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "service" {
  name        = "${local.name_prefix}-policy"
  path        = "/"
  description = "${local.name_prefix}-policy"

  #CodePipeline 을 통해 S3 생성되는 build output Pattern
  #{bucket}/{pipeline name}/{output name}/???
  #pipeline name 최대 길이 20
  #output name 최대 길이 10
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::${var.service_bucket_name}"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
              "arn:aws:s3:::${var.service_bucket_name}/${var.deploy_s3_key_prefix}/*",
              "arn:aws:s3:::${var.service_bucket_name}/${length(format("%s%s", local.name_prefix, "-pipeline")) > 20 ? substr(format("%s%s", local.name_prefix, "-pipeline"), 0, 20) : format("%s%s", local.name_prefix, "-pipeline")}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "service" {
  role       = "${aws_iam_role.service.name}"
  policy_arn = "${aws_iam_policy.service.arn}"
}

resource "aws_iam_instance_profile" "service" {
  name = "${local.name_prefix}-profile"
  role = "${aws_iam_role.service.name}"
}
