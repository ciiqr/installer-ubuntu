#!/usr/bin/env bash

install()
{
	sudo apt-get install --no-install-recommends --allow-unauthenticated -y "$@"
}
ppa()
{
	sudo add-apt-repository "ppa:$1" -y
}
