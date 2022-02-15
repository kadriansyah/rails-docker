#!/bin/bash
docker run -d --net devnet --name rails -p 80:80 kadriansyah/rails

# note:
## don't forget to create devnet using this command:
## docker network create devnet