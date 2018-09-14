#!/usr/bin/perl -w 

# for status    just add status text file 

# prints commands for legit 
sub print_commands {
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
    exit 1;
}

# checks if file name is valid ie start with an alphanumeric character ([a-zA-Z0-9]) 
# and will only contain alpha-numeric characters plus '.', '-' and '_' characters.
sub valid_file {
    my ($fileName) = shift @_;
    return 0 if (!($fileName =~ m/^[A-Za-z0-9]{1}[A-Za-z0-9\.\-\_]/));
    return 1;
}

# add file to given destination
sub add_to_dest {
    my ($src) = shift @_;
    my ($dest) = shift @_;
    
    open F, '<', $src;
    open C, '>', $dest;
    
    print C <F>;
    
    close C;
    close F;
}

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

# removes files from current directory  or  current directory and the index
sub rm_files {
    my ($forced) = shift @_;
    my ($cached) = shift @_;
    my (@files) = @_;
    
    foreach $file (@_) {
        # file is not valid
        if (valid_file == 0) {
            print "legit.pl: error: invalid filename '$file'\n";
            exit 1;
        }
    
        # given --... as argument 
        if ($file =~ m/^--.+$/) {
            print "usage: legit.pl rm [--force] [--cached] <filenames>\n";
            exit 1;
        }
        
        # file not in repository
        if (!(-e ".legit/index/$file")) {
            print "legit.pl: error: '$file' is not in the legit repository";
            exit 1;
        }
        
        $last_commit = newest_commit - 1;
        
        # remove file current directory
        if ($cached == 0) {
            if (-e ".legit/commit_$last_commit" && forced == 0 && (cmp_files "$file", ".legit/commit_$last_commit") == 0) {
                print "legit.pl: error: '$file' in repository is different to working file\n";
                exit 1;
            }
            unlink $file; 
          
        # remove file from index
        } else {
            if (forced == 0 && (cmp_files ".legit/index/$file", ".legit/commit_$last_commit") == 0) {
                print "legit.pl: error: '$file' has changes staged in the index\n";
                exit 1;
            }
            unlink ".legit/index/$file";    
        }   
    }
}

# commit files to repository
sub copy_files {
    my ($message) = shift @_;
    my ($flag) = shift @_;
    # no changes to index
    if (!(-e ".legit/index/.y") && $flag ne "-a") {
        print "Nothing to commit\n";
    
    # commit new/changed files
    } else { 
        my $new_commit=newest_commit;

        my $fileChanged = 0;
        if ($flag eq "-a") {
            # commit -a:  add all files in current directory to index if an older version of that file is already in the index
            foreach $file (glob ".legit/index/*") {
                $file =~ s/\.legit\/index\///g; 
                next if (!(-e $file));  
                
                # ignore unchanged files
                my $identical = cmp_files ".legit/index/$file", "$file"; 
                next if ($fileChanged == 0 && $identical == 1); 
                 
                # add file to index 
                $fileChanged = 1;
                add_to_dest $file, ".legit/index/$file";
            }
            
            # no files changed => nothing to commit        
            if ($fileChanged == 0 && !(-e ".legit/index/.y")) {
                print "Nothing to commit\n";
                return;
            }
        }


        mkdir ".legit/commit_$new_commit";
        
        # copy files from index to new commit
        foreach my $oldFile (glob ".legit/index/*") {
            next if ($oldFile eq ".legit/index/.y" || $oldFile eq ".legit/index/.n");
            $oldName = $oldFile;
            $oldName =~ s/\.legit\/index\///g;
            add_to_dest $oldFile, ".legit/commit_$new_commit/$oldName"; 
        }
        
        print "Committed as commit $new_commit\n";
        rename ".legit/index/.y", ".legit/index/.n";


        # write commit message to log
        open OLD_LOG, '<', ".legit/log.txt";
        open NEW_LOG, '>', ".legit/log1.txt";
        print NEW_LOG "$new_commit $message\n";
        print NEW_LOG <OLD_LOG>;
        close NEW_LOG;
        close OLD_LOG;
        rename ".legit/log1.txt", ".legit/log.txt";
    }
}


$command = shift @ARGV;

# invalid command
if (!(defined $command)) {
    print_commands;
}

# initiate legit repository
elsif ($command eq "init") {
    # invalid extra arguments 
    if (defined (shift @ARGV)) {
        print "usage: legit.pl init\n";
        exit 1;
    }
    
    if (-e ".legit") {
        print STDERR "legit.pl: error: .legit already exists\n";
        exit 1;
    
    # initialize files in .legit repository    
    } else {
        mkdir ".legit";
        mkdir ".legit/index";
        print "Initialized empty legit repository in .legit\n";
        
        # create log file txt 
        open F, '>', ".legit/log.txt";
        close F;
        
        # indication to whether files have been changed (n=no, y=yes)
        mkdir ".legit/index/.n";  
    }
}

# using legit without legit initiated 
elsif (!(-e ".legit") && $command ne "init") {
    print STDERR "legit.pl: error: no .legit directory containing legit repository exists\n";
    exit 1;
}

# add files to the index 
elsif ($command eq "add") {
    foreach $file (@ARGV) {
        # file is not in current repository
        if (!(-e $file)) {
            print STDERR "legit.pl: error: can not open '$file'";
            exit 1;
        }
        
        # file is not valid
        if (valid_file == 0) {
            print "legit.pl: error: invalid filename '$file'\n";
            exit 1;
        }
        
        add_to_dest $file, ".legit/index/$file";
        rename ".legit/index/.n", ".legit/index/.y" if (-e ".legit/index/.n");
    }
}

# adds files in the index to the "repository"
elsif ($command eq "commit") {
    $flag = shift @ARGV;
    $m = shift @ARGV;

    if (defined $flag && $flag eq "-m" && defined $m) {
        # commit -m -a  or  invalid extra arguments  or empty message
        if ($m eq "-a" || defined (shift @ARGV) || $m eq "") {
            print "usage: legit.pl commit [-a] -m commit-message\n";
            exit 1;
 
        # commit -m "message"
        } else {
            copy_files $m, "-m";
        }
        
    # commit -a -m "message"
    } elsif (defined $flag && $flag eq "-a" && defined $m && $m eq "-m" && defined ($message = shift @ARGV)) {
        # invalid extra arguments  or  empty message
        if (defined (shift @ARGV) || $message eq "") {
            print "usage: legit.pl commit [-a] -m commit-message\n";
            exit 1;
        }
        copy_files $message, "-a";

    # invalid extra arguments for commit -m"message"
    } elsif (defined $flag && $flag =~ m/-m(.+)/ && defined $m) {
        print "usage: legit.pl commit [-a] -m commit-message\n";
        exit 1;
   
    # commit with no separation between -m and message
    } elsif (defined $flag && (($flag eq "-a" && defined $m && $m =~ m/-m(.+)/) || $flag =~ m/-m(.+)/)) {
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

# prints all commits (commit-number commit-message)
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

# prints contents of specified file as of the specified commit
elsif ($command eq "show") {
    $cf = shift @ARGV;
   
    # split ':'

    # no commits
    if (!(-e ".legit/commit_0")) {
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
        exit 1;
    }
    
    if (defined $cf && $cf =~ m/.*:(.+)/) {
        # file is not valid
        if (valid_file $1 == 0) {
            print "legit.pl: error: invalid filename '$1'\n";
            exit 1;
        }   
    }
    
    # show commit:fileName 
    if (defined $cf && $cf =~ m/^(\d+):([A-Za-z0-9]{1}[A-Za-z0-9_\.\-]*)$/) {
        # commit doesnt exist
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
        if (!(-e ".legit/index/$1")) {
            print STDERR "legit.pl: error: '$1' not found in index\n";
            exit 1;
        }
        open F, '<', ".legit/index/$1";
        print <F>;
        close F;
    
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

} elsif ($command eq "rm") {
    # no commits
    if (!(-e ".legit/commit_0")) {
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
        exit 1;
    }
    
    $arg = shift @ARGV;
    
    # rm fileNames
    if ($arg ne "--force" && $arg ne "--cached") {
        rm_files 0, 0, @ARGV; 
    
    } elsif ($arg eq "--force") {
        $nextArg = shift @ARGV;
        # rm --forced --cached fileNames
        if ($arg eq "--cached") {
            rm_files 1, 1, @ARGV;
        
        # rm --forced fileNames
        } else {
            rm_files 1, 0, @ARGV;
        }
    
    } elsif ($arg eq "--cached") {
        rm_files 1, 0, @ARGV;   
    
    } else {
        
    }
    
} elsif ($command eq "status" || $command eq "branch" || $command eq "checkout" || $command eq "merge") {  

# invalid command
} else {
    print_commands;
}
