"""Fetch the pinned official Godot toolchain into this workspace, verifying SHA-256.

Uses Python's TLS stack instead of Windows Schannel. No global installation or PATH
changes. Only Windows x86_64 templates are extracted from the verified template pack.
"""

from __future__ import annotations

import concurrent.futures
import hashlib
import json
import pathlib
import shutil
import urllib.parse
import urllib.request
import zipfile

VERSION = "4.7.2"
ROOT = pathlib.Path(__file__).resolve().parents[1]
TOOLS = ROOT / ".tools"
CACHE = TOOLS / "downloads"
ENGINE = TOOLS / "godot" / VERSION
TEMPLATES = ENGINE / "editor_data" / "export_templates" / f"{VERSION}.stable"
HEADERS = {"User-Agent": "MinecraftRemix-M0-toolchain"}


def sha256(path: pathlib.Path) -> str:
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def fetch_verified(name: str, url: str, expected_hash: str, expected_size: int) -> pathlib.Path:
    destination = CACHE / name
    if destination.exists() and sha256(destination) == expected_hash:
        print(f"Verified cache: {name}", flush=True)
        return destination
    temporary = destination.with_suffix(destination.suffix + ".part")
    offset = temporary.stat().st_size if temporary.exists() else 0
    if offset > expected_size:
        raise RuntimeError(f"Oversized partial download: {temporary}")
    # Bounded ranges avoid large transfers being truncated by intermediary proxies.
    while offset < expected_size:
        end = min(offset + 128 * 1024 * 1024 - 1, expected_size - 1)
        request = urllib.request.Request(url, headers={**HEADERS, "Range": f"bytes={offset}-{end}"})
        with urllib.request.urlopen(request, timeout=60) as response:
            content_range = response.headers.get("Content-Range", "")
            if response.status != 206 or content_range != f"bytes {offset}-{end}/{expected_size}":
                raise RuntimeError(f"Unexpected range response: {response.status} {content_range}")
            remaining = end - offset + 1
            with temporary.open("ab") as output:
                while remaining:
                    chunk = response.read(min(4 * 1024 * 1024, remaining))
                    if not chunk:
                        raise RuntimeError(f"Truncated range for {name}; rerun to resume")
                    output.write(chunk)
                    offset += len(chunk)
                    remaining -= len(chunk)
        print(f"{name}: {offset // (1024 * 1024)} / {expected_size // (1024 * 1024)} MiB", flush=True)
    actual_hash = sha256(temporary)
    if actual_hash != expected_hash:
        raise RuntimeError(f"SHA-256 mismatch for {name}; actual={actual_hash}; file will not be executed")
    temporary.replace(destination)
    print(f"SHA-256 verified: {name}", flush=True)
    return destination


def main() -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    ENGINE.mkdir(parents=True, exist_ok=True)
    TEMPLATES.mkdir(parents=True, exist_ok=True)
    # Pin the digest returned by the official release API; repeated installs need
    # no API calls and remain reproducible even when GitHub's shared rate limit is hit.
    pinned = json.loads((ROOT / "tools" / "godot_manifest.json").read_text(encoding="utf-8"))
    if pinned["version"] != VERSION:
        raise RuntimeError("Toolchain version does not match pinned manifest")
    jobs = []
    manifest = {"version": VERSION, "release_url": pinned["release_url"], "assets": []}
    for asset in pinned["assets"]:
        name, slug, platform = asset["name"], asset["slug"], asset["platform"]
        digest = asset["sha256"]
        if len(digest) != 64:
            raise RuntimeError(f"Invalid pinned SHA-256: {name}")
        url = "https://downloads.godotengine.org/?" + urllib.parse.urlencode(
            {"version": VERSION, "flavor": "stable", "slug": slug, "platform": platform}
        )
        jobs.append((name, url, digest, asset["size"]))
        manifest["assets"].append({"name": name, "url": url, "sha256": digest, "size": asset["size"]})
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        downloaded = list(executor.map(lambda args: fetch_verified(*args), jobs))
    with zipfile.ZipFile(downloaded[0]) as archive:
        for name in (f"Godot_v{VERSION}-stable_win64.exe", f"Godot_v{VERSION}-stable_win64_console.exe"):
            with archive.open(name) as source, (ENGINE / name).open("wb") as target:
                shutil.copyfileobj(source, target)
    (ENGINE / "_sc_").touch()
    with zipfile.ZipFile(downloaded[1]) as archive:
        for name in ("version.txt", "windows_debug_x86_64.exe", "windows_release_x86_64.exe"):
            with archive.open(f"templates/{name}") as source, (TEMPLATES / name).open("wb") as target:
                shutil.copyfileobj(source, target)
    manifest["installed_files"] = [
        {"path": str(path.relative_to(ROOT)), "sha256": sha256(path)}
        for path in [*ENGINE.glob("*.exe"), *TEMPLATES.glob("*.exe")]
    ]
    (TOOLS / "toolchain_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Editor: {ENGINE}", flush=True)
    print(f"Templates: {TEMPLATES}", flush=True)


if __name__ == "__main__":
    main()
