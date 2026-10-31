# reproduce-basic-build-fail-in-conda-forge-with-c-compiler

Reproducer for [conda-forge/compilers-feedstock#84](https://github.com/conda-forge/compilers-feedstock/issues/84):
binutils tools are not exported by the compiler activation scripts in version
2.0.0. The Pixi environment has only two direct dependencies: `c-compiler` and
`cmake`. In particular, it does not explicitly install `binutils`, set `AR`, or
override CMake's tool discovery.

The C-only CMake project builds three independent targets from the same small
function:

- `example_shared`: a shared library.
- `example_static`: a static library.
- `example_executable`: an executable that checks the function's result.

## Run locally

Install [Pixi](https://pixi.sh) and `make`, then run:

```sh
pixi run test
```

This attempts all three targets, reports each failure, and exits nonzero if any
target fails. To test one target, use `pixi run shared`, `pixi run static`, or
`pixi run executable`. The executable task also runs the resulting program.
Each target uses its own build directory, removed before configuration to avoid
cached tools masking the issue.

A host with system binutils may mask the problem. To reproduce without them:

```sh
docker build -t c-compiler-reproducer .
docker run --rm c-compiler-reproducer
```

The Docker image uses Debian bookworm-slim with only CA certificates and `make`
added via apt. `make` is a build runner, not part of binutils. Pixi is copied
from its official image; no compiler or binutils is copied from that image.
The test checks that Debian's binutils packages and system binutils commands
are absent before entering the Pixi environment.

## GitHub Actions

The workflow builds the Docker image and runs shared, static, and executable
tests in separate matrix jobs with fail-fast disabled. Tests are not marked as
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