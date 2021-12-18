#!/bin/bash

PREFIX=$(realpath build)
WEBSITE=$(realpath website)

set -e

echo "Prepare Website root"

rm -rf "${WEBSITE}"
cp -r src/website/src/ "${WEBSITE}"
mkdir -p "${WEBSITE}/download"
mkdir -p "${WEBSITE}/benchmark"
mkdir -p "${WEBSITE}/img"

echo "Prepare SDK root"

rm -rf "${PREFIX}"
mkdir "${PREFIX}"

mkdir -p "${PREFIX}/native/x86_64-windows/bin/"
mkdir -p "${PREFIX}/native/x86_64-linux/bin/"
mkdir -p "${PREFIX}/native/x86_64-macos/bin/"
mkdir -p "${PREFIX}/native/aarch64-linux/bin/"
mkdir -p "${PREFIX}/native/aarch64-macos/bin/"

cp src/sdk/docs/sdk-readme.txt "${PREFIX}/README.txt"

echo "Prepare examples..."
mkdir -p ${PREFIX}/examples/{code,graphics}

cp "src/sdk/examples/usage.c" "${PREFIX}/examples/code/usage.c"
cp "src/sdk/examples/index.htm" "${PREFIX}/examples/code/polyfill.htm"

cp "src/specification/design/logo.tvg"  "${PREFIX}/examples/graphics/tinyvg.tvg"
cp "src/examples/files/everything.tvg"  "${PREFIX}/examples/graphics/feature-test.tvg"
cp "src/website/src/img/shield.tvg"     "${PREFIX}/examples/graphics/shield.tvg"
cp "src/website/src/img/tiger.tvg"      "${PREFIX}/examples/graphics/tiger.tvg"
cp "src/website/src/img/flowchart.tvg"  "${PREFIX}/examples/graphics/flowchart.tvg"
cp "src/website/src/img/comic.tvg"      "${PREFIX}/examples/graphics/comic.tvg"
cp "src/website/src/img/chart.tvg"      "${PREFIX}/examples/graphics/chart.tvg"
cp "src/website/src/img/app-icon.tvg"   "${PREFIX}/examples/graphics/app-icon.tvg"

echo "Prepare Zig package"
mkdir -p "${PREFIX}/zig"

cp -r "src/sdk/vendor/parser-toolkit/src" "${PREFIX}/zig/ptk"
cp -r src/sdk/src/lib/*                   "${PREFIX}/zig"

echo "Build native libraries"

pushd src/sdk

zig build -Drelease-safe -Dinstall-lib=false -Dinstall-bin -Dinstall-www=false --prefix "${PREFIX}/native/" install

zig build -Drelease-safe -Dinstall-include=false -Dinstall-www=false --prefix "${PREFIX}/native/x86_64-windows" -Dtarget=x86_64-windows install
zig build -Drelease-safe -Dinstall-include=false -Dinstall-www=false --prefix "${PREFIX}/native/x86_64-macos"   -Dtarget=x86_64-macos   install
zig build -Drelease-safe -Dinstall-include=false -Dinstall-www=false --prefix "${PREFIX}/native/x86_64-linux"   -Dtarget=x86_64-linux   install
zig build -Drelease-safe -Dinstall-include=false -Dinstall-www=false --prefix "${PREFIX}/native/aarch64-macos"  -Dtarget=x86_64-macos   install
zig build -Drelease-safe -Dinstall-include=false -Dinstall-www=false --prefix "${PREFIX}/native/aarch64-linux"  -Dtarget=x86_64-linux   install

echo "Build wasm polyfill"
zig build -Drelease-small -Dinstall-include=false -Dinstall-lib=false -Dinstall-bin=false --prefix "${PREFIX}"

echo "Patch DLL paths"
mv ${PREFIX}/native/x86_64-windows/lib/tinyvg{.dll,}.dll
mv ${PREFIX}/native/x86_64-windows/lib/tinyvg{.dll,}.pdb

popd

mv ${PREFIX}/{www,js}

echo "Build specification"
make -C src/specification/

cp src/specification/specification.pdf "${PREFIX}/specification.pdf"

cp src/specification/specification.pdf "${WEBSITE}/download/specification.pdf"
cp src/specification/specification.txt "${WEBSITE}/download/specification.txt"
cp src/specification/specification.md "${WEBSITE}/download/specification.md"

echo "Build dotnet tooling"
make -C src/sdk/src/tools/svg2tvgt/ "PREFIX=$(pwd)/build/native" install

echo "Bundle SDK into website"

pushd "${PREFIX}"
7z a "${WEBSITE}/download/tinyvg-sdk.zip" *
popd

pushd "${WEBSITE}/download"
unzip -l tinyvg-sdk.zip > tinyvg-sdk.txt
popd

echo "Bundle toolchains into website"

function bundleToolchain()
{
  pushd "${PREFIX}/native/$1/bin"
  7z a "${WEBSITE}/download/tinyvg-$1.zip" *
  popd
}

bundleToolchain x86_64-windows
bundleToolchain x86_64-macos
bundleToolchain x86_64-linux
bundleToolchain aarch64-macos
bundleToolchain aarch64-linux

echo "Integrate polyfill into website"

pushd "${PREFIX}/js"
7z a "${WEBSITE}/download/tinyvg-polyfill.zip" *
popd

cp ${PREFIX}/js/* "${WEBSITE}/polyfill/"

echo "Add social media preview"

cp -r src/specification/design/social-media-preview.png "${WEBSITE}/img/social-media-preview.png"