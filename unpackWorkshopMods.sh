#!/bin/bash

[ -e autoUnpack ] && rm -r autoUnpack
mkdir autoUnpack

ls "../../workshop/content/211820/" | while read ID ; do
  ls "../../workshop/content/211820/${ID}" | grep '.pak' | while read PAK ; do
    linux/asset_unpacker "../../workshop/content/211820/${ID}/${PAK}" "autoUnpack/${ID}_${PAK}"
  done
done
