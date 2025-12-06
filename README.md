# cmake_util
cmake utils, such as find packages and pre definitions.

## add_run_target helper

`add_run_target(exe_target [ARGS <args>...])` creates a CMake custom target
named `run_<exe_target>` and a small wrapper script `run_<exe_target>.sh`
in the current binary directory. The wrapper executes the built executable
and forwards any runtime arguments you pass to it.

Usage examples:

```cmake
add_run_target(uni_svr ARGS ${PROJECT_SOURCE_DIR}/doc/server.json uni_svr)
```

Run it from CMake (no extra args):

```bash
cmake --build build --target run_uni_svr
```

Or call the wrapper directly with additional args:

```bash
./build/tests/uni_svr/run_uni_svr.sh extra_arg
```
