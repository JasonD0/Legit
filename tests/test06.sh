#!/bin/sh

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

# test commiting 2 files differing by an extra empty line
echo a > a;
echo b >> a;
echo "" >> a;
echo a > b;
echo b >> b;
./legit.pl "add" a;
./legit.pl "commit" "-m" "da";

# test commiting 2 files differing by an extra space at the end of a line
echo a > a;
echo "b " >> a;
echo a > b;
echo b >> b;
./legit.pl "add" a;
./legit.pl "commit" "-m" "ba";

