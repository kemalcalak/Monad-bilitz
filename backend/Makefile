.PHONY: help up down logs build migrate seed test clean

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start all services with Docker Compose
	docker-compose up -d

down: ## Stop all services
	docker-compose down

logs: ## View backend logs
	docker-compose logs -f backend

build: ## Rebuild backend service
	docker-compose up --build backend

migrate: ## Run database migrations
	docker-compose exec backend alembic upgrade head

seed: ## Seed demo data
	docker-compose exec backend python scripts/seed_demo_data.py

test: ## Run tests
	docker-compose exec backend pytest tests/ -v

test-cov: ## Run tests with coverage
	docker-compose exec backend pytest tests/ --cov=app --cov-report=html

clean: ## Remove containers and volumes
	docker-compose down -v

shell: ## Open shell in backend container
	docker-compose exec backend /bin/bash

db-shell: ## Open PostgreSQL shell
	docker-compose exec postgres psql -U postgres -d signature_db

redis-cli: ## Open Redis CLI
	docker-compose exec redis redis-cli

generate-key: ## Generate Fernet encryption key
	@python -c "from cryptography.fernet import Fernet; print('HKAS_ENCRYPTION_KEY=' + Fernet.generate_key().decode())"

dev: ## Start development server (without Docker)
	uvicorn app.main:socket_app --reload --host 0.0.0.0 --port 8000
