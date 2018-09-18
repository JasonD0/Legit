#!/bin/sh

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

# test commands before any commits
echo dsda > c;
./legit.pl "add" c;
./legit.pl "log";
./legit.pl "show" ":c";
./legit.pl "rm" c;

# test commit usage errors
echo das > a;
./legit.pl "add" a;
./legit.pl "commit" "-m" "-a" "dasda";
./legit.pl "commit" "-a" "-m";
./legit.pl "commit" "-m" "";

# test rm usage errors
echo a > b;
./legit.pl "add" b;
./legit.pl "commit" "-m" b;
./legit.pl "rm" "--cached" "--forced" b;
./legit.pl "rm" "-b";

# test commands with extra invalid commands
echo a > d;
echo b > e;
echo c > f;
./legit.pl "add" d e f  dsadsadsad;
./legit.pl "commit" "-m" "dsadsadasd" "dasdasdasdasda";
./legit.pl "commit" "-m" "dasd";
./legit.pl "log" "dasdasdasdasda";
./legit.pl "log";
./legit.pl "show" "0:d" "dsadasdsadasda";
./legit.pl "show" "0:e";
./legit.pl "rm" d "dasdsadsadasda";
./legit.pl "status" "dsadasdasdasdsa";

