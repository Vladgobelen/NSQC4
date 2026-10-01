#!/bin/sh
cd "/home/diver/Games/wc/CircleL/Interface/AddOns/NSQC4/"
j=$(date)
git add .
git commit -m "$1 $j"
git push git@github.com:Vladgobelen/NSQC4.git
git push git@gitlab.com:Vladgobelen/NSQC4.git