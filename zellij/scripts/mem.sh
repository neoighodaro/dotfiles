#!/bin/bash
memory_pressure | awk '/percentage/{gsub(/%/,""); print 100-$5"%"}'
