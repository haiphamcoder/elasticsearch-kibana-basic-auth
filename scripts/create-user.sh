#!/bin/bash

# Elasticsearch User Creation Script
# Usage: ./create-user.sh [username] [password] [roles]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_USERNAME="testuser"
DEFAULT_PASSWORD="testpass"
DEFAULT_ROLES='["kibana_user", "monitoring_user"]'

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if Elasticsearch is running
check_elasticsearch() {
    print_info "Checking Elasticsearch connection..."
    
    if ! docker exec -it elasticsearch-1 curl -s -u elastic:elastic -X GET "localhost:9200/_cluster/health" > /dev/null 2>&1; then
        print_error "Elasticsearch is not running or not accessible"
        print_info "Please start the cluster first with: make up"
        exit 1
    fi
    
    print_success "Elasticsearch is running"
}

# Function to get user input
get_user_input() {
    if [ $# -eq 0 ]; then
        # Interactive mode
        echo ""
        print_info "Creating Elasticsearch user interactively"
        echo ""
        
        read -p "Enter username [${DEFAULT_USERNAME}]: " username
        username=${username:-$DEFAULT_USERNAME}
        
        read -s -p "Enter password [${DEFAULT_PASSWORD}]: " password
        echo ""
        password=${password:-$DEFAULT_PASSWORD}
        
        echo ""
        print_info "Available roles:"
        echo "  - kibana_user: Access to Kibana"
        echo "  - monitoring_user: Access to monitoring data"
        echo "  - watcher_admin: Manage watchers"
        echo "  - logstash_admin: Manage Logstash"
        echo "  - beats_admin: Manage Beats"
        echo "  - rollup_user: Access to rollup functionality"
        echo "  - transform_user: Access to transforms"
        echo "  - snapshot_user: Access to snapshots"
        echo "  - ingest_admin: Manage ingest pipelines"
        echo "  - cluster_admin: Full cluster access"
        echo "  - superuser: Superuser access"
        echo ""
        
        read -p "Enter roles (comma-separated) [kibana_user,monitoring_user]: " roles_input
        roles_input=${roles_input:-"kibana_user,monitoring_user"}
        
        # Convert comma-separated roles to JSON array
        IFS=',' read -ra ROLES_ARRAY <<< "$roles_input"
        roles="["
        for i in "${!ROLES_ARRAY[@]}"; do
            if [ $i -gt 0 ]; then
                roles+=","
            fi
            roles+="\"${ROLES_ARRAY[$i]// /}\""
        done
        roles+="]"
    else
        # Command line mode
        username=$1
        password=$2
        roles=${3:-$DEFAULT_ROLES}
    fi
}

# Function to create user
create_user() {
    print_info "Creating user: $username"
    
    # Create user JSON
    user_json=$(cat <<EOF
{
  "password": "$password",
  "roles": $roles,
  "full_name": "$username",
  "email": "$username@example.com"
}
EOF
)
    
    # Create user via Elasticsearch API
    response=$(docker exec -it elasticsearch-1 curl -s -w "\n%{http_code}" -u elastic:elastic \
        -X POST "localhost:9200/_security/user/$username" \
        -H "Content-Type: application/json" \
        -d "$user_json")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        print_success "User '$username' created successfully"
        print_info "Username: $username"
        print_info "Roles: $roles"
    else
        print_error "Failed to create user. HTTP Code: $http_code"
        echo "Response: $response_body"
        exit 1
    fi
}

# Function to verify user creation
verify_user() {
    print_info "Verifying user creation..."
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/_security/user/$username")
    
    if echo "$response" | grep -q "\"$username\""; then
        print_success "User verification successful"
    else
        print_error "User verification failed"
        exit 1
    fi
}

# Function to test user login
test_user_login() {
    print_info "Testing user login..."
    
    if docker exec -it elasticsearch-1 curl -s -u "$username:$password" \
        -X GET "localhost:9200/_cluster/health" > /dev/null 2>&1; then
        print_success "User login test successful"
    else
        print_error "User login test failed"
        exit 1
    fi
}

# Main execution
main() {
    echo "🔐 Elasticsearch User Creation Script"
    echo "====================================="
    
    check_elasticsearch
    get_user_input "$@"
    create_user
    verify_user
    test_user_login
    
    echo ""
    print_success "User creation completed successfully!"
    echo ""
    print_info "You can now use this user to connect to Elasticsearch:"
    echo "  Username: $username"
    echo "  Password: $password"
    echo "  Elasticsearch URL: http://localhost:9200"
    echo "  Kibana URL: http://localhost:5601"
    echo ""
    print_info "Test the connection:"
    echo "  curl -u $username:$password http://localhost:9200/_cluster/health"
}

# Run main function
main "$@"

