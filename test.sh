#!/bin/sh
# Command Line Tools alone don't always register the swift-testing macro plugin; pass it explicitly.
exec swift test -Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing "$@"
