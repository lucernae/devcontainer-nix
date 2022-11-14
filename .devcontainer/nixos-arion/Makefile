
config:
	@echo "# generated using arion, do not edit manually. Override using docker-compose.override.yml" > docker-compose.yml
	arion config >> docker-compose.yml

a-build:
	arion build

a-up:
	arion up

dc-up:
	docker-compose up

post-create-command:
	./arion-post-create-command.sh

retag-image:
	./arion-image-retag.sh