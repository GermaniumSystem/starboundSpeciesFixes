#!/bin/bash

[ -e mods ] && rm -r mods
mkdir mods
cp -a mods.prod/* mods/

WSDIR="mods.ws/"
DESTDIR="mods/"

ls "$WSDIR"  | while read MODID ; do
  ls "${WSDIR}/${MODID}/" | while read FILE ; do
    cp -a "${WSDIR}/${MODID}/${FILE}" "${DESTDIR}/${MODID}_${FILE}"
    echo "- Added '${WSDIR}/${MODID}/${FILE}' as '${DESTDIR}/${MODID}_${FILE}'"
  done
done
