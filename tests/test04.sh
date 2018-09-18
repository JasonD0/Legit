#!/bin/sh

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

# test add and commiting unchanged file
echo a > a;
./legit.pl "add" a;
./legit.pl "commit" "-m" "das";
./legit.pl "add" a;
./legit.pl "commit" "-m" "dasda";
./legit.pl "log";

# test add then change file back to last commit and try commit
echo b > b;
./legit.pl "add" b;
./legit.pl "commit" "-m" "w";
echo bb > b;
./legit.pl "add" b;
echo b > b;
./legit.pl "add" b;
./legit.pl "commit" "-m" "dasd";

