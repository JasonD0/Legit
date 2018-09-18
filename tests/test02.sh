#!/bin/sh

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

# removing file from index with status file modified
echo a > a;
./legit.pl "add" a;
./legit.pl "commit" "-m" a;
echo aa > a;
./legit.pl "add" a;
./legit.pl "rm" a;
./legit.pl "rm" "--cached" a;
./legit.pl "status";

# remove file where last commit same as current but different to index
echo a > a;
./legit.pl "add" a;
./legit.pl "commit" "-m" a;
echo aa > a;
./legit.pl "add" a;
echo a > a;
./legit.pl "rm" a;
./legit.pl "rm" "--cached" a;
./legit.pl "rm" "--force" "--cached" a;
./legit.pl "status";
