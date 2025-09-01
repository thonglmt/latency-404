local:
	docker-compose -f deploy/docker/docker-compose.local.yaml up -d --pull always

stop-local:
	docker-compose -f deploy/docker/docker-compose.local.yaml down

clean-local:
	docker-compose -f deploy/docker/docker-compose.local.yaml down --volumes

.PHONY: local stop-local clean-local
