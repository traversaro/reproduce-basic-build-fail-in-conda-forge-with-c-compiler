# reproduce-basic-build-fail-in-conda-forge-with-c-compiler

Reproducer for [conda-forge/compilers-feedstock#84](https://github.com/conda-forge/compilers-feedstock/issues/84):
binutils tools are not exported by the compiler activation scripts in version
2.0.0. Three separate Pixi environments each have two direct dependencies:

| Environment | Compiler dependency | Build-system dependency |
| --- | --- | --- |
| `c-compiler` | `c-compiler==2.0.0` | `cmake` |
| `gcc` | `gcc = "*"` | `cmake` |
| `clang` | `clang = "*"` | `cmake` |

No environment explicitly adds binutils or compiler activation outputs such as
`gcc_linux-64` or `clang_linux-64`. The reproducer does not set `CC`, `AR`,
`RANLIB`, or `LD`, or override CMake's tool discovery. Package-provided
activation and CMake's default discovery determine which tools are used;
the selected compiler is printed in the logs.

The C-only CMake project builds three independent targets from the same small
function:

- `example_shared`: a shared library.
- `example_static`: a static library.
- `example_executable`: an executable that checks the function's result.

## Run locally

Install [Pixi](https://pixi.sh) and `make`, then run:

```sh
pixi run --environment c-compiler test
pixi run --environment gcc test
pixi run --environment clang test
```

This attempts all three targets, reports each failure, and exits nonzero if any
target fails. To test one target, use, for example,
`pixi run --environment clang shared`, replacing `shared` with `static` or
`executable` as needed. The executable task also runs the resulting program.
Each target uses its own build directory, removed before configuration to avoid
cached tools masking the issue.

A host with system binutils may mask the problem. To reproduce without them:

```sh
docker build -t c-compiler-reproducer .
docker run --rm c-compiler-reproducer
docker run --rm c-compiler-reproducer --environment gcc test
docker run --rm c-compiler-reproducer --environment clang test
```

The default Docker command tests the `c-compiler` environment.

The Docker image uses Debian bookworm-slim with only CA certificates and `make`
added via apt. `make` is a build runner, not part of binutils. Pixi is copied
from its official image; no compiler or binutils is copied from that image.
The test checks that Debian's binutils packages and system binutils commands
are absent before entering the Pixi environment.

## GitHub Actions

The workflow builds the Docker image and runs shared, static, and executable
tests for all three environments in nine separate matrix jobs with fail-fast
disabled. Tests are not marked as
expected failures: a missing tool should fail CI, while successful builds show
which targets work without system binutils. Logs include compiler activation
variables, tool discovery, and CMake's selected compiler, archiver, ranlib, and
linker. The committed Pixi lockfile pins the tested packages.

### Observed results

The [initial GitHub Actions run](https://github.com/traversaro/reproduce-basic-build-fail-in-conda-forge-with-c-compiler/actions/runs/41208392929)
with the committed environment (`c-compiler` 2.0.0, GCC 15.3.0, CMake 4.4.5)
confirmed that system binutils were absent in every job:

| Target | Result |
| --- | --- |
| Shared library | Built successfully |
| Static library | Failed when invoking `CMAKE_AR-NOTFOUND` |
| Executable | Built and ran successfully |

CMake reported `CMAKE_AR=CMAKE_AR-NOTFOUND`, `CMAKE_RANLIB=:`, and
`CMAKE_LINKER=CMAKE_LINKER-NOTFOUND`. The compiler driver can still link shared
libraries and executables using its bundled tools, but static-library creation
needs an archiver discoverable by CMake. The static job intentionally remains
red to expose this failure.