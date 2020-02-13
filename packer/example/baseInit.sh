#!/bin/bash -e
main() {
  sudo yum install -y java-1.8.0-openjdk-devel.x86_64
  sudo yum remove -y java-1.7.0-openjdk
}
main
