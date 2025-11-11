Feature: Resources must be properly tagged
  In order to manage resources effectively
  As a cloud engineer
  I want to ensure all resources are tagged appropriately

  Scenario: VPC resources must have tags
    Given I have aws_vpc defined
    Then it must contain tags

  Scenario: Subnet resources must have tags
    Given I have aws_subnet defined
    Then it must contain tags

  Scenario: Security groups must have tags
    Given I have aws_security_group defined
    Then it must contain tags

  Scenario: Load balancers must have tags
    Given I have aws_lb defined
    Then it must contain tags

  Scenario: Target groups must have tags
    Given I have aws_lb_target_group defined
    Then it must contain tags

  Scenario: ECS clusters must have tags
    Given I have aws_ecs_cluster defined
    Then it must contain tags

  Scenario: ECS task definitions must have tags
    Given I have aws_ecs_task_definition defined
    Then it must contain tags

  Scenario: ECS services must have tags
    Given I have aws_ecs_service defined
    Then it must contain tags

  Scenario: RDS instances must have tags
    Given I have aws_db_instance defined
    Then it must contain tags

  Scenario: RDS subnet groups must have tags
    Given I have aws_db_subnet_group defined
    Then it must contain tags

  Scenario: KMS keys must have tags
    Given I have aws_kms_key defined
    Then it must contain tags

  Scenario: Secrets Manager secrets must have tags
    Given I have aws_secretsmanager_secret defined
    Then it must contain tags

  Scenario: CloudWatch log groups must have tags
    Given I have aws_cloudwatch_log_group defined
    Then it must contain tags

  Scenario: IAM roles must have tags
    Given I have aws_iam_role defined
    Then it must contain tags