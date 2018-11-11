#!/bin/bash

PLATFORMS=macOS,iOS

carthage update --no-use-binaries --platform ${PLATFORMS}
