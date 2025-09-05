# Elasticsearch Kibana Basic Auth Cluster Makefile
# Usage: make <target>

.PHONY: help up down restart logs status clean clean-volumes clean-all-volumes clean-all setup create-user create-index test-connection test-search health metrics indices users

# Default target
help:
	@echo "🚀 Elasticsearch Kibana Basic Auth Cluster Management"
	@echo ""
	@echo "📋 Available commands:"
	@echo "  up                    - Start Elasticsearch cluster and Kibana"
	@echo "  down                  - Stop Elasticsearch cluster and Kibana"
	@echo "  restart               - Restart Elasticsearch cluster and Kibana"
	@echo "  logs                  - Show logs from all services"
	@echo "  status                - Show status of all containers"
	@echo ""
	@echo "🔧 Setup & Configuration:"
	@echo "  setup                 - Initial setup (create user, index)"
	@echo "  create-user           - Create Elasticsearch user interactively"
	@echo "  create-index          - Create test index interactively"
	@echo "  list-indices          - List all indices"
	@echo "  list-users            - List all users"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test-connection       - Test Elasticsearch connection"
	@echo "  test-search           - Test search functionality"
	@echo "  test-kibana           - Test Kibana connection"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  clean                 - Remove containers and networks"
	@echo "  clean-volumes         - Remove Elasticsearch data volumes (⚠️ DANGEROUS)"
	@echo "  clean-all-volumes     - Remove ALL Docker volumes (⚠️ VERY DANGEROUS)"
	@echo "  clean-all             - Remove everything including images"
	@echo "  clean-logs            - Clean container logs"
	@echo "  clean-configs         - Clean configuration files"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  health                - Check cluster health"
	@echo "  metrics               - Show cluster metrics"
	@echo "  indices               - Show indices information"
	@echo "  users                 - Show users information"

# Docker Compose commands
up:
	@echo "🚀 Starting Elasticsearch cluster and Kibana..."
	docker compose up -d
	@echo "⏳ Waiting for cluster to be ready..."
	@sleep 30
	@echo "✅ Elasticsearch cluster and Kibana started!"

down:
	@echo "🛑 Stopping Elasticsearch cluster and Kibana..."
	docker compose down
	@echo "✅ Elasticsearch cluster and Kibana stopped!"

restart:
	@echo "🔄 Restarting Elasticsearch cluster and Kibana..."
	docker compose restart
	@echo "✅ Elasticsearch cluster and Kibana restarted!"

# Logs and status
logs:
	@echo "📋 Showing logs from all services..."
	docker compose logs -f

status:
	@echo "📊 Container status:"
	docker compose ps
	@echo ""
	@echo "🔍 Detailed status:"
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Setup and configuration
setup: create-user create-index
	@echo "✅ Setup completed!"

create-user:
	@echo "🔐 Creating Elasticsearch user interactively..."
	@./scripts/create-user.sh

create-index:
	@echo "📝 Creating test index interactively..."
	@./scripts/create-index.sh

list-indices:
	@echo "📋 Listing all indices:"
	@docker exec -it elasticsearch-1 curl -s -u elastic:elastic -X GET "localhost:9200/_cat/indices?v"

list-users:
	@echo "👥 Listing all users:"
	@docker exec -it elasticsearch-1 curl -s -u elastic:elastic -X GET "localhost:9200/_security/user"

# Testing
test-connection:
	@echo "🔌 Testing Elasticsearch connection..."
	@docker exec -it elasticsearch-1 curl -s -u elastic:elastic -X GET "localhost:9200/_cluster/health?pretty"

test-search:
	@echo "🔍 Testing search functionality..."
	@./scripts/test-search.sh

test-kibana:
	@echo "📊 Testing Kibana connection..."
	@curl -s -u elastic:elastic -X GET "http://localhost:5601/api/status" | jq '.' || echo "❌ Kibana not ready or jq not installed"

# Cleanup commands
clean:
	@echo "🧹 Cleaning up containers and networks..."
	docker compose down --remove-orphans
	@echo "✅ Cleanup completed!"

clean-volumes:
	@echo "⚠️  WARNING: This will delete ALL Elasticsearch data!"
	@echo "⚠️  Are you sure? Type 'yes' to continue:"
	@read -p "> " confirm && [ "$$confirm" = "yes" ] || exit 1
	@echo "🗑️  Removing Elasticsearch data volumes..."
	docker compose down -v
	@echo "✅ Elasticsearch data volumes removed!"

clean-all-volumes:
	@echo "⚠️  WARNING: This will delete ALL Docker volumes on your system!"
	@echo "⚠️  Are you sure? Type 'yes' to continue:"
	@read -p "> " confirm && [ "$$confirm" = "yes" ] || exit 1
	@echo "🗑️  Removing all Docker volumes..."
	docker volume prune -f
	@echo "✅ All Docker volumes removed!"

clean-all:
	@echo "⚠️  WARNING: This will delete EVERYTHING including images!"
	@echo "⚠️  Are you sure? Type 'yes' to continue:"
	@read -p "> " confirm && [ "$$confirm" = "yes" ] || exit 1
	@echo "🗑️  Removing everything..."
	docker compose down -v --rmi all
	docker system prune -af
	@echo "✅ Everything cleaned!"

clean-logs:
	@echo "🧹 Cleaning container logs..."
	docker system prune -f
	@echo "✅ Logs cleaned!"

clean-configs:
	@echo "🧹 Cleaning configuration files..."
	rm -f .env client.properties
	@echo "✅ Configuration files cleaned!"

# Monitoring
health:
	@echo "🏥 Checking cluster health..."
	@echo "1. Checking Elasticsearch nodes..."
	@docker exec -it elasticsearch-1 curl -s -u elastic:elastic -X GET "localhost:9200/_cluster/health?pretty" | grep -E "(status|number_of_nodes|active_shards)" || echo "❌ Elasticsearch not ready"
	@echo ""
	@echo "2. Checking Kibana..."
	@curl -s -u elastic:elastic -X GET "http://localhost:5601/api/status" | jq '.status.overall.state' 2>/dev/null || echo "❌ Kibana not ready"
	@echo ""
	@echo "3. Checking indices..."
	@make list-indices

metrics:
	@echo "📊 Cluster metrics:"
	@echo "Cluster Health:"
	@docker exec -it elasticsearch-1 curl -s -u elastic:elastic -X GET "localhost:9200/_cluster/health?pretty"
	@echo ""
	@echo "Node Stats:"
	@docker exec -it elasticsearch-1 curl -s -u elastic:elastic -X GET "localhost:9200/_nodes/stats?pretty" | jq '.nodes | to_entries[] | {name: .value.name, roles: .value.roles, jvm: .value.jvm.mem.heap_used_percent}'

indices:
	@echo "📋 Indices information:"
	@docker exec -it elasticsearch-1 curl -s -u elastic:elastic -X GET "localhost:9200/_cat/indices?v&s=index"

users:
	@echo "👥 Users information:"
	@docker exec -it elasticsearch-1 curl -s -u elastic:elastic -X GET "localhost:9200/_security/user?pretty"

# Utility commands
shell:
	@echo "🐚 Opening shell to elasticsearch-1..."
	docker exec -it elasticsearch-1 bash

kibana-shell:
	@echo "🐚 Opening shell to kibana..."
	docker exec -it kibana bash

# Environment setup
env:
	@echo "🔧 Creating environment file..."
	@echo "ELASTIC_USERNAME=elastic" > .env
	@echo "ELASTIC_PASSWORD=elastic" >> .env
	@echo "KIBANA_ENCRYPTION_KEY=changeme123456789012345678901234567890" >> .env
	@echo "✅ Environment file created!"

# Quick start
quick-start: env up setup
	@echo "🚀 Quick start completed!"
	@echo "📊 Kibana: http://localhost:5601 (elastic/elastic)"
	@echo "🔍 Elasticsearch: http://localhost:9200 (elastic/elastic)"

