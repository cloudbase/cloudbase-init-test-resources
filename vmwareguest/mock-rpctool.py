import argparse
import base64
import gzip
import json

USERDATA = b"""#cloud-config
groups:
    -
        windows:
            - Admin
    - cloud-users

users:
    -
        name: cloud-config-user
        gecos: 'Created by cloudbase-init'
        primary_group: cloud-users
        groups: windows

write_files:
    -
        encoding: b64
        content: CiMgVGhpcyBmaWxlIGNvbnRyb2xzIHRoZSBzdGF0ZSBvZiBTRUxpbnV4
        path: 'C:\\test_file'
        permissions: '0644'
    -
        content: "# Example ps1 file\\necho 'test'\\n"
        path: 'C:\\test_append.ps1'
        permissions: '0644'
    -
        content: "added to file\n"
        path: 'C:\\test_append.ps1'
        permissions: '0644'
        append: true
runcmd:
    -
        - dir
        - 'c:\\'
    - 'mkdir c:\\runcmd'
ntp:
    enabled: true
    pools:
        - 1.pool.ntp.org
    servers:
        - 0.pool.ntp.org
"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", default="info-get guestinfo.metadata",
                        help="VMware key and namespace to retrieve")
    args = parser.parse_args()
    encode_b64 = False
    if args.command == "info-get guestinfo.metadata":
        data = json.dumps({
            "instance-id": "b9517879-4e93-4a1a-9073-4ae0ddfac27c",
            "local-hostname": "v4.novalocal",
            "public-keys-data": "test key",
            "admin-username": "Admin",
            "admin-password": "Passw0rd",
            "network": {
              "version": 1,
              "config": [{
                "mac_address": "REPLACE_MAC_ADDRESS",
                "name": "cbs_init_eth0",
                "type": "physical",
                "subnets": [
                    {
                      "address": "10.196.59.2/24",
                      "dns_nameservers": [
                        "1.1.1.1",
                        "8.8.8.8"
                      ],
                      "gateway": "10.196.59.1",
                      "type": "static"
                    }
                 ]
              }]
            }
        })
        data = data.encode("utf-8")
        encode_b64 = True

    if args.command == "info-get guestinfo.userdata":
        data = gzip.compress(USERDATA)
        encode_b64 = True

    if args.command == "info-get guestinfo.userdata.encoding":
        data = 'gz+b64'
    if args.command == "info-get guestinfo.metadata.encoding":
        data = 'b64'

    if encode_b64:
        data = base64.b64encode(data).decode()

    print(data, end='')


if __name__ == "__main__":
    main()
