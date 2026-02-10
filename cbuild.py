#!/usr/bin/env python3
"""
Lightweight cross-platform replacement for `cbuild.sh`.
- Supports configure/build and run targets with `--` arg forwarding.
- Behavior parity with existing `cbuild.sh`:
  * `run_<target>` without extra args -> `cmake --build . --target run_<target>` (use CMake-configured defaults)
  * `run_<target> -- a b` -> build `<target>` then execute it with provided args (overrides defaults)

Usage examples:
  ./scripts/cbuild.py            # configure+build (Release)
  ./scripts/cbuild.py -d         # configure+build (Debug)
  ./scripts/cbuild.py r          # recreate build dir then build
  ./scripts/cbuild.py r i        # recreate build dir, build then install
  ./scripts/cbuild.py run_inspector_svr
  ./scripts/cbuild.py run_inspector_svr -- foo bar

"""
from __future__ import annotations
import argparse
import os
import platform
import shutil
import stat
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Tuple

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_JOBS = os.cpu_count() or 1


def run(cmd: List[str], check=True, **kwargs) -> subprocess.CompletedProcess:
    print("+", " ".join(cmd))
    return subprocess.run(cmd, check=check, **kwargs)


def ensure_build_dir(build_dir: Path, recreate: bool, config: str) -> None:
    if recreate and build_dir.exists():
        print(f"Removing {build_dir}")
        shutil.rmtree(build_dir)
    build_dir.mkdir(parents=True, exist_ok=True)
    # run cmake configure if no cache
    cache = build_dir / "CMakeCache.txt"
    if not cache.exists() or recreate:
        # Configure while being inside the build dir so any tools that use
        # current working directory won't write into the source tree.
        cmake_cmd = ["cmake", "-S", str(ROOT), "-B", ".", f"-DCMAKE_BUILD_TYPE={config}"]
        run(cmake_cmd, cwd=str(build_dir))


def cmake_build(build_dir: Path, target: Optional[str], jobs: int, verbose: bool = False) -> None:
    # Run the build while in the build directory to keep all generated files there
    cmd = ["cmake", "--build", "."]
    if target:
        cmd += ["--target", target]
    if verbose:
        cmd += ["-v"]
    cmd += ["--", f"-j{jobs}"]
    run(cmd, cwd=str(build_dir.resolve()))


def find_executable(build_dir: Path, name: str) -> Optional[Path]:
    # On Windows prefer name.exe
    exts = [".exe", ""] if platform.system() == "Windows" else [""]
    for root, dirs, files in os.walk(build_dir):
        for f in files:
            for ext in exts:
                if f == name + ext:
                    p = Path(root) / f
                    # quick executable check: on unix, check execute bit
                    try:
                        mode = p.stat().st_mode
                        if platform.system() == "Windows" or (mode & stat.S_IXUSR):
                            return p
                    except Exception:
                        return p
    return None


def install(build_dir: Path) -> None:
    print("install target...")
    run(["sudo", "cmake", "--install", "."], cwd=str(build_dir))


def parse_legacy_args(argv: List[str]) -> Tuple[List[str], Optional[bool], Optional[bool], Optional[bool], Optional[bool]]:
    """Parse legacy positional arguments from cbuild.sh style."""
    legacy_args = list(argv)
    legacy_build_flag: Optional[bool] = None  # True => debug, False => release
    legacy_recreate: Optional[bool] = None
    legacy_install: Optional[bool] = None
    legacy_verbose: Optional[bool] = None
    
    # Check if first arg is 'd' or 'r' (single char) and not starting with '-'
    if (len(legacy_args) >= 1 and not legacy_args[0].startswith("-") and
        len(legacy_args[0]) == 1 and legacy_args[0] in ("d", "r")):
        
        # interpret first positional
        legacy_build_flag = legacy_args[0] == "d"
        legacy_args = legacy_args[1:]
        
        # Check subsequent args for 'r' (recreate), 'i' (install), 'v' (verbose)
        # Note: logic loops here to handle order like 'r i' or 'i r' if we wanted, 
        # but cbuild.sh usually expects specific order. 
        # Based on cbuild.sh: $2 is checked for 'r' (if $1 was d/r?), actually cbuild.sh is messy.
        # Let's support: [d|r] [r] [i] [v] in sequence roughly
        
        if legacy_args and legacy_args[0] == "r":
            legacy_recreate = True
            legacy_args = legacy_args[1:]
            
        if legacy_args and legacy_args[0] == "i":
            legacy_install = True
            legacy_args = legacy_args[1:]
            
        if legacy_args and legacy_args[0] == "v":
            legacy_verbose = True
            legacy_args = legacy_args[1:]
            
    return legacy_args, legacy_build_flag, legacy_recreate, legacy_install, legacy_verbose


def parse_command_and_args(command: List[str]) -> Tuple[List[str], List[str]]:
    """Parse command and user args separated by '--'."""
    if not command:
        return [], []
    if "--" in command:
        idx = command.index("--")
        return command[:idx], command[idx+1:]
    return command, []


def handle_run_command(build_dir_abs: Path, exe_target: str, run_target: str,
                       user_args: List[str], jobs: int, verbose: bool) -> int:
    """Handle run_<target> or run <target> commands."""
    if not user_args:
        print(f"execute target {run_target} (CMake-configured run)")
        cmake_build(build_dir_abs, target=run_target, jobs=jobs, verbose=verbose)
        return 0
    else:
        print(f"execute executable {exe_target} with user args: {user_args}")
        # build underlying exe
        cmake_build(build_dir_abs, target=exe_target, jobs=jobs, verbose=verbose)
        p = find_executable(build_dir_abs, exe_target)
        if not p:
            print(f"Error: built executable '{exe_target}' not found under {build_dir_abs}")
            return 2
        abs_p = str(p.resolve())
        print(f"running: {abs_p} {' '.join(user_args)}")
        # run it by absolute path; set cwd to the exe directory
        return subprocess.call([abs_p] + user_args, cwd=str(p.parent))


def main(argv: List[str]) -> int:
    # Parse legacy positional arguments
    argv, legacy_build_flag, legacy_recreate, legacy_install, legacy_verbose = parse_legacy_args(argv)

    parser = argparse.ArgumentParser(prog="cbuild", description="Project build helper")
    parser.add_argument("-d", action="store_true", help="Debug build (sets CMAKE_BUILD_TYPE=Debug and uses build_debug)")
    parser.add_argument("-r", action="store_true", help="Recreate build dir before configure")
    parser.add_argument("-i", "--install", action="store_true", help="Install target (sudo cmake --install)")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show verbose build output (passes -v to `cmake --build`) - also supported as legacy third positional 'v'")
    parser.add_argument("-j", type=int, default=DEFAULT_JOBS, help="Parallel jobs")
    parser.add_argument("--build-dir", default=None, help="Build directory (overrides default)")
    parser.add_argument("command", nargs=argparse.REMAINDER, help="Command to run (e.g. run_inspector_svr) and optional '--' followed by runtime args")

    ns = parser.parse_args(argv)

    # Apply legacy interpretations
    if legacy_build_flag is not None:
        ns.d = legacy_build_flag
    if legacy_recreate:
        ns.r = True
    if legacy_install:
        ns.install = True
    if legacy_verbose:
        ns.verbose = True

    build_dir = Path(ns.build_dir) if ns.build_dir else (Path("build_debug") if ns.d else Path("build"))
    config = "Debug" if ns.d else "Release"

    # Resolve build directory to an absolute path under the project root
    build_dir_abs = (ROOT / build_dir).resolve() if not build_dir.is_absolute() else build_dir.resolve()

    # Parse command and runtime args
    cmd, user_args = parse_command_and_args(ns.command)
    
    # Ensure build dir and configure
    ensure_build_dir(build_dir_abs, recreate=ns.r, config=config)

    # Change current working directory to the build dir
    os.chdir(str(build_dir_abs))

    # If no command, just build default
    if not cmd:
        cmake_build(build_dir_abs, target=None, jobs=ns.j, verbose=ns.verbose)
        if ns.install:
            install(build_dir_abs)
        return 0

    # Handle commands
    first = cmd[0]
    if first.startswith("run_"):
        run_target = first
        exe_target = run_target[len("run_"):]
        return handle_run_command(build_dir_abs, exe_target, run_target, user_args, ns.j, ns.verbose)
    elif first == "run" and len(cmd) >= 2:
        exe_target = cmd[1]
        run_target = f"run_{exe_target}"
        return handle_run_command(build_dir_abs, exe_target, run_target, user_args, ns.j, ns.verbose)
    else:
        print("Unsupported command. Use run_<target> or run <target>.")

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
