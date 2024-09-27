ENV?=rpi
ANSIBLE_ROLES_PATH=$(shell pwd)/ansible/roles

ansible/roles/marinepi-provisioning:
	ansible-galaxy install -r ansible/requirements.yml -p ansible/roles

deploy: ansible/roles/marinepi-provisioning
	ANSIBLE_ROLES_PATH=$(ANSIBLE_ROLES_PATH) ansible-playbook -i ansible/hosts -l $(ENV) ansible/playbooks/rpi.yml

.PHONY: deploy
