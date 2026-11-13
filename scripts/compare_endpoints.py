import os
import re
import sys

# Add backend to sys.path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend"))
sys.path.insert(0, backend_dir)

from app.main import create_application

app = create_application()
openapi_paths = set(app.openapi()["paths"].keys())
# Normalize openapi paths: replace {var} with wildcard or regex
print(f"Loaded {len(openapi_paths)} OpenAPI paths from backend.")

# Search flutter repositories for dioClient calls: get, post, put, patch, delete
flutter_repo_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "lib"))

endpoint_pattern = re.compile(r"""(?:get|post|put|patch|delete)\(\s*['"]([^'"]+)['"]""")

flutter_endpoints = set()
for root, _, files in os.walk(flutter_repo_dir):
    for f in files:
        if f.endswith(".dart"):
            path = os.path.join(root, f)
            with open(path, "r", encoding="utf-8", errors="ignore") as fp:
                content = fp.read()
                matches = endpoint_pattern.findall(content)
                for m in matches:
                    if m.startswith("/") or m.startswith("http"):
                        flutter_endpoints.add((f, m))

print(f"\nFound {len(flutter_endpoints)} unique endpoint calls in Flutter:")
mismatches = []
for file, ep in sorted(flutter_endpoints):
    # Strip query params
    ep_clean = ep.split("?")[0]
    # Check if direct match in openapi or with /api/v1 prefix or /v1 prefix
    candidates = [ep_clean, f"/api/v1{ep_clean}", f"/v1{ep_clean}"]
    
    # Check template matching like /loads/{id}
    matched = False
    for c in candidates:
        for oa in openapi_paths:
            # simple regex convert {id} to [^/]+
            oa_regex = "^" + re.sub(r"\{[^}]+\}", r"[^/]+", oa) + "$"
            if re.match(oa_regex, c):
                matched = True
                break
        if matched:
            break
            
    status = "OK" if matched else "MISMATCH"
    print(f"[{status:8s}] {file:35s} -> {ep}")
    if not matched and not ep.startswith("http"):
        mismatches.append((file, ep))

print(f"\nTotal Mismatches to fix: {len(mismatches)}")
for file, ep in mismatches:
    print(f" - {file}: {ep}")
