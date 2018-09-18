#!/bin/sh 

# commit file => change file => change file back to last commit's content 
# commit file => change file and add to index => change file back to last commit's content => rm 
#                                                                                          => commit

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

echo a > a;
echo b > b;

./legit.pl "add" a b;
./legit.pl "commit" "-m" "first commit";
./legit.pl "status";

echo a >> a;
echo B > b;

./legit.pl "add" a;
./legit.pl "status";

echo a > a;
echo b > b;

./legit.pl "status";
./legit.pl "rm" a;
./legit.pl "rm" "--cached" a;
./legit.pl "status";
./legit.pl "commit" "-m" "second commit";

