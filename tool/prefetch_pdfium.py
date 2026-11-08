"""Cache the pinned PDFium Android assets for pdfium_dart 0.2.5 in CI.

The package's native hook downloads from a GitHub release URL without retries.
That URL has timed out on hosted runners. Use the authenticated GitHub asset
API and check each downloaded archive before use.
"""

import hashlib
import io
import os
from pathlib import Path
import tarfile
import time
import urllib.error
import urllib.request


ASSETS = {
    "android-arm": (
        406428654,
        "bb9250eefb33343f56f27f7e60c81ab3236d932c40e21557bf02ca4c276eb832",
    ),
    "android-arm64": (
        406428652,
        "f51539cadeb5135534305b8bdf8685ce2fbe9991dbbc5b35f553108411b9ed14",
    ),
    "android-x64": (
        406428649,
        "23faaf6f993a39524d9dc7fafbb760e295f8bd5e9ffa46139bad2299fb5c80f3",
    ),
}
OUTPUT = Path(".dart_tool/hooks_runner/shared/pdfium_dart/build/chromium_7811")


def download(asset_id: int, token: str) -> bytes:
    url = (
        "https://api.github.com/repos/bblanchon/pdfium-binaries/"
        f"releases/assets/{asset_id}"
    )
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/octet-stream",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except (urllib.error.URLError, TimeoutError):
            if attempt == 2:
                raise
            time.sleep(2**attempt)
    raise AssertionError("unreachable")


def main() -> None:
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        raise SystemExit("GITHUB_TOKEN is required to fetch pinned PDFium assets")
    lock = Path("pubspec.lock").read_text()
    if 'pdfium_dart:\n' not in lock or 'version: "0.2.5"' not in lock:
        raise SystemExit("Review PDFium asset pins after updating pdfium_dart")

    for platform, (asset_id, expected_sha256) in ASSETS.items():
        output = OUTPUT / platform / "libpdfium.so"
        if output.is_file():
            continue
        archive = download(asset_id, token)
        if hashlib.sha256(archive).hexdigest() != expected_sha256:
            raise SystemExit(f"PDFium archive checksum mismatch: {platform}")
        with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as tar:
            member = tar.extractfile("lib/libpdfium.so")
            if member is None:
                raise SystemExit(f"PDFium archive lacks libpdfium.so: {platform}")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(member.read())
        print(f"Cached pinned PDFium asset for {platform}")


if __name__ == "__main__":
    main()
