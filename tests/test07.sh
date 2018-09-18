#!/bin/sh

if [ ! -e ".legit" ] 
then
    ./legit.pl "init";
fi

#test rm on different file statuses (excluding rm --forced file)
# tries  rm first  then rm --cached  then rm --force --cached

touch a b c d e;
./legit.pl "add" a b c d e;
./legit.pl "commit" "-m" 'first commit';
echo hello >a;
echo hello >b;
echo hello >c;
./legit.pl "add" a b;
echo world >a;
rm d;
./legit.pl "rm" e;


./legit.pl "rm" a;
if ($? eq 1) 
then 
    ./legit.pl "rm" "--cached" a;
    if ($? eq 1) {
        ./legit.pl "rm" "--force" "--cached" a;
    }
fi
./legit.pl "show :a";
./legit.pl "status";

./legit.pl "rm" b;
if ($? eq 1) 
then 
    ./legit.pl "rm" "--cached" b;
    if ($? eq 1) {
        ./legit.pl "rm" "--force" "--cached" b;
    }
fi
./legit.pl "show :b";
./legit.pl "status";

./legit.pl "rm" c;
if ($? eq 1) 
then 
    ./legit.pl "rm" "--cached" c;
    if ($? eq 1) {
        ./legit.pl "rm" "--force" "--cached" c;
    }
fi
./legit.pl "show :c";
./legit.pl "status";

./legit.pl "rm" d;
if ($? eq 1) 
then 
    ./legit.pl "rm" "--cached" d;
    if ($? eq 1) {
        ./legit.pl "rm" "--force" "--cached" d;
    }
fi
./legit.pl "show :d";
./legit.pl "status";

./legit.pl "rm" e;
if ($? eq 1) 
then 
    ./legit.pl "rm" "--cached" e;
    if ($? eq 1) {
        ./legit.pl "rm" "--force" "--cached" e;
    }
fi
./legit.pl "show :e";
./legit.pl "status";





