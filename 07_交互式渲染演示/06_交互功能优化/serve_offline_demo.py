# -*- coding: utf-8 -*-
"""Serve the offline Interactive demo on http://127.0.0.1:8766/"""
from __future__ import annotations

import argparse
import functools
import http.server
import importlib.util
import json
import socketserver
import webbrowser
from pathlib import Path

OPT = Path(__file__).resolve().parent
DEMO = OPT.parent
PROJECT = DEMO.parent


def build_manifest() -> str:
    spec = importlib.util.spec_from_file_location(
        "_build_offline_manifest", OPT / "_build_offline_manifest.py"
    )
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    mod.main()
    m = json.loads((PROJECT / "offline_manifest.json").read_text(encoding="utf-8"))
    return m.get("page") or f"{OPT.relative_to(PROJECT).as_posix()}/offline_orbit_viewer.html"


def main() -> None:
    parser = argparse.ArgumentParser(description="LagerNVS offline Interactive demo server")
    parser.add_argument("--port", type=int, default=8766)
    parser.add_argument("--no-open", action="store_true")
    args = parser.parse_args()

    page = build_manifest()
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(PROJECT))
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(("127.0.0.1", args.port), handler) as httpd:
        httpd.daemon_threads = True
        url = f"http://127.0.0.1:{args.port}/"
        print(f"Serving {PROJECT}", flush=True)
        print(f"Open: {url}", flush=True)
        print(f"Direct: http://127.0.0.1:{args.port}/{page}", flush=True)
        print("HQ stills first (sharp GT|Pred). Orbit explore: drag to scrub.", flush=True)
        if not args.no_open:
            webbrowser.open(url)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nstopped", flush=True)


if __name__ == "__main__":
    main()
