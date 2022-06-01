#!/bin/sh
swift build -c release
sudo cp -f .build/release/Zolang /usr/local/bin/zolang
