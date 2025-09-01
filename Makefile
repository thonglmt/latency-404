local:
	docker-compose -f deploy/docker/docker-compose.local.yaml up -d --pull always

stop-local:
	docker-compose -f deploy/docker/docker-compose.local.yaml down

clean-local:
	docker-compose -f deploy/docker/docker-compose.local.yaml down --volumes

infracost:
	infracost breakdown --path deploy/infra/aws

.PHONY: local stop-local clean-local infracost
