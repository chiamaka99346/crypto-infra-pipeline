Feature: Encryption at rest must be enabled for all storage resources
  In order to protect sensitive data
  As a security engineer
  I want to ensure all storage resources are encrypted

  Scenario: RDS instances must have encryption enabled
    Given I have aws_db_instance defined
    Then it must contain storage_encrypted
    And its value must be true

  Scenario: S3 buckets must have encryption enabled
    Given I have aws_s3_bucket defined
    When it has server_side_encryption_configuration
    Then it must have rule
    And it must have apply_server_side_encryption_by_default
    And it must have sse_algorithm

  Scenario: KMS keys must have rotation enabled
    Given I have aws_kms_key defined
    Then it must contain enable_key_rotation
    And its value must be true

  Scenario: EBS volumes must be encrypted
    Given I have aws_ebs_volume defined
    Then it must contain encrypted
    And its value must be true