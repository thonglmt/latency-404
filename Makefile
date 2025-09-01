local:
	docker-compose -f deploy/docker/docker-compose.local.yaml up -d --build

stop-local:
	docker-compose -f deploy/docker/docker-compose.local.yaml down

clean-local:
	docker-compose -f deploy/docker/docker-compose.local.yaml down --volumes

monitoring:
	docker-compose -f deploy/docker/docker-compose.monitoring.yaml up -d --build

stop-monitoring:
	docker-compose -f deploy/docker/docker-compose.monitoring.yaml down

clean-monitoring:
	docker-compose -f deploy/docker/docker-compose.monitoring.yaml down --volumes

infracost:
	infracost breakdown --path deploy/infra/aws

.PHONY: local stop-local clean-local infracost monitoring stop-monitoring clean-monitoring
