#!/bin/sh

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

# try add file not in current directory
# check if file before and/or file after still added 
echo a > a;
echo b > b;
./legit.pl "add" a dadasd b;
./legit.pl "show" ":a";
./legit.pl "show" ":b";
./legit.pl "status";


# rm file not in current directory
# check if file before and/or file after still removed
echo c > c;
echo d > d;
./legit.pl "add" a b;
./legit.pl "rm" "--forced" a dasdasda b;
./legit.pl "status";
