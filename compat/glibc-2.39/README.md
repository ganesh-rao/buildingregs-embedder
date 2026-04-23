# glibc 2.39 Compatibility Loader

DeployDash currently builds this project through Railpack. In practice, that
Railpack path can produce a Debian bookworm runtime with glibc 2.36 even when
`railpack.json` requests an Ubuntu 24.04 deploy base.

The bundled `llama-server` binary was built against newer Ubuntu runtime
libraries. `serve.sh` launches it through the loader in this directory so the
process uses compatible `glibc`, `libstdc++`, and related runtime libraries
instead of the host image's older versions.

These files were copied from an Ubuntu 24.04 x86_64 runtime compatible with the
binary. If `llama-server` is rebuilt on an older baseline, this directory can be
removed and `serve.sh` will fall back to the container's default loader.
