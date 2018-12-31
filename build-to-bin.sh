#!/bin/sh
swift build -c release -Xswiftc -static-stdlib
cd .build/release
cp -f Zolang /usr/local/bin/zolang
cd ..
cd ..
