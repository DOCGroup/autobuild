#!/bin/sh

rm ace_vms.tar
tar -cf ace_vms.tar -X excludes.lst ACE_wrappers
