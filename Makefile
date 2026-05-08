PORT ?= 8000
IMAGE := statuspulse:local

.PHONY: build up down logs test clean shell

build:
	docker build -t $(IMAGE) .

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f --tail=100

test:
	@echo "Waiting for app to be healthy..."
	@for i in $$(seq 1 30); do \
	  curl -fsS http://localhost:$(PORT)/health && echo "OK" && exit 0; \
	  sleep 2; \
	done; \
	echo "Health check failed" && exit 1

clean:
	docker compose down -v --rmi local --remove-orphans

shell:
	docker compose exec app /bin/bash || docker compose exec app /bin/sh