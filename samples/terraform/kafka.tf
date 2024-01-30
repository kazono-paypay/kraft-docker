provider "kafka" {
  bootstrap_servers = ["broker001:9092"]
  skip_tls_verify   = true
  tls_enabled       = true
  ca_cert           = file("/tmp/ca.crt")
  client_cert       = file("/tmp/terraform-client.crt")
  client_key        = file("/tmp/terraform-client.key")
  sasl_username     = "admin"
  sasl_password     = "admin-secret"
  sasl_mechanism    = "scram-sha256"
}

resource "kafka_topic" "test_topic_tls" {
  name               = "test-topic-created-by-terraform-via-sasl-ssl"
  replication_factor = 3
  partitions         = 3
}

resource "kafka_acl" "add_read_permission_to_test_topic_tls" {
  resource_name       = "test-topic-created-by-terraform-via-sasl-ssl"
  resource_type       = "Topic"
  acl_principal       = "User:client"
  acl_host            = "*"
  acl_operation       = "Read"
  acl_permission_type = "Allow"
}

resource "kafka_acl" "add_describe_permission_to_test_topic_tls" {
  resource_name       = "test-topic-created-by-terraform-via-sasl-ssl"
  resource_type       = "Topic"
  acl_principal       = "User:client"
  acl_host            = "*"
  acl_operation       = "Describe"
  acl_permission_type = "Allow"
}

resource "kafka_acl" "add_write_permission_to_test_topic_tls" {
  resource_name       = "test-topic-created-by-terraform-via-sasl-ssl"
  resource_type       = "Topic"
  acl_principal       = "User:client"
  acl_host            = "*"
  acl_operation       = "Write"
  acl_permission_type = "Allow"
}
