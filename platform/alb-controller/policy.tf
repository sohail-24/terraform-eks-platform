resource "aws_iam_policy" "alb_policy" {

  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_attach" {

  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_policy.arn
}
