#!/usr/bin/env python3
"""Choose a unique release version, reusing an existing tag on reruns."""
import json
from pathlib import Path
import re
import subprocess


def parse(value):
    match = re.fullmatch(r"v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", value)
    return tuple(map(int, match.groups())) if match else None


def select(base, tags, head_tags):
    base_version = parse(base)
    if base_version is None:
        raise ValueError("Invalid package version")
    existing = [parse(tag) for tag in head_tags if parse(tag)]
    if existing:
        return ".".join(map(str, max(existing)))
    versions = [parse(tag) for tag in tags if parse(tag)]
    if versions:
        major, minor, patch = max(versions)
        base_version = max(base_version, (major, minor, patch + 1))
    return ".".join(map(str, base_version))


def main():
    root = Path(__file__).resolve().parents[1]
    base = json.loads((root / "package/metadata.json").read_text())["KPlugin"]["Version"]
    tags = subprocess.check_output(["git", "tag", "--list", "v*"], cwd=root, text=True).splitlines()
    head_tags = subprocess.check_output(["git", "tag", "--points-at", "HEAD", "--list", "v*"], cwd=root, text=True).splitlines()
    print(select(base, tags, head_tags))


if __name__ == "__main__":
    main()
