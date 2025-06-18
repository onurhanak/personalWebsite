#!/usr/bin/env python3

import json
import sys

with open("terraform_outputs.json") as f:
    data = json.load(f)

ip = data["instance_public_ip"]["value"]

inventory = {
    "webserver": {
        "hosts": [ip],
        "vars": {
            "ansible_user": "ec2-user",
            "ansible_ssh_private_key_file": "~/.ssh/id_rsa"
        }
    }
}

print(json.dumps(inventory))
