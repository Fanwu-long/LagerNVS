# -*- coding: utf-8 -*-
"""Stable Offline Interactive launcher.

Keeps http://127.0.0.1:8766/ alive. Optionally restarts a Cloudflare quick
tunnel when it dies (URL still changes — localhost is the durable link).
"""
from __future__ import annotations

import argparse
import functools
import http.server
import importlib.util
import json
import os
import re
import socketserver
import subprocess
import sys
import threading
import time
import webbrowser
from pathlib import Path

OPT = Path(__file__).resolve().parent
DEMO = OPT.parent
PROJECT = DEMO.parent
STATUS = PROJECT / "DEMO_STATUS.txt"
URL_RE = re.compile(r"https://[a-z0-9-]+\.trycloudflare\.com")


def build_manifest() -> tuple[str, dict]:
    spec = importlib.util.spec_from_file_location(
        "_build_offline_manifest", OPT / "_build_offline_manifest.py"
    )
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    mod.main()
    m = json.loads((PROJECT / "offline_manifest.json").read_text(encoding="utf-8"))
    page = m.get("page") or f"{OPT.relative_to(PROJECT).as_posix()}/offline_orbit_viewer.html"
    return page, m


def find_cloudflared() -> Path | None:
    candidates = [
        Path(os.environ.get("USERPROFILE", "")) / "bin" / "cloudflared.exe",
        Path(os.environ.get("LOCALAPPDATA", "")) / "cloudflared" / "cloudflared.exe",
        Path("C:/Program Files/cloudflared/cloudflared.exe"),
    ]
    for p in candidates:
        if p.exists():
            return p
    from shutil import which

    w = which("cloudflared")
    return Path(w) if w else None


def write_status(local: str, page: str, stats: dict, public: str | None = None) -> None:
    lines = [
        "LagerNVS Offline Interactive — STATUS",
        f"updated: {time.strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "【稳定访问 — 请用这个】",
        f"  {local}",
        f"  {local.rstrip('/')}/{page}",
        "",
        f"样本: {stats.get('scenes', '?')} scenes | "
        f"{stats.get('hq_stills', '?')} HQ stills | "
        f"{stats.get('orbit_clips', '?')} orbit clips | "
        f"{stats.get('input_thumbs', '?')} input thumbs",
        "",
        "【公网临时隧道 — 会过期/换域名，仅临时分享】",
        f"  {public or '(未启用或尚未连上)'}",
        "",
        "Cloudflare trycloudflare 本身不稳定；本机 8766 才是常驻入口。",
        "Live GPU WebUI 请用 SSH 端口转发，不要依赖公网隧道。",
        "",
    ]
    STATUS.write_text("\n".join(lines), encoding="utf-8")
    print("\n".join(lines), flush=True)


def tunnel_watchdog(port: int, page: str, stats: dict, local: str) -> None:
    exe = find_cloudflared()
    if not exe:
        write_status(local, page, stats, None)
        print("cloudflared not found — local-only mode", flush=True)
        return
    public = None
    while True:
        write_status(local, page, stats, public)
        cmd = [str(exe), "tunnel", "--url", f"http://127.0.0.1:{port}"]
        print(f"[tunnel] starting: {' '.join(cmd)}", flush=True)
        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
        except OSError as e:
            print(f"[tunnel] failed to start: {e}", flush=True)
            time.sleep(8)
            continue
        assert proc.stdout is not None
        for line in proc.stdout:
            line = line.rstrip()
            if line:
                print(f"[tunnel] {line}", flush=True)
            m = URL_RE.search(line)
            if m:
                public = m.group(0) + "/"
                write_status(local, page, stats, public)
        code = proc.wait()
        public = None
        print(f"[tunnel] exited {code}; restart in 5s", flush=True)
        time.sleep(5)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8766)
    parser.add_argument("--no-open", action="store_true")
    parser.add_argument("--tunnel", action="store_true", help="optional Cloudflare watchdog")
    args = parser.parse_args()

    page, manifest = build_manifest()
    stats = manifest.get("stats") or {}
    local = f"http://127.0.0.1:{args.port}/"
    write_status(local, page, stats, None)

    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(PROJECT))
    socketserver.TCPServer.allow_reuse_address = True

    if args.tunnel:
        t = threading.Thread(
            target=tunnel_watchdog,
            args=(args.port, page, stats, local),
            daemon=True,
        )
        t.start()

    with socketserver.ThreadingTCPServer(("127.0.0.1", args.port), handler) as httpd:
        httpd.daemon_threads = True
        print(f"Serving {PROJECT} on {local}", flush=True)
        if not args.no_open:
            webbrowser.open(local)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nstopped", flush=True)


if __name__ == "__main__":
    main()
