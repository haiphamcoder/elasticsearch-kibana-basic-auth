# Elasticsearch Kibana Basic Authentication

A development and testing Docker Compose setup for Elasticsearch cluster with Kibana, featuring Basic Authentication for enhanced security. This setup provides a solid foundation that can be enhanced for production use.

## 🚀 Overview

This project provides a complete, containerized Elasticsearch cluster setup with Kibana dashboard, making it suitable for development, testing, and learning purposes.

**Use Cases:**

- 🧪 **Development environments**
- 🧪 **Testing and QA**
- 📚 **Learning Elasticsearch and Kibana**
- 🚀 **Foundation for production setup** (with enhancements)

**Not Suitable For:**

- ❌ **Production environments** (without significant modifications)
- ❌ **High-security requirements**
- ❌ **Compliance-heavy industries**

**Key Features:**

- **Elasticsearch Cluster**: 3-node cluster for high availability
- **Kibana Dashboard**: Web interface for data visualization
- **Basic Authentication**: Secure access with username/password
- **Docker Compose**: Easy deployment and management
- **Development Ready**: Includes basic security and monitoring

## 📋 Prerequisites

Before running this project, ensure you have the following installed:

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)
- **Bash shell** (for running scripts)
- **curl** (for testing API calls)
- **jq** (optional, for JSON processing)

### System Requirements

- **Memory**: Minimum 6GB RAM (2GB per Elasticsearch node)
- **Storage**: At least 20GB free disk space
- **CPU**: 4+ cores recommended

## 🏗️ System Architecture

### Elasticsearch Cluster

The cluster consists of:

- **3 Elasticsearch Nodes**: Each running with master, data, and ingest roles
- **Basic Authentication**: Username/password authentication
- **Docker Network**: Isolated container communication
- **Persistent Storage**: Data volumes for each node

### Kibana Integration

- **Web Interface**: Accessible on port 5601
- **Elasticsearch Connection**: Connected to all cluster nodes
- **Authentication**: Same credentials as Elasticsearch

### Security Model

- **Basic Authentication**: Username/password authentication
- **X-Pack Security**: Built-in security features
- **API Key Support**: For programmatic access
- **Audit Logging**: Security event logging

## 🚨 Production Readiness

### ⚠️ Current Status: Development/Testing Only

This setup is **NOT production-ready** as-is. It's designed for development, testing, and learning purposes. For production deployment, significant enhancements are required.

### 🔒 What's Missing for Production

**Security:**

- ❌ TLS/SSL encryption (currently plaintext)
- ❌ External secret management (hardcoded credentials)
- ❌ Role-based access control (RBAC)
- ❌ Network segmentation and firewall rules

**Monitoring & Observability:**

- ❌ Prometheus metrics export
- ❌ Grafana dashboards
- ❌ Centralized logging (ELK stack)
- ❌ Alerting and notification system

**Operational:**

- ❌ Backup and restore procedures
- ❌ Disaster recovery plan
- ❌ Resource limits and quotas
- ❌ Rolling update procedures
- ❌ Performance tuning

**Compliance:**

- ❌ Audit logging
- ❌ Data retention policies
- ❌ Compliance monitoring

### 🎯 Production Enhancement Roadmap

1. **Phase 1: Security Hardening**
   - Enable TLS/SSL encryption
   - Implement external secret management
   - Add role-based access control

2. **Phase 2: Monitoring & Alerting**
   - Deploy Prometheus + Grafana
   - Setup centralized logging
   - Implement alerting rules

3. **Phase 3: Operational Excellence**
   - Backup automation
   - Performance tuning
   - Disaster recovery procedures

## 🛠️ Setup and Installation

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd elasticsearch-kibana-basic-auth
```

### 2. Create Environment File

```bash
# Create environment file with default credentials
make env

# Or create manually
echo "ELASTIC_USERNAME=elastic" > .env
echo "ELASTIC_PASSWORD=elastic" >> .env
echo "KIBANA_ENCRYPTION_KEY=changeme123456789012345678901234567890" >> .env
```

### 3. Start the Cluster

```bash
# Start all services
make up

# Or use Docker Compose directly
docker compose up -d
```

### 4. Wait for Cluster Initialization

The cluster takes a few minutes to start up. Monitor the logs:

```bash
make logs
# Or
docker compose logs -f
```

**Note**: The cluster will start automatically. All nodes run with master, data, and ingest roles. User and index management is handled through the provided shell scripts and Makefile commands.

### 5. Verify Cluster Status

```bash
make status
# Or
docker compose ps
```

## 🚀 Quick Start

### Using Makefile (Recommended)

```bash
# Complete setup in one command
make quick-start

# This will:
# 1. Create environment file
# 2. Start cluster and Kibana
# 3. Create test user
# 4. Create test index with sample data
```

### Manual Setup

```bash
# 1. Start cluster
make up

# 2. Wait for startup
sleep 60

# 3. Create test user
make create-user

# 4. Create test index
make create-index

# 5. Test search functionality
make test-search
```

## 📖 Usage

### Scripts Overview

All scripts are located in the `scripts/` directory and support both interactive and command-line modes.

#### 1. User Management

**Create Elasticsearch User**:

```bash
# Interactive mode
./scripts/create-user.sh

# Command-line mode
./scripts/create-user.sh myuser mypassword '["kibana_user", "monitoring_user"]'
```

**Using Makefile**:

```bash
make create-user          # Interactive
make list-users           # List all users
```

#### 2. Index Management

**Create Index**:

```bash
# Interactive mode
./scripts/create-index.sh

# Command-line mode
./scripts/create-index.sh my-index 3 1
# Creates index 'my-index' with 3 shards and 1 replica
```

**Using Makefile**:

```bash
make create-index         # Interactive
make list-indices         # List all indices
```

#### 3. Search Testing

**Test Search Functionality**:

```bash
# Interactive mode
./scripts/test-search.sh

# Command-line mode
./scripts/test-search.sh my-index "search query"
```

**Using Makefile**:

```bash
make test-search          # Interactive
make test-connection      # Test Elasticsearch connection
make test-kibana          # Test Kibana connection
```

### Makefile Commands

The project includes a comprehensive Makefile for easy management:

```bash
# Cluster Management
make up                    # Start cluster
make down                  # Stop cluster
make restart               # Restart cluster
make status                # Show container status
make logs                  # View logs

# Setup and Configuration
make setup                 # Complete initial setup
make create-user           # Create Elasticsearch user
make create-index          # Create test index

# Testing
make test-connection       # Test Elasticsearch connection
make test-search           # Test search functionality
make test-kibana           # Test Kibana connection

# Cleanup
make clean                 # Remove containers and networks
make clean-volumes         # Remove Elasticsearch data volumes (⚠️ DANGEROUS)
make clean-all             # Remove everything including images

# Monitoring
make health                # Check cluster health
make metrics               # Show cluster metrics
make indices               # Show indices information
make users                 # Show users information

# Help
make help                  # Show all available commands
```

## ⚙️ Configuration Details

### Docker Compose Configuration

The `docker-compose.yml` file defines:

- **3 Elasticsearch Nodes**: Each running on different ports (9200, 9201, 9202)
- **Kibana**: Web interface on port 5601
- **Basic Authentication**: Username/password authentication
- **Volume Mounts**: Persistent data storage and configuration
- **Network Configuration**: Internal cluster communication

**Key Environment Variables:**

```yaml
ELASTIC_USERNAME: "elastic"
ELASTIC_PASSWORD: "elastic"
KIBANA_ENCRYPTION_KEY: "changeme123456789012345678901234567890"
```

### Elasticsearch Configuration

The `config/elasticsearch.yml` file configures:

- **Cluster Settings**: Cluster name and node roles
- **Security Settings**: X-Pack security configuration
- **Performance Settings**: Memory and thread pool configuration
- **Index Settings**: Default index configuration

**Key Configuration:**

```yaml
cluster.name: "elasticsearch-cluster"
node.roles: ["master", "data", "ingest"]
xpack.security.enabled: true
xpack.license.self_generated.type: basic
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Cluster Startup Issues

**Problem**: Elasticsearch nodes fail to start with memory errors

```bash
# Solution: Check available memory
free -h
# Ensure at least 6GB RAM available
```

**Problem**: Authentication errors during startup

```bash
# Solution: Check credentials
cat .env
# Verify ELASTIC_USERNAME and ELASTIC_PASSWORD are set
```

#### 2. Connection Issues

**Problem**: Cannot connect to Elasticsearch

```bash
# Solution: Check cluster health
make health
# Verify all nodes are running
```

**Problem**: Kibana cannot connect to Elasticsearch

```bash
# Solution: Check Elasticsearch connection
docker exec -it kibana curl -u elastic:elastic http://elasticsearch-1:9200/_cluster/health
```

#### 3. Performance Issues

**Problem**: Slow cluster startup

```bash
# Solution: Increase memory allocation
# Edit docker-compose.yml and increase ES_JAVA_OPTS
```

**Problem**: High memory usage

```bash
# Solution: Monitor resource usage
docker stats
# Adjust JVM heap settings if necessary
```

### Debug Commands

```bash
# Check cluster health
make health

# View detailed metrics
make metrics

# Check indices
make indices

# Inspect container configuration
make shell
```

## 📊 Monitoring and Health Checks

### Health Check Commands

```bash
# Basic health check
make health

# Detailed metrics
make metrics

# Indices information
make indices

# Container status
make status
```

### Log Monitoring

```bash
# Follow all logs
make logs

# Follow specific service logs
docker compose logs -f elasticsearch-1
docker compose logs -f kibana
```

## 🔒 Security Considerations

### Current Security Status

⚠️ **Important**: This setup is designed for development and testing. For production use, significant security enhancements are required.

**Current Security Features:**

- Basic username/password authentication
- Hardcoded credentials (not suitable for production)
- No TLS/SSL encryption
- No role-based access control

### Authentication Best Practices

1. **Strong Passwords**: Use complex passwords for production
2. **User Management**: Regularly audit user accounts
3. **Network Security**: Use TLS/SSL encryption in production
4. **Access Control**: Implement role-based access control

### Production Security Requirements

```bash
# Enable TLS encryption
# Add to docker-compose.yml:
# xpack.security.transport.ssl.enabled: "true"
# xpack.security.http.ssl.enabled: "true"

# Use external secret management
# Mount secrets from Docker secrets or external vaults

# Implement role-based access control
# Create custom roles with specific permissions
```

## 🧪 Testing

### Basic Functionality Test

```bash
# 1. Start cluster
make up

# 2. Wait for startup
sleep 60

# 3. Run complete test
make setup

# 4. Test search functionality
make test-search
```

### Advanced Testing

```bash
# Test user creation
./scripts/create-user.sh testuser testpass '["kibana_user"]'

# Test index creation
./scripts/create-index.sh test-index 3 1

# Test search functionality
./scripts/test-search.sh test-index "elasticsearch"

# Test Kibana access
curl -u elastic:elastic http://localhost:5601/api/status
```

## 📚 Additional Resources

### Elasticsearch Documentation

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Elasticsearch Security](https://www.elastic.co/guide/en/elasticsearch/reference/current/security.html)
- [Elasticsearch Configuration](https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html)

### Kibana Documentation

- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Kibana Security](https://www.elastic.co/guide/en/kibana/current/security.html)

### Docker and Docker Compose

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🤝 Contributing

We welcome contributions to improve this project! Here's how you can help:

### Contributing Guidelines

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**: Follow the existing code style
4. **Test your changes**: Ensure the cluster starts and functions correctly
5. **Commit your changes**: Use clear, descriptive commit messages
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**: Provide detailed description of changes

### Development Setup

```bash
# Clone your fork
git clone https://github.com/haiphamcoder/elasticsearch-kibana-basic-auth.git
cd elasticsearch-kibana-basic-auth

# Create development branch
git checkout -b dev/your-feature

# Make changes and test
make up
make setup
# ... test your changes ...

# Commit and push
git add .
git commit -m "Add amazing feature"
git push origin dev/your-feature
```

### Code Style

- Follow existing shell script conventions
- Use meaningful variable names
- Add comments for complex logic
- Ensure scripts are executable (`chmod +x`)
- Test all changes before submitting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Elastic team for the excellent documentation
- Docker team for containerization tools
- Contributors and users of this project

## 📞 Support

If you encounter issues or have questions:

1. **Check the troubleshooting section** above
2. **Review existing issues** in the repository
3. **Create a new issue** with detailed information
4. **Provide logs and error messages** for faster resolution

---

***Happy Elasticsearch-ing! 🚀***

*This README is maintained by the project contributors. For the latest updates, check the repository.*
