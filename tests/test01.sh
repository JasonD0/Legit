#!/bin/sh 

# test different sequences of statuses

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

echo b > b; # add -> commit -> change file -> add
echo a > a; # add -> commit -> change file -> add -> commit
echo g > g; # add -> commit -> change file -> add -> change file
echo h > h; # add -> commit -> change file -> add -> change file -> commit

./legit.pl "add" a b g h;
./legit.pl "commit" "-m" "first commit";
echo ccc > c;
echo bb > b;
echo aa > a;
echo gg > g;
echo hh > h;

./legit.pl "add" a b;     
./legit.pl "status";    # b ends

./legit.pl "commit" "-m" "second commit";
./legit.pl "status";    # a ends
    
./legit.pl "add" h;
echo hhh > h;
echo ggg > g;
./legit.pl "status";    # g ends

./legit.pl "commit" "-m" "third commit";
./legit.pl "status";    # h ends






