BUILD_FLAGS := "-collection:src=src -collection:lib=lib"
OUT := "kidnapper.bin"

run: build
    ./{{OUT}}

debug: build
    lldb {{OUT}}

build:
    odin build src -debug {{BUILD_FLAGS}} -out:{{OUT}}

update-submodules:
    git submodule update --recursive --remote
