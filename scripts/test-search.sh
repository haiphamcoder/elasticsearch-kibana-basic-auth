#!/bin/bash

# Elasticsearch Search Testing Script
# Usage: ./test-search.sh [index_name] [query]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_INDEX="test-index"
DEFAULT_QUERY="elasticsearch"

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
        print_info "Testing Elasticsearch search functionality"
        echo ""
        
        read -p "Enter index name [${DEFAULT_INDEX}]: " index_name
        index_name=${index_name:-$DEFAULT_INDEX}
        
        read -p "Enter search query [${DEFAULT_QUERY}]: " query
        query=${query:-$DEFAULT_QUERY}
    else
        # Command line mode
        index_name=$1
        query=$2
    fi
}

# Function to check if index exists
check_index_exists() {
    print_info "Checking if index '$index_name' exists..."
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X HEAD "localhost:9200/$index_name")
    
    if [ $? -ne 0 ]; then
        print_error "Index '$index_name' does not exist"
        print_info "Please create the index first with: ./create-index.sh $index_name"
        exit 1
    fi
    
    print_success "Index exists"
}

# Function to test basic search
test_basic_search() {
    print_info "Testing basic search for: '$query'"
    
    search_json=$(cat <<EOF
{
  "query": {
    "multi_match": {
      "query": "$query",
      "fields": ["title", "content", "tags"]
    }
  },
  "size": 10,
  "sort": [
    {"_score": {"order": "desc"}},
    {"created_at": {"order": "desc"}}
  ]
}
EOF
)
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/$index_name/_search" \
        -H "Content-Type: application/json" \
        -d "$search_json")
    
    hits=$(echo "$response" | jq '.hits.total.value')
    took=$(echo "$response" | jq '.took')
    
    print_success "Search completed in ${took}ms"
    print_info "Found $hits matching documents"
    
    # Show top results
    echo ""
    print_info "Top results:"
    echo "$response" | jq -r '.hits.hits[] | "  • \(.source.title) (Score: \(.score))"'
}

# Function to test filtered search
test_filtered_search() {
    print_info "Testing filtered search (status: published)"
    
    search_json=$(cat <<EOF
{
  "query": {
    "bool": {
      "must": [
        {
          "multi_match": {
            "query": "$query",
            "fields": ["title", "content"]
          }
        }
      ],
      "filter": [
        {
          "term": {
            "status": "published"
          }
        }
      ]
    }
  },
  "size": 5
}
EOF
)
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/$index_name/_search" \
        -H "Content-Type: application/json" \
        -d "$search_json")
    
    hits=$(echo "$response" | jq '.hits.total.value')
    
    print_success "Filtered search completed"
    print_info "Found $hits published documents matching '$query'"
}

# Function to test aggregation
test_aggregation() {
    print_info "Testing aggregation (tags count)"
    
    search_json=$(cat <<EOF
{
  "size": 0,
  "aggs": {
    "tag_counts": {
      "terms": {
        "field": "tags",
        "size": 10
      }
    },
    "status_counts": {
      "terms": {
        "field": "status",
        "size": 10
      }
    }
  }
}
EOF
)
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/$index_name/_search" \
        -H "Content-Type: application/json" \
        -d "$search_json")
    
    print_success "Aggregation completed"
    
    echo ""
    print_info "Tag distribution:"
    echo "$response" | jq -r '.aggregations.tag_counts.buckets[] | "  • \(.key): \(.doc_count) documents"'
    
    echo ""
    print_info "Status distribution:"
    echo "$response" | jq -r '.aggregations.status_counts.buckets[] | "  • \(.key): \(.doc_count) documents"'
}

# Function to test range query
test_range_query() {
    print_info "Testing range query (priority >= 2)"
    
    search_json=$(cat <<EOF
{
  "query": {
    "bool": {
      "must": [
        {
          "multi_match": {
            "query": "$query",
            "fields": ["title", "content"]
          }
        }
      ],
      "filter": [
        {
          "range": {
            "priority": {
              "gte": 2
            }
          }
        }
      ]
    }
  },
  "size": 5
}
EOF
)
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/$index_name/_search" \
        -H "Content-Type: application/json" \
        -d "$search_json")
    
    hits=$(echo "$response" | jq '.hits.total.value')
    
    print_success "Range query completed"
    print_info "Found $hits documents with priority >= 2 matching '$query'"
}

# Function to test fuzzy search
test_fuzzy_search() {
    print_info "Testing fuzzy search for: '$query'"
    
    search_json=$(cat <<EOF
{
  "query": {
    "multi_match": {
      "query": "$query",
      "fields": ["title", "content"],
      "fuzziness": "AUTO"
    }
  },
  "size": 5
}
EOF
)
    
    response=$(docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/$index_name/_search" \
        -H "Content-Type: application/json" \
        -d "$search_json")
    
    hits=$(echo "$response" | jq '.hits.total.value')
    
    print_success "Fuzzy search completed"
    print_info "Found $hits documents with fuzzy matching for '$query'"
}

# Function to show index mapping
show_index_mapping() {
    print_info "Index mapping for '$index_name':"
    
    docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/$index_name/_mapping?pretty"
}

# Function to show cluster health
show_cluster_health() {
    print_info "Cluster health:"
    
    docker exec -it elasticsearch-1 curl -s -u elastic:elastic \
        -X GET "localhost:9200/_cluster/health?pretty"
}

# Main execution
main() {
    echo "🔍 Elasticsearch Search Testing Script"
    echo "====================================="
    
    check_elasticsearch
    get_user_input "$@"
    check_index_exists
    
    echo ""
    print_info "Running search tests..."
    echo ""
    
    test_basic_search
    echo ""
    test_filtered_search
    echo ""
    test_aggregation
    echo ""
    test_range_query
    echo ""
    test_fuzzy_search
    
    echo ""
    print_success "All search tests completed!"
    echo ""
    print_info "Additional information:"
    show_index_mapping
    echo ""
    show_cluster_health
}

# Run main function
main "$@"

