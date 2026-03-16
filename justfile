BUILD_FLAGS := "-collection:src=src -collection:lib=lib"
OUT := "tunnels.bin"

run: shader build
    ./{{OUT}}

debug: shader build
    lldb {{OUT}}

build:
    odin build src -debug {{BUILD_FLAGS}} -out:{{OUT}}

[macos]
shader:
    sokol-shdc -i src/shader/shader.glsl -o src/shader/shader.odin -l metal_macos -f sokol_odin

update-submodules:
    git submodule update --recursive --remote
