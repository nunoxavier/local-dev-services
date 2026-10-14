.DEFAULT_GOAL := help
.PHONY: help up down restart ps logs psql redis-cli reset

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

up: ## Start all services and wait until they are healthy
	docker compose up -d --wait

down: ## Stop all services (data is kept)
	docker compose down

restart: down up ## Restart all services

ps: ## Show service status
	docker compose ps

logs: ## Follow logs (one service: make logs s=postgres)
	docker compose logs -f $(s)

psql: ## Open a psql shell
	docker compose exec postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

redis-cli: ## Open a redis-cli shell
	docker compose exec redis redis-cli

reset: ## Stop all services and DELETE all data
	docker compose down -v
