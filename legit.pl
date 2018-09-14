#!/usr/bin/perl -w 

# for status    just add status text file 

# checks if files identical
sub cmp_files {
    my ($file1) = shift @_;
    my ($file2) = shift @_;
    
    open F1, '<', $file1;
    open F2, '<', $file2;
    
    @f1 = <F1>;
    @f2 = <F2>;
    
    close F1;
    close F2;


    return 0 if (@f1 != @f2);
    
    while (@f1 != 0) {
        return 0 if ((shift @f1) ne (shift @f2));
    }
    
    return 1;
}

# get next commit number 
sub newest_commit {
   my $max=0;
    foreach my $commits (glob ".legit/*") {
        $commits =~ s/\.legit\///g;
        next if (!($commits =~ m/commit_/));
        $commits =~ s/commit_//g;
        $commits++;
        $max = $commits if ($max < $commits);
    } 
    return $max;  
}

# commit functionality
sub copy_files {
    my ($message) = shift @_;
    my ($flag) = shift @_;
    
    # maybe when add to index  -> creates txt file   -> check index has this txt file    when commit rename 
    if (!(-e ".legit/index") && $flag ne "-a") {
        print "Nothing to commit\n";
    } else { 
        my $max=newest_commit;

        my $fileChanged = 0;
         
        my $input_path = ".legit/index/"; 
        my $output_path = ".legit/index/";  
        if (!(-e ".legit/index")) {
            my $latest_commit = $max - 1;
            $input_path = ".legit/commit_$latest_commit/";
            $output_path = ".legit/commit_$max/";
        }    

        # commit -a  add all files in current directory to index if an older version of that file is already in the index
        if ($flag eq "-a") {
            # need add files from prev commit 
            foreach $file (glob "*") {
                next if (!(-e "$input_path$file"));
                my $y = cmp_files "$input_path$file", "$file";  # compare prev version of file 
                next if ($fileChanged == 0 && $y == 1);  # file havent been changed ie something to commit
                
                $fileChanged = 1;
                mkdir $output_path if (!(-e ".legit/commit_$max"));
                
                open F, '<', "$file";
                open C, '>', "$output_path$file";
                
                print C <F>;
                
                close C;
                close F;
            }
        }        
        
        # for flag  -a 
        if ($fileChanged == 1) {
            # copy files from last commit into newest commit
            $x = $max - 1;
            foreach $oldFile (glob ".legit/commit_$x/*") {
                $oldPath = $oldFile;
                $oldFile =~ s/\.legit\/commit_$x//g;
                next if (-e "$output_path$oldFile"); # skip file if already in newest commit
                
                # write old files to new commit
                open F, '<', $oldPath;
                open N, '>', "$output_path$oldFile";
                print N <F>;
                close N;
                close F;
            }
        }
        
        # commit if flag -a and a file has been changed  or  flag is -m  or  flag -a and file was added previously
        if ($fileChanged == 1 || $flag eq "-m" || -e ".legit/index") {
            if (-e ".legit/index") {
                rename ".legit/index", ".legit/commit_$max"; 
                
                #if (!(-e ".legit/index")) {
                    #mkdir ".legit/index";
                    ## copy files from last commit into index
                    #$max = newest_commit;
                    #$max--;
                    #foreach $oldFile (glob ".legit/commit_$max/*") {
                   #     open F, '<', $oldFile;
                  #      $oldFile =~ s/\.legit\/commit_$max//g;
                 #       open N, '>', ".legit/index/$oldFile";
                #        print N <F>;
               #         close N;
              #          close F;
             #       }
            #    } 
            } 
            
            print "Committed as commit $max\n";

            # write commit message to log
            open O, '<', ".legit/log.txt";
            open F, '>', ".legit/log1.txt";
            print F "$max $message\n";
            print F <O>;
            close F;
            close O;
            rename ".legit/log1.txt", ".legit/log.txt";
        } else {
            print "Nothing to commit\n";
        }
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
        print STDERR "legit.pl: error: .legit already exists\n";
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
    print STDERR "legit.pl: error: no .legit directory containing legit repository exists\n";
    exit 1;
}

elsif ($command eq "add") {
    if (!(-e ".legit/index")) {
        mkdir ".legit/index";
        # copy files from last commit into index
        $max = newest_commit;
        $max--;
        foreach $oldFile (glob ".legit/commit_$max/*") {
            open F, '<', $oldFile;
            $oldFile =~ s/\.legit\/commit_$max//g;
            open N, '>', ".legit/index/$oldFile";
            print N <F>;
            close N;
            close F;
        }
    } 

    foreach $file (@ARGV) {
        if (!(-e $file)) {
            print STDERR "legit.pl: error: can not open '$file'";
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
            copy_files $m, "-m";
        }
        
    # commit -a -m "message"
    } elsif ($flag eq "-a" && defined $m && $m eq "-m" && defined ($message = shift @ARGV)) {
        # invalid extra arguments  or  empty message
        if (defined (shift @ARGV) || $message eq "") {
            print "usage: legit.pl commit [-a] -m commit-message\n";
            exit 1;
        }
        
        copy_files $message, "-a";
    
    } elsif ($flag =~ m/-m(.+)/ && defined $m) {
        print "usage: legit.pl commit [-a] -m commit-message\n";
        exit 1;
   
    # commit with no separation between -m and message
    } elsif (($flag eq "-a" && defined $m && $m =~ m/-m(.+)/) || $flag =~ m/-m(.+)/) {
        # invalid extra arguments  or  empty message
        if (defined (shift @ARGV) || $1 eq "") {
            print "usage: legit.pl commit [-a] -m commit-message\n";
            exit 1;
        }
        $x = "-m";
        $x = $flag if ($flag eq "-a");
        copy_files $1, $x;
       
    # incorrect commit syntax
    } else {
        print "usage: legit.pl commit [-a] -m commit-message\n";
        exit 1;
    }
}

elsif ($command eq "log") {
    # no commits
    if (!(-e ".legit/commit_0")) {
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
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
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
        exit 1;
    }
    
    # show commit:fileName 
    if (defined $cf && $cf =~ m/^(\d+):([A-Za-z0-9]{1}[A-Za-z0-9_\.\-]*)$/) {
        # commit doesnt exit
        if (!(-e ".legit/commit_$1")) {
            print STDERR "legit.pl: error: unknown commit '$1'\n";
            exit 1;
        }
        
        # file doesnt exist in commit
        if (!(-e ".legit/commit_$1/$2")) {
            print STDERR "legit.pl: error: '$2' not found in commit $1\n";
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
            # for rm   removes from index   but doenst read from latest commit  so need change
                # so maybe create index file after rename    OR   text file says which files in index -> refer to latest commit (for show and rm) 
                                                                     # if affects   commit/add   then prob do first one  
                #  add and comit file     change that file, add   then show :file and show latest commit:file       see how index works
                #  rm file   show :file    show lastCommit:file    see how rm works
                # if add file   then must commit file  before rm it (is it same for if any other file different to rm file)
                
            $max=newest_commit;
            $max--;
            if (!(-e ".legit/commit_$max/$1")) {
                print STDERR "legit.pl: error: '$1' not found in index\n";
                exit 1;
            }            
            
            open F, '<', ".legit/commit_$max/$1";
            print <F>;
            close F;
            
        # read from index
        } else {
            if (!(-e ".legit/index/$1")) {
                print STDERR "legit.pl: error: '$1' not found in index\n";
                exit 1;
            }
            open F, '<', ".legit/index/$1";
            print <F>;
            close F;
        }    
    
    # commit doesnt exist
    } elsif (defined $cf && $cf =~ m/^(.*):.*$/) {
        print STDERR "legit.pl: error: unknown commit '$1'\n";
        exit 1;
    
    # singular word argument not in form of commit:fileName
    } elsif (defined $cf && !($cf =~ m/^.*:.*$/) && !(defined (shift @ARGV))) {
       print STDERR "legit.pl: error: invalid object $cf\n";    
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
    
} elsif ($command eq "rm" || $command eq "status" || $command eq "branch" || $command eq "checkout" || $command eq "merge") {  

# invalid command
} else {
    print STDERR "legit.pl: error: unknown command a.txt
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
