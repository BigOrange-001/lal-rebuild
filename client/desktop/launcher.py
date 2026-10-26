"""Portable Windows host: private local gateway, durable saves and AIR client."""
from __future__ import annotations

import ctypes
import json
import msvcrt
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parent
HIDDEN = subprocess.CREATE_NO_WINDOW


def main():
    data = ROOT / "data"
    data.mkdir(exist_ok=True)
    logs = ROOT / "logs"
    logs.mkdir(exist_ok=True)
    lock = (data / "launcher.lock").open("a+b")
    lock.seek(0)
    if not lock.read(1):
        lock.write(b"0")
        lock.flush()
    lock.seek(0)
    try:
        msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
    except OSError:
        ctypes.windll.user32.MessageBoxW(None, "此目录的游戏已在运行。", "Mod 游戏端", 0)
        return 0
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        port = listener.getsockname()[1]
    version = (ROOT / "VERSION").read_text("utf-8").strip()
    (ROOT / "app/bootstrap.json").write_text(json.dumps({"port": port, "version": version}), "utf-8")
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with (logs / "gateway.log").open("ab") as output:
        server = subprocess.Popen(
            [str(ROOT / "runtime/python.exe"), "-B", "-X", "utf8", "-u", str(ROOT / "server/gateway.py"),
             "--host", "127.0.0.1", "--port", str(port), "--database", str(data / "local.sqlite3"),
             "--config", str(ROOT / "config/reconstruction/full-config.json"), "--mods-root", str(data / "mods")],
            cwd=ROOT, stdin=subprocess.PIPE, stdout=output, stderr=output, creationflags=HIDDEN,
        )
        try:
            deadline = time.monotonic() + 40
            while time.monotonic() < deadline:
                if server.poll() is not None:
                    raise RuntimeError("本地服务启动失败，请查看 logs/gateway.log。")
                try:
                    with opener.open(f"http://127.0.0.1:{port}/health", timeout=1) as response:
                        if json.load(response).get("status") == "ok":
                            break
                except (urllib.error.URLError, TimeoutError, OSError):
                    time.sleep(.15)
            else:
                raise RuntimeError("本地服务启动超时，请查看 logs/gateway.log。")
            with (logs / "client.log").open("ab") as client_log:
                client = subprocess.Popen(
                    [str(ROOT / "air/bin/adl64.exe"), "-runtime", str(ROOT / "air/runtimes/air/win64"),
                     "-nodebug", "-profile", "extendedDesktop", str(ROOT / "app/application.xml"), str(ROOT / "app")],
                    cwd=ROOT / "app", stdout=client_log, stderr=client_log, creationflags=HIDDEN,
                )
                code = client.wait()
                if code:
                    raise RuntimeError("游戏客户端退出异常，请查看 logs/client.log。")
        finally:
            if server.poll() is None:
                try:
                    server.stdin.write(b"exit\n")
                    server.stdin.flush()
                    server.wait(timeout=8)
                except (OSError, subprocess.TimeoutExpired):
                    server.terminate()
                    try:
                        server.wait(timeout=8)
                    except subprocess.TimeoutExpired:
                        server.kill()
                        server.wait(timeout=8)
            if server.stdin is not None:
                server.stdin.close()
    lock.close()
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        ctypes.windll.user32.MessageBoxW(None, str(error), "Mod 游戏端启动失败", 0x10)
        raise SystemExit(1)
