#!/bin/sh
luacheck .
if [ $? -eq 127 ]
then 
   echo "ERR: 'luacheck' is missing"
   echo " You could try installing it (Debian ex. 'apt install lua-check')"
fi
if [ $? -eq 2 ]
then
   echo "No copying check errors"
   exit $?
fi
if [ $? -eq 1 ]
then
   echo "Check your warnings, none is best"
fi

MOD_PATH=~/Minetest/mods/eggwars/

mkdir -p ${MOD_PATH}schems/
mkdir -p ${MOD_PATH}stuff/

cp -ru schems/*.mts ${MOD_PATH}schems/
cp -ru stuff ${MOD_PATH}
cp -ru *.lua ${MOD_PATH}
cp -ru *.txt ${MOD_PATH}
cp -ru LICENSE ${MOD_PATH}
