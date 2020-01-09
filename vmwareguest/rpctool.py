import argparse
import base64
import json
import gzip

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", default="info-get guestinfo.metadata",
                        help="VMware key and namespace to retrieve")
    args = parser.parse_args()

    if args.command == "info-get guestinfo.metadata":
        data = json.dumps({
            "local-hostname": "dummy-hostname",
            "public-keys": "test key",
            "admin-username": "dummy-user",
            "admin-password": "Passw0rd"
        })
        data = data.encode("utf-8")

    if args.command == "info-get guestinfo.userdata":
        data = gzip.compress(b'#ps1\nmkdir C:\\test')

    str_out = base64.b64encode(data)
    print(str_out.decode(), end='')


if __name__ == "__main__":
    main()
