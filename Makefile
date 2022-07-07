
build:
	@docker-compose build

up:
	@docker-compose up -d

exec:
	@docker-compose exec devcontainer bash

down:
	@docker-compose down