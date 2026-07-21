## 📌 Description
<!-- Provide a clear and concise description of the changes introduced in this PR. Explain the context and why these changes are needed. -->

## 🛠️ Type of Change
- [ ] 🚀 New Feature (non-breaking change adding new functionality)
- [ ] 🐛 Bug Fix (non-breaking change fixing an issue)
- [ ] 🏗️ Infrastructure / IaC (Terraform, Docker, environment config)
- [ ] ⚡ Performance Optimization
- [ ] 🧹 Refactoring / Code Cleanup
- [ ] 📚 Documentation Update
- [ ] 🚨 Breaking Change (fix or feature that would cause existing functionality to not work as expected)

## 🧩 Component(s) Affected
- [ ] Ingestion / Producer (Python, Rust, Ruby)
- [ ] Message Broker (Kafka / Zookeeper)
- [ ] Stream Processing (Apache Flink / Spark Streaming)
- [ ] Storage & Catalog (MinIO / Apache Iceberg)
- [ ] Query Engine (Trino)
- [ ] Infrastructure (Terraform / Docker Compose)
- [ ] CI/CD & Testing

## 🧪 Verification & Testing
<!-- Describe the tests you ran to verify your changes. Include steps to reproduce, sample command executions, SQL query output, or Terraform plan/apply logs. -->

### Test Checklist
- [ ] `terraform validate` & `terraform plan` executed cleanly (if applicable)
- [ ] End-to-end data pipeline flow verified (Producer -> Broker -> Processing -> Storage -> Query Engine)
- [ ] Event deduplication / windowing verified with test event payloads
- [ ] Trino queries executed successfully against Iceberg tables

```sql
-- Paste sample Trino query or verification log here if applicable
```

## 📋 Pre-Merge Checklist
- [ ] Code follows project style and naming conventions
- [ ] Self-review performed on all modified files
- [ ] Relevant documentation/README updated
- [ ] No hardcoded secrets, credentials, or sensitive data added
- [ ] All new and existing tests pass locally

## 🔗 Related Issues & Pull Requests
<!-- Link any related issues or PRs here (e.g., Closes #12, Fixes #34) -->
- Fixes #
