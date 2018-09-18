#!/bin/sh

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

# test different rm flags on file statuses "file modified" and "file modified and changes in index"

touch a b;
./legit.pl "add" a b;
./legit.pl "commit" "-m" 'first commit';
echo hello >a;
echo hello >b;
echo hello >c;
./legit.pl "add" a b;
echo world >a;

./legit.pl "rm" a;
./legit.pl "show :a";
cat a;
./legit.pl "status";

./legit.pl "rm" b;
./legit.pl "show :b";
cat b;
./legit.pl "status";
rm a b;

touch a b;
./legit.pl "add" a b;
./legit.pl "commit" "-m" 'first commit';
echo hello >a;
echo hello >b;
echo hello >c;
./legit.pl "add" a b;
echo world >a;

./legit.pl "rm" "--cached" a;
./legit.pl "show :a";
cat a;
./legit.pl "status";

./legit.pl "rm" "--cached" b;
./legit.pl "show :b";
cat b;
./legit.pl "status";
rm a b;

touch a b;
./legit.pl "add" a b;
./legit.pl "commit" "-m" 'first commit';
echo hello >a;
echo hello >b;
echo hello >c;
./legit.pl "add" a b;
echo world >a;

./legit.pl "rm" "--force --cached" a;
./legit.pl "show :a";
cat a;
./legit.pl "status";

./legit.pl "rm" "--force --cached" b;
./legit.pl "show :b";
cat b;
./legit.pl "status";
rm a b;

touch a b;
./legit.pl "add" a b;
./legit.pl "commit" "-m" 'first commit';
echo hello >a;
echo hello >b;
echo hello >c;
./legit.pl "add" a b;
echo world >a;

./legit.pl "rm" "--force" a;
./legit.pl "show :a";
cat a;
./legit.pl "status";

./legit.pl "rm" "--force" b;
./legit.pl "show :b";
cat b;
./legit.pl "status";
rm a b;
