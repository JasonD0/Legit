#!/usr/bin/perl -w 

sub rm_files;
sub cmp_files;
sub update_file_status;
sub read_status;
sub my_exit;
sub print_commands;
sub valid_file;
sub add_to_dest;
sub newest_commit;
sub copy_files;

%file_status = ();

# update file statuses in the current directory
sub update_file_status {    
    open my $F, '>', ".legit/status.txt";
    
    # write file and it's status into the status file
    foreach my $file (keys %file_status) {
        next if ($file_status{$file} eq "");   
        print {$F} "$file - $file_status{$file}\n";
    }
    
    close $F;
}

# get latest file statuses in the current directory
sub read_status {
    # map file and it's status as a hash
    open my $F, '<', ".legit/status.txt";
    
    foreach my $line (<$F>) {
        $file_status{$1} = $2 if ($line =~ m/^(.*?) - (.*)/);
    }
    
    close $F;

    my $last_commit = newest_commit;
    $last_commit--;
    
    # check for changes in current repository and change the file statuses
    foreach my $file (glob "*") {
	    next if (-d $file);
	    # file doesnt exit or is untracked  =>  untracked
	    if (!(defined $file_status{$file}) || $file_status{$file} eq "untracked") {
        	$file_status{$file} = "untracked";
	 
	    # file is different to the file in the index  =>  changes in index  or  same as repo
        } elsif ((cmp_files $file, ".legit/index/$file") == 0) {
            $file_status{$file} = "changes in index" if (!($file_status{$file} =~ "file modified"));
            $file_status{$file} .= " and changes in index" if ($file_status{$file} eq "file modified");

            # file in current directory is also the same as the file in the repository
            if (-e ".legit/commit_$last_commit/$file" && (cmp_files $file, ".legit/commit_$last_commit/$file") == 1) {
                $file_status{$file} = "same as repo" if ($file_status{$file} ne "file modified and changes in index");
            }
        }
    }    

    # check for files that have been deleted in current repository    
    foreach $file (glob ".legit/index/*") {
        $file =~ s/\.legit\/index\///g;
        if (!(-e $file)) {
            $file_status{$file} = "file deleted";
            rename ".legit/index/.n", ".legit/index/.y" if (-e ".legit/index/.n");
        }
    }
}

sub my_exit {
    update_file_status;
    exit 1;
}

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
# and only contain alpha-numeric characters plus '.', '-' and '_' characters.
sub valid_file {
    my ($fileName) = shift @_;
    return 0 if (!($fileName =~ m/^[A-Za-z0-9]{1}/) || ($fileName =~ s/[A-Za-z0-9\.\-\_]//g && $fileName ne ""));
    return 1;
}

# add file to given destination
sub add_to_dest {
    my ($src) = shift @_;
    my ($dest) = shift @_;
    
    open my $F, '<', $src;
    open my $C, '>', $dest;
    
    print {$C} <$F>;
    
    close $C;
    close $F;
}

# checks if files identical
sub cmp_files {
    my ($file1) = shift @_;
    my ($file2) = shift @_;
    
    open my $F1, '<', $file1;
    open my $F2, '<', $file2;
    
    my @f1 = <$F1>;
    my @f2 = <$F2>;

    close $F1;
    close $F2;


    return 0 if (@f1 != @f2);
    
    while (@f1 != 0) {
        return 0 if ((shift @f1) ne (shift @f2));
        return 0 if (@f1 != 0 && (pop @f1) ne (pop @f2));
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
    
    foreach my $file (@files) {
    
        # given --... as argument 
        if ($file =~ m/^--.+$/) {
            print "usage: legit.pl rm [--force] [--cached] <filenames>\n";
            my_exit;
        }
        
        # file is not valid
        if ((valid_file $file) == 0) {
            print "legit.pl: error: invalid filename '$file'\n";
            my_exit;
        }
        
        # file not in repository
        if (!(-e ".legit/index/$file")) {
            print STDERR "legit.pl: error: '$file' is not in the legit repository\n";
            my_exit;
        }
        
        my $last_commit = newest_commit;
        $last_commit--;
        
        # file in index is different to both current directory and in repository
        if ($forced == 0 && $file_status{$file} eq "file modified and changes in index") {
            print STDERR "legit.pl: error: '$file' in index is different to both working file and repository\n";
            my_exit;
        }
        
        if ($forced == 0 && $cached == 0) {
            # file has changed in index since last commit
            if ($file_status{$file} eq "file modified" || $file_status{$file} eq "added to index") {
                print STDERR "legit.pl: error: '$file' has changes staged in the index\n";
                my_exit;
            }

            # file not in last commit  or  file has changed in current directory since last commit
            if (!(-e ".legit/commit_$last_commit/$file") || $file_status{$file} =~ /changes in index/) {
                print STDERR "legit.pl: error: '$file' in repository is different to working file\n";
                my_exit;
            }
        }
        
        # change file status
        $file_status{$file} = "untracked";  
        unlink ".legit/index/$file";    
        rename ".legit/index/.n", ".legit/index/.y" if (-e ".legit/index/.n");

        # remove file from current directory        
        if ($cached == 0) {
            # change file status
            $file_status{$file} = "deleted"; 
            unlink $file; 
        }   
    }
}

# commit files to repository
sub copy_files {
    my ($message) = shift @_;
    my ($flag) = shift @_;
    
    # no changes to index
    if (!(-e ".legit/index/.y") && $flag ne "-a") {
        print "nothing to commit\n";
    
    # commit new/changed files
    } else { 
        my $new_commit=newest_commit;

        my $fileChanged = 0;
        if ($flag eq "-a") {
            # commit -a:  add all files in current directory to index if an older version of that file is already in the index
            foreach my $file (glob ".legit/index/*") {
                $file =~ s/\.legit\/index\///g; 
                # ignore files that doesnt exist and unchanged files
                next if (!(-e $file) || !($file_status{$file} =~ /changes in index/));  
                 
                # add file to index 
                $fileChanged = 1;
                add_to_dest $file, ".legit/index/$file";
                
                # change file status
                $file_status{$file} = "same as repo";   
            }
            
            # no files changed => nothing to commit        
            if ($fileChanged == 0 && !(-e ".legit/index/.y")) {
                print "nothing to commit\n";
                return;
            }
        }

        mkdir ".legit/commit_$new_commit";
        
        # copy files from index to new commit
        foreach my $oldFile (glob ".legit/index/*") {
            next if ($oldFile eq ".legit/index/.y" || $oldFile eq ".legit/index/.n");
            $oldFile =~ s/\.legit\/index\///g;
            
            # change file status
            # uncommited files  =>  same as repo
            $file_status{$oldFile} = "same as repo" if ($file_status{$oldFile} eq "added to index" || $file_status{$oldFile} eq "file modified");    
            # index file different to repository file and current  =>  changes in index
            $file_status{$oldFile} = "changes in index" if ($file_status{$oldFile} eq "file modified and changes in index");   
            
            my $oldName = $oldFile;
            $oldName =~ s/\.legit\/index\///g;
            add_to_dest ".legit/index/$oldFile", ".legit/commit_$new_commit/$oldName"; 
        }
        
        print "Committed as commit $new_commit\n";
        rename ".legit/index/.y", ".legit/index/.n";


        # write commit message to log
        open my $OLD_LOG, '<', ".legit/log.txt";
        open my $NEW_LOG, '>', ".legit/log1.txt";
        print {$NEW_LOG} "$new_commit $message\n";
        print {$NEW_LOG} <$OLD_LOG>;
        close $NEW_LOG;
        close $OLD_LOG;
        rename ".legit/log1.txt", ".legit/log.txt";
        
        # remove deleted files from status
        foreach my $file (keys %file_status) {
            $file_status{$file} = "" if ($file_status{$file} eq "deleted");      
        }
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
        print STDERR "usage: legit.pl init\n";
        my_exit;
    }
    
    if (-e ".legit") {
        print STDERR "legit.pl: error: .legit already exists\n";
        my_exit;
    
    # initialize files in .legit repository    
    } else {
        mkdir ".legit";
        mkdir ".legit/index";
        print "Initialized empty legit repository in .legit\n";
        
        # create log file txt 
        open F, '>', ".legit/log.txt";
        close F;
 
        # create status text
        open F, '>', ".legit/status.txt";
        foreach $file (glob "*") {
            next if (-d $file);
            print F "$file - untracked\n";
        }
        close F;
        
        # indicates if there is something to commit
        mkdir ".legit/index/.n";  
    }
}

# using legit without legit initiated 
elsif (!(-e ".legit") && $command ne "init") {
    print STDERR "legit.pl: error: no .legit directory containing legit repository exists\n";
    my_exit;
}

# add files to the index 
elsif ($command eq "add") {
    read_status;    
    $fileChanged = 0;
    foreach $file (@ARGV) {
        # file is not in current repository
        if (!(-e $file)) {
            print STDERR "legit.pl: error: can not open '$file'\n";
            my_exit;
        }
        
        # file is not valid
        if ((valid_file $file) == 0) {
            print STDERR "legit.pl: error: invalid filename '$file'\n";
            my_exit;
        }
        
        # ignore unchanged files
        next if (-e ".legit/index/$file" && !($file_status{$file} =~ /changes in index/));
        
        read_status if ($fileChanged == 0);
        
        # add file to index 
        $fileChanged = 1;
        add_to_dest $file, ".legit/index/$file";
        
        # files have changed and added 
        $file_status{$file} = "added to index" if ($file_status{$file} eq "untracked");       # init -> add 
        $file_status{$file} = "file modified" if ($file_status{$file} eq "changes in index"); # init -> add -> commit -> change file -> add      
    }
    rename ".legit/index/.n", ".legit/index/.y" if (-e ".legit/index/.n" && $fileChanged == 1);
    update_file_status;
}

# adds files in the index to the "repository"
elsif ($command eq "commit") {
    read_status;
    $flag = shift @ARGV;
    $m = shift @ARGV;

    if (defined $flag && $flag eq "-m" && defined $m) {
        # commit -m -a  or  invalid extra arguments  or empty message
        if ($m =~ /^-/ || defined (shift @ARGV) || $m eq "") {
            print STDERR "usage: legit.pl commit [-a] -m commit-message\n";
            my_exit;
 
        # commit -m "message"
        } else {
            copy_files $m, "-m";
        }
        
    # commit -a -m "message"
    } elsif (defined $flag && $flag eq "-a" && defined $m && $m eq "-m" && defined ($message = shift @ARGV)) {
        # invalid extra arguments  or  empty message
        if (defined (shift @ARGV) || $message eq "") {
            print STDERR "usage: legit.pl commit [-a] -m commit-message\n";
            my_exit;
        }
        copy_files $message, "-a";

    # invalid extra arguments for commit -m"message"
    } elsif (defined $flag && $flag =~ m/-m(.+)/ && defined $m) {
        print STDERR "usage: legit.pl commit [-a] -m commit-message\n";
        my_exit;
   
    # commit with no separation between -m and message
    } elsif (defined $flag && (($flag eq "-a" && defined $m && $m =~ m/-m(.+)/) || $flag =~ m/-m(.+)/)) {
        # invalid extra arguments  or  empty message
        if (defined (shift @ARGV) || $1 eq "") {
            print STDERR "usage: legit.pl commit [-a] -m commit-message\n";
            my_exit;
        }
        $x = "-m";
        $x = $flag if ($flag eq "-a");
        copy_files $1, $x;
   
    # incorrect commit syntax
    } else {
        print STDERR "usage: legit.pl commit [-a] -m commit-message\n";
        my_exit;
    }
    update_file_status;
}

# prints all commits (commit-number commit-message)
elsif ($command eq "log") {
    # no commits
    if (!(-e ".legit/commit_0")) {
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
        my_exit;
    
    # invalid extra arguments
    } elsif (defined (shift @ARGV)) {
        print STDERR "usage: legit.pl log\n";
        my_exit;
        
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
        my_exit;
    }
    
    if (defined $cf && $cf =~ m/.*:(.+)/) {
        # file is not valid
        if ((valid_file $1) == 0) {
            print STDERR "legit.pl: error: invalid filename '$1'\n";
            my_exit;
        }   
    }
    
    # show commit:fileName 
    if (defined $cf && $cf =~ m/^(\d+):([A-Za-z0-9]{1}[A-Za-z0-9_\.\-]*)$/) {
        # commit doesnt exist
        if (!(-e ".legit/commit_$1")) {
            print STDERR "legit.pl: error: unknown commit '$1'\n";
            my_exit;
        }
        
        # file doesnt exist in commit
        if (!(-e ".legit/commit_$1/$2")) {
            print STDERR "legit.pl: error: '$2' not found in commit $1\n";
            my_exit;
        }
        
        open F, '<', ".legit/commit_$1/$2";
        print <F>;
        close F;
    
    # show :fileName 
    } elsif (defined $cf && $cf =~ m/^:([A-Za-z0-9]{1}[A-Za-z0-9_\.\-]*)$/) {
        if (!(-e ".legit/index/$1")) {
            print STDERR "legit.pl: error: '$1' not found in index\n";
            my_exit;
        }
        open F, '<', ".legit/index/$1";
        print <F>;
        close F;
    
    # commit doesnt exist or eg show : c 
    } elsif (defined $cf && $cf =~ m/^(.*):(.*)$/) {
        if (defined $2 && $2 eq "" && (!defined $1)) {
            print STDERR "usage: legit.pl <commit>:<filename>\n";
            my_exit;
        } 
        print STDERR "legit.pl: error: unknown commit '$1'\n";
        my_exit;
    
    # singular word argument not in form of commit:fileName
    } elsif (defined $cf && !($cf =~ m/^.*:.*$/) && !(defined (shift @ARGV))) {
       print STDERR "legit.pl: error: invalid object $cf\n";    
       my_exit;
   
    # argument is ':' 
    } elsif (defined $cf && $cf =~ m/^:$/) {
        print STDERR "legit.pl: error: invalid filename ''\n";
        my_exit;
    
    # no arguments or too many arguments
    } else {
        print STDERR "usage: legit.pl <commit>:<filename>\n";
        my_exit;
    }

} elsif ($command eq "rm") {
    # no commits
    if (!(-e ".legit/commit_0")) {
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
        my_exit;
    }
    read_status;
    
    $arg = shift @ARGV;
    
    # rm fileNames
    if ($arg ne "--force" && $arg ne "--cached") {
        # arg is not a flag, put back into array (of files)
        unshift @ARGV, $arg;
        rm_files 0, 0, @ARGV; 
    
    } elsif ($arg eq "--force") {
        $nextArg = shift @ARGV;
        # rm --forced --cached fileNames
        if ($nextArg eq "--cached") {
            rm_files 1, 1, @ARGV;
        
        # rm --forced fileNames
        } else {
            # nextArg is not another flag, put back into array (of files)
            unshift @ARGV, $nextArg; 
            rm_files 1, 0, @ARGV; 
        }
    
    } elsif ($arg eq "--cached") {
        rm_files 0, 1, @ARGV;   
    
    } else {
        print STDERR "legit.pl: error: '$arg' is not in the legit repository\n";
        my_exit;
    }
    update_file_status;

} elsif ($command eq "status") {
    # no commits
    if (!(-e ".legit/commit_0")) {
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
        my_exit;
    }
    read_status;
    
    foreach $file (sort keys %file_status) {
    	print "$file - $file_status{$file}\n";
    }
    
    update_file_status;

} elsif ($command eq "branch" || $command eq "checkout" || $command eq "merge") {  

# invalid command
} else {
    print_commands;
}
