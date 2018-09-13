#!/usr/bin/perl -w 

# TO DO
# if file added wasnt changed since last commit then nothing to commit     

# commit functionality
sub copy_files {
    if (!(-e ".legit/index")) {
        print "Nothing to commit\n";
    } else { 
        my ($message) = shift @_;
        my $max=0;
        foreach my $commits (glob ".legit*") {
            next if (!($commits =~ m/commit_/));
            $commits =~ s/"commit_"//g;
            $commits++;
            $max = $commits if ($max < $commits);
        }
        
        rename ".legit/index", ".legit/commit_$max"; 
       # mkdir ".legit/index";
        
        print "Committed as commit $max\n";
        # write commit message to log
        open F, '>>', ".legit/log.txt";
        print F "0: $message\n";
        close F;
    }
}

# using legit without legit initiated 
if (-e ".legit") {
    print "legit.pl: error: no .legit directory containing legit repository exists";
    exit 1;
}

$command = shift @ARGV;

if ($command eq "init") {
    if (-e ".legit") {
        print "legit.pl: error: .legit already exists\n";
        exit 1;
    } else {
        mkdir ".legit";
        # create log file txt 
        open F, '>', ".legit/log.txt";
        close F;
    }
}

if ($command eq "add") {
    if (!(-e ".legit/index")) {
        mkdir ".legit/index";
    } else {
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
}

if ($command eq "commit") {
    $flag = shift @ARGV;
    $m = shift @ARGV;
    if ($flag eq "-m" && defined $m) {
        # commit -m -a  or  invalid extra arguments
        if ($m eq "-a" || defined (shift @ARGV)) {
            print "usage: legit.pl commit [-a] -m commit-message\n";
            exit 1;
 
        # commit -m "message"
        } else {
            copy_files $message;
        }
        
    # commit -a -m "message"
    } elsif ($flag eq "-a" && defined $m && $m eq "-m" && defined ($message = shift @ARGV)) {
        copy_files $message;
        
    # incorrect commit syntax
    } else {
        print "usage: legit.pl commit [-a] -m commit-message\n";
        exit 1;
    }
}

if ($command eq "log") {
    # invalid extra arguments
    if (defined (shift @ARGV)) {
        print "usage: legit.pl log\n";
        exit 1;
        
    # no commits
    elsif (!(-e ".legit/commit_0")) {
        print "legit.pl: error: your repository does not have any commits yet\n";
        exit 1;
    
    # show log file
    } else {
        open F, '<', ".legit/log.txt";
        print <F>;
        close F;
    }
}

if ($command eq "show") {
    $cf = shift @ARGV;
   
    # invalid extra arguments
    if (defined (shift @ARGV)) {
        print "usage: legit.pl show\n";
        exit 1;
    }
   
    # no commits
    if (!(-e ".legit/commit_0")) {
        print "legit.pl: error: your repository does not have any commits yet\n";
        exit 1;
    }
   
    if ($cf =~ m/^(\d*):(\w+)$/) {
        $commit = $1;
        $file = $2;
        # check commit number exists    check index exists    check files exists    
        #legit.pl: error: unknown commit 'file'
        if (defined $commit) {
            open F, '<', ".legit/commit_$commit/$file";
            print <F>;
            close F;
        # no commit provided, show file in index
        } else {
            open F, '<', ".legit/index/$file";
            print <F>;
            close F;
        }
        
    # no arguments or too many arguments
    } else {
        print "usage: legit.pl <commit>:<filename>\n";
        exit 1;
    }
}
