#!/bin/bash
name=$1
if [ $name = "sukki" ]; then
  echo $name
elif [ $name = "morgis" ]; then
  echo "hi ${name}"
else
  echo "so wht"
fi
