#!/bin/sh

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

# test commit -a -m  on different file statuses

touch a b c d e f g;
./legit.pl "add" a b c d e f g;
./legit.pl "commit" "-a" "-m" "dasda";
./legit.pl "commit" "-m" "dasdas1";
echo dasda > a;
echo dsadsadas > b;
./legit.pl "rm" "--cached" g;
./legit.pl "rm" "--forced" f;
./legit.pl "status";
./legit.pl "commit" "-a" "-m" "sdasdasdasdasda";
./legit.pl "status";
./legit.pl "log";
echo dasda > c;
./legit.pl "add" c;
echo 2312 > c;
./legit.pl "commit" "-a" "-m" "sdasds12311213123323a";
./legit.pl "status";
