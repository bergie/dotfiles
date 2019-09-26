ENV?=rpi
ANSIBLE_ROLES_PATH=$(shell pwd)/roles

roles/marinepi-provisioning:
	ansible-galaxy install -r requirements.yml -p roles

deploy: roles/marinepi-provisioning
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i hosts -l $(ENV) playbooks/rpi.yml

.PHONY: deploy
