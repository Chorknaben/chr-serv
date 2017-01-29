#!/bin/sh
find ./mirror/doms -type f -exec sed -i "s/href=\"#!\//href=\"\/#!\//g" {} \;
