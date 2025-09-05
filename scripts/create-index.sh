#!/bin/bash

# Elasticsearch Index Creation Script
# Usage: ./create-index.sh [index_name] [shards] [replicas]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_INDEX="test-index"
DEFAULT_SHARDS="3"
DEFAULT_REPLICAS="1"

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
        print_info "Creating Elasticsearch index interactively"
        echo ""
        
        read -p "Enter index name [${DEFAULT_INDEX}]: " index_name
        index_name=${index_name:-$DEFAULT_INDEX}
        
        read -p "Enter number of shards [${DEFAULT_SHARDS}]: " shards
        shards=${shards:-$DEFAULT_SHARDS}
        
        read -p "Enter number of replicas [${DEFAULT_REPLICAS}]: " replicas
        replicas=${replicas:-$DEFAULT_REPLICAS}
    else
        # Command line mode
        index_name=$1
        shards=$2
        replicas=$3
    fi
}

# Function to check if index already exists
check_index_exists() {
    print_info "Checking if index '$index_name' already exists..."
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X HEAD "localhost:9200/$index_name")
    
    if [ $? -eq 0 ]; then
        print_warning "Index '$index_name' already exists"
        read -p "Do you want to delete and recreate it? (y/N): " recreate
        if [[ $recreate =~ ^[Yy]$ ]]; then
            print_info "Deleting existing index..."
            docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
                -X DELETE "localhost:9200/$index_name" > /dev/null
            print_success "Index deleted"
        else
            print_info "Keeping existing index"
            exit 0
        fi
    else
        print_info "Index does not exist, proceeding with creation"
    fi
}

# Function to create index
create_index() {
    print_info "Creating index: $index_name"
    print_info "Shards: $shards, Replicas: $replicas"
    
    # Create index with mapping
    index_json=$(cat <<EOF
{
  "settings": {
    "number_of_shards": $shards,
    "number_of_replicas": $replicas,
    "index": {
      "refresh_interval": "1s",
      "max_result_window": 10000
    }
  },
  "mappings": {
    "properties": {
      "id": {
        "type": "keyword"
      },
      "title": {
        "type": "text",
        "analyzer": "standard"
      },
      "content": {
        "type": "text",
        "analyzer": "standard"
      },
      "tags": {
        "type": "keyword"
      },
      "created_at": {
        "type": "date",
        "format": "strict_date_optional_time||epoch_millis"
      },
      "updated_at": {
        "type": "date",
        "format": "strict_date_optional_time||epoch_millis"
      },
      "status": {
        "type": "keyword"
      },
      "priority": {
        "type": "integer"
      },
      "metadata": {
        "type": "object",
        "dynamic": true
      }
    }
  }
}
EOF
)
    
    # Create index via Elasticsearch API
    response=$(docker exec -it elasticsearch-1 curl -s -w "\n%{http_code}" -u elastic:elastic \
        -X PUT "localhost:9200/$index_name" \
        -H "Content-Type: application/json" \
        -d "$index_json")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        print_success "Index '$index_name' created successfully"
    else
        print_error "Failed to create index. HTTP Code: $http_code"
        echo "Response: $response_body"
        exit 1
    fi
}

# Function to verify index creation
verify_index() {
    print_info "Verifying index creation..."
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/$index_name")
    
    if echo "$response" | grep -q "\"$index_name\""; then
        print_success "Index verification successful"
    else
        print_error "Index verification failed"
        exit 1
    fi
}

# Function to add sample data
add_sample_data() {
    print_info "Adding sample data to index..."
    
    # Sample documents
    sample_docs=(
        '{"id":"1","title":"Introduction to Elasticsearch","content":"Elasticsearch is a distributed search and analytics engine.","tags":["elasticsearch","search","analytics"],"created_at":"2024-01-01T00:00:00Z","status":"published","priority":1,"metadata":{"author":"admin","category":"tutorial"}}'
        '{"id":"2","title":"Kibana Dashboard Guide","content":"Kibana provides visualization and dashboard capabilities.","tags":["kibana","dashboard","visualization"],"created_at":"2024-01-02T00:00:00Z","status":"published","priority":2,"metadata":{"author":"admin","category":"guide"}}'
        '{"id":"3","title":"Logstash Data Processing","content":"Logstash processes and transforms data before sending to Elasticsearch.","tags":["logstash","data","processing"],"created_at":"2024-01-03T00:00:00Z","status":"draft","priority":3,"metadata":{"author":"user","category":"tutorial"}}'
        '{"id":"4","title":"Elasticsearch Performance Tuning","content":"Tips and tricks for optimizing Elasticsearch performance.","tags":["elasticsearch","performance","optimization"],"created_at":"2024-01-04T00:00:00Z","status":"published","priority":1,"metadata":{"author":"expert","category":"advanced"}}'
        '{"id":"5","title":"Monitoring Elasticsearch Cluster","content":"How to monitor your Elasticsearch cluster health and performance.","tags":["elasticsearch","monitoring","cluster"],"created_at":"2024-01-05T00:00:00Z","status":"published","priority":2,"metadata":{"author":"admin","category":"operations"}}'
    )
    
    for doc in "${sample_docs[@]}"; do
        # Extract ID from document
        doc_id=$(echo "$doc" | jq -r '.id')
        
        # Index document
        response=$(docker exec -it elasticsearch-1 curl -s -w "\n%{http_code}" -u elastic:elastic \
            -X POST "localhost:9200/$index_name/_doc/$doc_id" \
            -H "Content-Type: application/json" \
            -d "$doc")
        
        http_code=$(echo "$response" | tail -n1)
        
        if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
            print_success "Document $doc_id indexed successfully"
        else
            print_warning "Failed to index document $doc_id"
        fi
    done
}

# Function to refresh index
refresh_index() {
    print_info "Refreshing index to make documents searchable..."
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X POST "localhost:9200/$index_name/_refresh")
    
    if [ $? -eq 0 ]; then
        print_success "Index refreshed successfully"
    else
        print_warning "Failed to refresh index"
    fi
}

# Function to show index stats
show_index_stats() {
    print_info "Index statistics:"
    
    docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/$index_name/_stats?pretty" | jq '.indices | to_entries[] | {index: .key, docs: .value.total.docs.count, size: .value.total.store.size_in_bytes}'
}

# Main execution
main() {
    echo "📝 Elasticsearch Index Creation Script"
    echo "======================================"
    
    check_elasticsearch
    get_user_input "$@"
    check_index_exists
    create_index
    verify_index
    add_sample_data
    refresh_index
    show_index_stats
    
    echo ""
    print_success "Index creation completed successfully!"
    echo ""
    print_info "Index details:"
    echo "  Name: $index_name"
    echo "  Shards: $shards"
    echo "  Replicas: $replicas"
    echo "  Sample documents: 5"
    echo ""
    print_info "You can now search the index:"
    echo "  curl -u elastic:elastic 'http://localhost:9200/$index_name/_search?pretty'"
    echo ""
    print_info "View in Kibana:"
    echo "  http://localhost:5601 (elastic/elastic)"
}

# Run main function
main "$@"

