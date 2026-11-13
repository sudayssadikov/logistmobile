import sys
import os

sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))
from app.api.v1.router import api_v1_router

def print_router_routes(router, prefix=""):
    for route in router.routes:
        if hasattr(route, "routes"):
            print_router_routes(route, prefix + getattr(route, "prefix", ""))
        else:
            methods = getattr(route, "methods", ["WS"])
            path = prefix + getattr(route, "path", str(route))
            name = getattr(route, "name", "")
            print(f"{','.join(methods):18s} /api/v1{path:40s} ({name})")

print_router_routes(api_v1_router)
