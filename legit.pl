#!/usr/bin/perl -w 

# TO DO
# if file added wasnt changed since last commit then nothing to commit     
# new commit folders should have old commit files that werent added and commited   
    # eg add a b commit    add a commit   commit_1 should have b from first but a fron 2nd commit

# commit functionality
sub copy_files {
    if (!(-e ".legit/index")) {
        print "Nothing to commit\n";
    } else { 
        my ($message) = shift @_;
        my $max=0;
        foreach my $commits (glob ".legit/*") {
            $commits =~ s/\.legit\///g;
            next if (!($commits =~ m/commit_/));
            $commits =~ s/commit_//g;
            $commits++;
            $max = $commits if ($max < $commits);
        }
        
        rename ".legit/index", ".legit/commit_$max"; 
       # mkdir ".legit/index";
        
        print "Committed as commit $max\n";
        # write commit message to log
        open O, '<', ".legit/log.txt";
        open F, '>', ".legit/log1.txt";
        print F "$max $message\n";
        print F <O>;
        close F;
        close O;
        rename ".legit/log1.txt", ".legit/log.txt";
    }
}


$command = shift @ARGV;

if ($command eq "init") {
    # invalid extra arguments 
    if (defined (shift @ARGV)) {
        print "usage: legit.pl init\n";
        exit 1;
    }
    if (-e ".legit") {
        print "legit.pl: error: .legit already exists\n";
        exit 1;
    } else {
        mkdir ".legit";
        print "Initialized empty legit repository in .legit\n";
        # create log file txt 
        open F, '>', ".legit/log.txt";
        close F;
    }
}

# using legit without legit initiated 
elsif (!(-e ".legit") && $command ne "init") {
    print "legit.pl: error: no .legit directory containing legit repository exists\n";
    exit 1;
}

elsif ($command eq "add") {
    if (!(-e ".legit/index")) {
        mkdir ".legit/index";
    } 
    foreach $file (@ARGV) {
        if (!(-e $file)) {
            print "legit.pl: error: can not open '$file'";
            exit 1;
        }
        open F, '<', "$file";
        open C, '>', ".legit/index/$file";
        
        print C <F>;
        
        close C;
        close F;
    }
}

elsif ($command eq "commit") {
    $flag = shift @ARGV;
    $m = shift @ARGV;
    if ($flag eq "-m" && defined $m) {
        # commit -m -a  or  invalid extra arguments  or empty message
        if ($m eq "-a" || defined (shift @ARGV) || $m eq "") {
            print "usage: legit.pl commit [-a] -m commit-message\n";
            exit 1;
 
        # commit -m "message"
        } else {
            copy_files $m;
        }
        
    # commit -a -m "message"
    } elsif ($flag eq "-a" && defined $m && $m eq "-m" && defined ($message = shift @ARGV)) {
        # invalid extra arguments  or  empty message
        if (defined (shift @ARGV) || $message eq "") {
            print "usage: legit.pl commit [-a] -m commit-message\n";
            exit 1;
        }
        copy_files $message;

    # commit with no separation between -m and message
    } elsif (($flag eq "-a" && defined $m && $m =~ m/-m(.+)/) || $flag =~ m/-m(.+)/) {
        # invalid extra arguments  or  empty message
        if (defined (shift @ARGV) || $1 eq "") {
            print "usage: legit.pl commit [-a] -m commit-message\n";
            exit 1;
        }
        copy_files $1;
       
    # incorrect commit syntax
    } else {
        print "usage: legit.pl commit [-a] -m commit-message\n";
        exit 1;
    }
}

elsif ($command eq "log") {
    # no commits
    if (!(-e ".legit/commit_0")) {
        print "legit.pl: error: your repository does not have any commits yet\n";
        exit 1;
    
    # invalid extra arguments
    } elsif (defined (shift @ARGV)) {
        print "usage: legit.pl log\n";
        exit 1;
        
    # show log file
    } else {
        open F, '<', ".legit/log.txt";
        print <F>;
        close F;
    }
}

elsif ($command eq "show") {
    $cf = shift @ARGV;
   
    # no commits
    if (!(-e ".legit/commit_0")) {
        print "legit.pl: error: your repository does not have any commits yet\n";
        exit 1;
    }
    
    # show commit:fileName 
    if (defined $cf && $cf =~ m/^(\d+):([A-Za-z0-9]{1}[A-Za-z0-9_\.\-]*)$/) {
        # commit doesnt exit
        if (!(-e ".legit/commit_$1")) {
            print "legit.pl: error: unknown commit '$1'\n";
            exit 1;
        }
        
        # file doesnt exist in commit
        if (!(-e ".legit/commit_$1/$2")) {
            print "legit.pl: error: '$2' not found in commit $1\n";
            exit 1;
        }
        
        open F, '<', ".legit/commit_$1/$2";
        print <F>;
        close F;
    
    # show :fileName 
    } elsif (defined $cf && $cf =~ m/^:([A-Za-z0-9]{1}[A-Za-z0-9_\.\-]*)$/) {
        # when commit, index removed 
        if (!(-e ".legit/index")) {
            # read from latest commit
            $max=0;
            foreach $commits (glob ".legit/*") {
                $commits =~ s/\.legit\///g;
                next if (!($commits =~ m/commit_/));
                $commits =~ s/commit_//g;
                $max = $commits if ($max < $commits);
            }           

            if (!(-e ".legit/commit_$max/$1")) {
                print "legit.pl: error: '$1' not found in index\n";
                exit 1;
            }            
            
            open F, '<', ".legit/commit_$max/$1";
            print <F>;
            close F;
            
        # read from index
        } else {
            if (!(-e ".legit/index/$1")) {
                print "legit.pl: error: '$1' not found in index\n";
                exit 1;
            }
            open F, '<', ".legit/index/$1";
            print <F>;
            close F;
        }    
    
    # commit doesnt exist
    } elsif (defined $cf && $cf =~ m/^(.*):.*$/) {
        print "legit.pl: error: unknown commit '$1'\n";
        exit 1;
    
    # singular word argument not in form of commit:fileName
    } elsif (defined $cf && !($cf =~ m/^.*:.*$/)) {
       print "legit.pl: error: invalid object \n";    
       exit 1;
   
    # argument is : 
    } elsif (defined $cf && $cf =~ m/^:$/) {
        print "legit.pl: error: invalid filename ''\n";
        exit 1;
    
    # no arguments or too many arguments
    } else {
        print "usage: legit.pl <commit>:<filename>\n";
        exit 1;
    }
}

else {
    print "legit.pl: error: unknown command a.txt
Usage: legit.pl <command> [<args>]

These are the legit commands:
   init       Create an empty legit repository
   add        Add file contents to the index
   commit     Record changes to the repository
   log        Show commit log
   show       Show file at particular state
   rm         Remove files from the current directory and from the index
   status     Show the status of files in the current directory, index, and repository
   branch     list, create or delete a branch
   checkout   Switch branches or restore current directory files
   merge      Join two development histories together\n
";
}
