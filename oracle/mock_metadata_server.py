# Copyright (c) 2026, Oracle and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

import http.server
import pathlib


METADATA_ROOT = pathlib.Path(__file__).parent / "metadata"
EXPECTED_AUTHORIZATION = "Bearer Oracle"


class OracleMetadataRequestHandler(http.server.BaseHTTPRequestHandler):

    def do_GET(self):
        if self.headers.get("Authorization") != EXPECTED_AUTHORIZATION:
            self.send_error(
                http.HTTPStatus.UNAUTHORIZED,
                "OCI IMDSv2 requires Authorization: Bearer Oracle",
            )
            return

        metadata_path = (METADATA_ROOT / self.path.lstrip("/")).resolve()
        if METADATA_ROOT.resolve() not in metadata_path.parents:
            self.send_error(http.HTTPStatus.NOT_FOUND)
            return
        try:
            metadata = metadata_path.read_bytes().rstrip(b"\r\n")
        except (FileNotFoundError, IsADirectoryError):
            self.send_error(http.HTTPStatus.NOT_FOUND)
            return

        self.send_response(http.HTTPStatus.OK)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(metadata)))
        self.end_headers()
        self.wfile.write(metadata)


if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer(
        ("127.0.0.1", 18080), OracleMetadataRequestHandler
    )
    server.serve_forever()
