#!/usr/bin/env python3
"""Check SwiftPM pins in Package.resolved against OSV's SwiftURL ecosystem."""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from pathlib import Path


OSV_QUERY_URL = "https://api.osv.dev/v1/query"


def package_names(location: str) -> list[str]:
    names = [location]
    if location.endswith(".git"):
        names.append(location[:-4])
    return names


def query_osv(name: str, version: str) -> list[dict[str, object]]:
    payload = {
        "version": version,
        "package": {
            "ecosystem": "SwiftURL",
            "name": name,
        },
    }
    request = urllib.request.Request(
        OSV_QUERY_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        body = json.loads(response.read().decode("utf-8"))
    return body.get("vulns", [])


def main() -> int:
    lockfile = Path("Package.resolved")
    if not lockfile.exists():
        print("Package.resolved not found", file=sys.stderr)
        return 2

    pins = json.loads(lockfile.read_text(encoding="utf-8")).get("pins", [])
    vulnerable: list[tuple[str, str, list[dict[str, object]]]] = []

    for pin in pins:
        state = pin.get("state", {})
        version = state.get("version")
        location = pin.get("location")
        kind = pin.get("kind")
        if kind != "remoteSourceControl" or not location or not version:
            continue

        vulns: list[dict[str, object]] = []
        for name in package_names(location):
            try:
                vulns.extend(query_osv(name, version))
            except urllib.error.URLError as error:
                print(f"OSV query failed for {location}@{version}: {error}", file=sys.stderr)
                return 2
        if vulns:
            vulnerable.append((location, version, vulns))

    if vulnerable:
        for location, version, vulns in vulnerable:
            ids = ", ".join(str(vuln.get("id", "unknown")) for vuln in vulns)
            print(f"{location}@{version}: {ids}", file=sys.stderr)
        return 1

    print("No OSV vulnerabilities found for SwiftPM remote pins.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
