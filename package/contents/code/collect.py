#!/usr/bin/env python3
"""Optional activity snapshots. Standard library only; no daemon or root access."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
from urllib.request import ProxyHandler, Request, build_opener


def command(args, timeout=0.7):
    try:
        return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL, timeout=timeout).strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def fetch(port, path):
    try:
        # Local APIs must never be sent through a configured HTTP proxy.
        with build_opener(ProxyHandler({})).open(Request(f"http://127.0.0.1:{port}{path}"), timeout=0.35) as response:
            return json.loads(response.read(1024 * 1024))
    except (OSError, ValueError):
        return {}


def cpu_percent(previous, current):
    if not previous or len(previous) != len(current) or len(current) < 5:
        return None
    total = sum(current) - sum(previous)
    idle = current[3] + current[4] - previous[3] - previous[4]
    return round(max(0, min(100, 100 * (1 - idle / total))), 1) if total > 0 else None


def intel_gpu_snapshot():
    if not shutil.which("intel_gpu_top"):
        return []
    process = subprocess.Popen(["intel_gpu_top", "-J", "-s", "100", "-o", "-"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    try:
        raw, _ = process.communicate(timeout=0.4)
    except subprocess.TimeoutExpired:
        process.terminate()
        try:
            raw, _ = process.communicate(timeout=0.2)
        except subprocess.TimeoutExpired:
            process.kill()
            raw, _ = process.communicate()
    text = raw.decode(errors="replace")
    samples = []
    decoder = json.JSONDecoder()
    for i, character in enumerate(text):
        if character != "{":
            continue
        try:
            sample, _ = decoder.raw_decode(text[i:])
            if isinstance(sample, dict) and isinstance(sample.get("engines"), dict):
                samples.append(sample)
        except ValueError:
            pass
    if not samples:
        return []
    busy = [float(engine["busy"]) for engine in samples[-1]["engines"].values() if isinstance(engine, dict) and "busy" in engine]
    # Busiest engine, not a sum across independent GPU engines.
    return [{"name": "Intel GPU", "util": round(max(busy), 1)}] if busy else []


def system_snapshot(previous):
    ticks = [int(n) for n in Path("/proc/stat").read_text().splitlines()[0].split()[1:9]]
    memory = {line.split(":")[0]: int(line.split()[1]) for line in Path("/proc/meminfo").read_text().splitlines() if len(line.split()) >= 2}
    gpus = []
    for card in Path("/sys/class/drm").glob("card[0-9]*"):
        if "-" in card.name:
            continue
        try:
            gpus.append({"name": card.name, "util": int((card / "device/gpu_busy_percent").read_text())})
        except (OSError, ValueError):
            pass
    if shutil.which("nvidia-smi"):
        for line in command(["nvidia-smi", "--query-gpu=name,utilization.gpu", "--format=csv,noheader,nounits"]).splitlines():
            try:
                name, util = line.rsplit(",", 1)
                gpus.append({"name": name.strip(), "util": float(util)})
            except ValueError:
                pass
    try:
        gpus.extend(intel_gpu_snapshot())
    except (OSError, ValueError):
        pass
    return {"cpu": cpu_percent(previous.get("cpu_ticks"), ticks),
            "ram": round(100 * (1 - memory["MemAvailable"] / memory["MemTotal"]), 1), "gpus": gpus}, ticks


def processes():
    result = []
    for proc in Path("/proc").glob("[0-9]*"):
        try:
            if proc.stat().st_uid not in {0, os.getuid()}:
                continue
            args = [s.decode(errors="replace") for s in (proc / "cmdline").read_bytes().split(b"\0") if s]
            if args:
                ppid = int((proc / "stat").read_text().rsplit(")", 1)[1].split()[1])
                result.append({"pid": int(proc.name), "ppid": ppid, "args": args})
        except (OSError, ValueError, IndexError):
            continue
    return result


def package_snapshot(procs):
    tools = {"pacman", "apt", "apt-get", "dpkg", "dnf", "dnf5", "yum", "zypper", "flatpak", "pip", "pip3", "npm"}
    operations = {"install", "uninstall", "remove", "upgrade", "update", "dist-upgrade", "full-upgrade", "reinstall", "autoremove"}
    for proc in procs:
        args = proc["args"]
        name = Path(args[0]).name
        if name.startswith("python") and len(args) > 3 and args[1:3] in (["-m", "pip"], ["-m", "pip3"]):
            name, args = "pip", ["pip"] + args[3:]
        elif name.startswith("python") and len(args) > 2 and Path(args[1]).name in {"pip", "pip3"}:
            name, args = "pip", ["pip"] + args[2:]
        elif name.startswith("npm "):
            import shlex
            args = shlex.split(name) + args[1:]
            name = "npm"
        if name not in tools:
            continue
        operation = next((s for s in args[1:] if s in operations), "")
        if name == "pacman":
            operation = "remove" if any(s.startswith("-") and "R" in s for s in args[1:]) else ("install" if any(s.startswith("-") and "S" in s for s in args[1:]) else "")
        if name == "dpkg" and any(s in {"-i", "--install", "--unpack", "--configure", "-r", "--remove", "-P", "--purge"} for s in args[1:]):
            operation = "remove" if any(s in {"-r", "--remove", "-P", "--purge"} for s in args[1:]) else "install"
        if operation:
            targets = [s for s in args[1:] if not s.startswith("-") and s not in operations]
            return {"active": True, "tool": name, "operation": operation,
                    "package": targets[-1] if targets else "", "pid": proc["pid"], "ppid": proc["ppid"]}
    return {"active": False}


def model_list(port, path, key):
    data = fetch(port, path)
    if not isinstance(data, dict):
        return []
    items = data.get(key, [])
    return [m for m in items if isinstance(m, dict)] if isinstance(items, list) else []


def llm_snapshot():
    loaded = [m for m in model_list(1234, "/api/v1/models", "models") if m.get("loaded_instances")]
    if loaded:
        model = loaded[0]
        instance = model["loaded_instances"][0]
        return {"active": True, "runner": "LM Studio", "model": model.get("display_name", model.get("key", "")),
                "context": instance.get("config", {}).get("context_length", 0)}
    loaded = [m for m in model_list(1234, "/api/v0/models", "data") if m.get("state") == "loaded"]
    if loaded:
        model = loaded[0]
        return {"active": True, "runner": "LM Studio", "model": model.get("id", ""),
                "context": model.get("loaded_context_length", model.get("max_context_length", 0))}
    models = model_list(11434, "/api/ps", "models")
    if models:
        model = models[0]
        return {"active": True, "runner": "Ollama", "model": model.get("name", model.get("model", "")),
                "context": model.get("context_length", 0), "memory": model.get("size", 0)}
    return {"active": False}


def generation_stats(slots, previous, now, identity):
    """Decode-token deltas only, never prompt throughput. Reset across tasks."""
    if not isinstance(slots, list):
        return {"phase": "unknown", "tokens_per_second": None}, {}
    active = [s for s in slots if isinstance(s, dict) and s.get("is_processing")]
    if not active:
        return {"phase": "idle", "tokens_per_second": None}, {}
    slot = active[0]
    decoded = int(slot.get("next_token", {}).get("n_decoded", slot.get("n_decoded", 0)))
    key = f"{identity}:{slot.get('id')}:{slot.get('id_task')}"
    current = {"key": key, "decoded": decoded, "time": now}
    rate = None
    elapsed = now - previous.get("time", now)
    if decoded > 0 and previous.get("key") == key and 0.2 < elapsed < 15 and decoded >= previous.get("decoded", decoded):
        rate = round((decoded - previous["decoded"]) / elapsed, 1)
    return {"phase": "generating" if decoded > 0 else "processing", "tokens_per_second": rate}, current


def inference_stats(procs, previous, now, runner):
    samples = {}
    rss = 0
    cpu = 0.0
    ports = []
    for proc in procs:
        args = proc["args"]
        name = Path(args[0]).name.lower()
        matched = ("llama-server" in name or "llama.cpp" in name) if runner == "LM Studio" else (name.startswith("ollama") and ("runner" in args or "llama" in name))
        if not matched:
            continue
        try:
            stat = (Path("/proc") / str(proc["pid"]) / "stat").read_text().rsplit(")", 1)[1].split()
            ticks = int(stat[11]) + int(stat[12])
            key = f"{proc['pid']}:{stat[19]}"
            samples[key] = ticks
            rss += int(stat[21]) * os.sysconf("SC_PAGE_SIZE")
            old = previous.get("process_ticks", {}).get(key)
            elapsed = now - previous.get("time", now)
            if old is not None and 0.2 < elapsed < 15 and ticks >= old:
                cpu += (ticks - old) / os.sysconf("SC_CLK_TCK") / elapsed * 100
            for i, arg in enumerate(args):
                if arg == "--port" and i + 1 < len(args) and args[i + 1].isdigit():
                    ports.append(int(args[i + 1]))
                elif arg.startswith("--port=") and arg[7:].isdigit():
                    ports.append(int(arg[7:]))
        except (OSError, ValueError, IndexError):
            continue
    result = {"cpu": round(cpu, 1) if previous.get("time") and samples else None,
              "process_memory": rss or None, "phase": "unknown", "tokens_per_second": None}
    slot_state = {}
    if runner == "LM Studio":
        # Inspect only an explicitly advertised local inference port. Authenticated
        # or unavailable /slots endpoints simply leave generation speed unknown.
        for port in ports[:4]:
            if not 0 < port < 65536:
                continue
            slots = fetch(port, "/slots")
            if isinstance(slots, list):
                generation, slot_state = generation_stats(slots, previous.get("slot", {}), now, str(port))
                result.update(generation)
                break
    return result, {"time": now, "process_ticks": samples, "slot": slot_state}


def audio_snapshot():
    if not shutil.which("pactl"):
        return ""
    try:
        name = command(["pactl", "get-default-sink"])
        sinks = json.loads(command(["pactl", "-f", "json", "list", "sinks"]) or "[]")
        return next((s.get("description", "") for s in sinks if s.get("name") == name), "")
    except (ValueError, TypeError):
        return ""


def activate(kind):
    procs = processes()
    if kind == "packages":
        package = package_snapshot(procs)
        pid = package.get("pid", 0)
        by_pid = {p["pid"]: p for p in procs}
        ancestors = []
        while pid in by_pid and pid not in ancestors:
            ancestors.append(pid)
            pid = by_pid[pid]["ppid"]
        if shutil.which("kdotool"):
            for pid in ancestors:
                windows = command(["kdotool", "search", "--pid", str(pid)]).splitlines()
                if windows:
                    command(["kdotool", "windowactivate", windows[0]])
                    return
        return
    if kind == "system":
        choices = [["plasma-systemmonitor"], ["konsole", "-e", "top"]]
    elif llm_snapshot().get("runner") == "Ollama":
        choices = [["konsole", "-e", "ollama", "ps"]]
    else:
        choices = [["lmstudio"], ["lm-studio"], ["gtk-launch", "lm-studio"]]
    for args in choices:
        if shutil.which(args[0]) and ("ollama" not in args or shutil.which("ollama")):
            subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            return


def snapshot(features, previous):
    result = {"timestamp": time.time()}
    state = {}
    if "system" in features:
        try:
            result["system"], state["cpu_ticks"] = system_snapshot(previous)
        except (OSError, ValueError, KeyError):
            result["system"] = {}
    procs = processes() if {"packages", "llm"} & features else []
    if "packages" in features:
        result["packages"] = package_snapshot(procs)
    if "llm" in features:
        result["llm"] = llm_snapshot()
        if result["llm"].get("active"):
            stats, state["inference"] = inference_stats(procs, previous.get("inference", {}), result["timestamp"], result["llm"]["runner"])
            result["llm"].update(stats)
    if "audio" in features:
        result["audio"] = audio_snapshot()
    return result, state


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--features", default="system,packages,llm,audio")
    parser.add_argument("--open", choices=["system", "packages", "llm"])
    args = parser.parse_args()
    if args.open:
        activate(args.open)
        return
    # Keep only numeric counters and task IDs, never prompts or process command lines.
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR") or os.environ.get("XDG_CACHE_HOME") or str(Path.home() / ".cache")) / "boring-island"
    runtime.mkdir(mode=0o700, parents=True, exist_ok=True)
    if runtime.stat().st_uid != os.getuid() or runtime.is_symlink():
        raise OSError("Invalid runtime directory")
    state_path = runtime / "counters.json"
    try:
        previous = json.loads(state_path.read_text())
    except (OSError, ValueError):
        previous = {}
    result, state = snapshot(set(args.features.split(",")), previous)
    # Atomic replacement; concurrent widget instances may share this sample.
    import tempfile
    with tempfile.NamedTemporaryFile(mode="w", dir=runtime, delete=False) as stream:
        json.dump(state, stream)
        temporary = stream.name
    os.replace(temporary, state_path)
    print(json.dumps(result))


if __name__ == "__main__":
    main()
