#!/usr/bin/env bash

. /scripts/inc/apt.sh

# Explicitly install kernel because I had a problem once right after re-installation where it was installed but seemingly the wrong version
# TODO: Maybe we just need to make the packages installed though d-i pull from the internet? (either remove local (to cd) repo entirely, or set some preseed option, idk...)
# NOTE: It seems the generic/server kernels are no longer different http://askubuntu.com/a/177643
install linux-generic

# TODO: probably move this to preseed file?
# curl for installing salt later on
install curl ca-certificates
