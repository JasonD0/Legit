#!/usr/bin/perl -w 

use File::Compare;
use File::Copy;

sub my_exit;
sub print_commands;
sub valid_file;
sub newest_commit;
sub write_log;
sub print_log;
sub init_sub_dir;
sub init_repo_files;
sub check_add_file_errors;
sub add_files;
sub check_commit_input_errors;
sub read_commit_flags;
sub commit_files;
sub read_rm_flags;
sub check_rm_file_errors;
sub check_removable;
sub rm_files;
sub check_show_input_errors;
sub show_commit_file;
sub print_file_statuses;
sub update_file_status;
sub read_status;

%file_status = ();
$DIFF_CHANGES = "file changed, different changes staged for commit";
$NOT_STAGED = "file changed, changes not staged for commit";
$STAGED = "file changed, changes staged for commit";

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


# write commit message to log
sub write_log {
    my ($new_commit) = shift @_;
    my ($message) = shift @_;
    open my $OLD_LOG, '<', ".legit/log.txt";
    open my $NEW_LOG, '>', ".legit/log1.txt";
    print {$NEW_LOG} "$new_commit $message\n";
    print {$NEW_LOG} <$OLD_LOG>;
    close $NEW_LOG;
    close $OLD_LOG;
    rename ".legit/log1.txt", ".legit/log.txt";
}

# prints all commits 
sub print_log {
    open my $F, '<', ".legit/log.txt";
    print <$F>;
    close $F;
}

# create the initial sub directories for the repository
sub init_sub_dir {
    mkdir ".legit";
    mkdir ".legit/index";
    print "Initialized empty legit repository in .legit\n";
    # indicates if there is something to commit
    mkdir ".legit/index/.n";  
}

# create the initial text files for the repository 
sub init_repo_files {
    # create log file txt 
    open my $F, '>', ".legit/log.txt";
    close $F;

    # create status text
    open $G, '>', ".legit/status.txt";
    foreach my $file (glob "*") {
        next if (-d $file);
        print {$G} "$file - untracked\n";
    }
    close $G;
}

# checks validity of files given with the command add
sub check_add_file_errors {
    my ($file) = shift @_;
    
    # file is not in current repository and not in the index
    if (!(-e $file) && !(-e ".legit/index/$file")) {
        print STDERR "legit.pl: error: can not open '$file'\n";
        my_exit;
    }
    
    # file is not valid
    if ((valid_file $file) == 0) {
        print STDERR "legit.pl: error: invalid filename '$file'\n";
        my_exit;
    }
    
    # file removed from current directory but in index
    if (!(-e $file) && -e ".legit/index/$file") {
        rename ".legit/index/.n", ".legit/index/.y" if (-e ".legit/index/.n");
    }
}

# add files to the index 
sub add_files {
    my (@files) = @_;
    my $fileChanged = 0;
    
    foreach my $file (@files) {
        check_add_file_errors $file;
        
        # ignore unchanged files
        next if (-e ".legit/index/$file" && !($file_status{$file} eq "$NOT_STAGED"));
        
        # add file to index 
        $fileChanged = 1;
        copy($file, ".legit/index/$file");
        
        # change file status
        $file_status{$file} = "added to index" if ($file_status{$file} eq "untracked");       # init -> add 
        $file_status{$file} = "$STAGED" if ($file_status{$file} eq "$NOT_STAGED");
    }
    rename ".legit/index/.n", ".legit/index/.y" if (-e ".legit/index/.n" && $fileChanged == 1);
}

# checks valid arguments given with the command commit
sub check_commit_input_errors {
    my ($message) = shift @_;
    my (@args) = @_;
    
    # invalid extra arguments  or  empty message  or message starts with '-'
    if (defined (shift @args) || $message eq "" || $message =~ /^-/) {
        print STDERR "usage: legit.pl commit [-a] -m commit-message\n";
        my_exit;
    }
}

# interpret flags given with the command commit
sub read_commit_flags {
    my (@args) = @_;
    my $flag = shift @args;
    my $arg = shift @args;
    
    # commit -m "message"
    if (defined $flag && $flag eq "-m" && defined $arg) {
        check_commit_input_errors $arg, @args;        
        commit_files $arg, "-m";
        
    # commit -a -m "message"
    } elsif (defined $flag && $flag eq "-a" && defined $arg && $arg eq "-m" && defined ($message = shift @args)) {
        check_commit_input_errors $message, @args;    
        commit_files $message, "-a";
   
    # commit [-a] -m"message"
    } elsif (defined $flag && (($flag eq "-a" && defined $arg && $arg =~ m/-m(.+)/) || $flag =~ m/-m(.+)/)) {
        check_commit_input_errors $1, @args;
        commit_files $1, "-a" if ($flag eq "-a");
        commit_files $1, "-m" if ($flag ne "-a");
   
    # incorrect commit syntax
    } else {
        print STDERR "usage: legit.pl commit [-a] -m commit-message\n";
        my_exit;
    }
}

# commit files to repository
sub commit_files {
    my ($message) = shift @_;
    my ($flag) = shift @_;
    chomp $message;
    
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
                next if (!(-e $file) || !($file_status{$file} eq "$NOT_STAGED"));  
                 
                # add file to index 
                $fileChanged = 1;
                copy($file, ".legit/index/$file");
                
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
            $file_status{$oldFile} = "same as repo" if ($file_status{$oldFile} eq "added to index" || $file_status{$oldFile} eq "$STAGED");    
            # index file different to repository file and current  =>  changes in index
            $file_status{$oldFile} = "$NOT_STAGED" if ($file_status{$oldFile} eq "$DIFF_CHANGES");   
            
            my $oldName = $oldFile;
            $oldName =~ s/\.legit\/index\///g;
            copy(".legit/index/$oldFile", ".legit/commit_$new_commit/$oldName"); 
        }
        
        print "Committed as commit $new_commit\n";
        rename ".legit/index/.y", ".legit/index/.n";

        write_log $new_commit, $message;
        
        # remove deleted files from status
        foreach my $file (keys %file_status) {
            $file_status{$file} = "" if ($file_status{$file} eq "deleted");      
        }
    }
}

# rm files based on flags given with the command rm
sub read_rm_flags {
    my (@args) = @_;
    my $arg = shift @args;    

    # rm fileNames
    if ($arg ne "--force" && $arg ne "--cached") {
        # arg is not a flag, put back into array (of files)
        unshift @args, $arg;
        rm_files 0, 0, @args; 
    
    } else {
        my $nextArg = shift @args;
        
        # rm with both --cached and --force flags
        if (($arg eq "--force" && $nextArg eq "--cached") || ($arg eq "--cached" && $nextArg eq "--force")) {
            rm_files 1, 1, @args;
        
        # rm with only one flag
        } else {
            unshift @args, $nextArg; 
            rm_files 1, 0, @args if ($arg eq "--force");
            rm_files 0, 1, @args if ($arg eq "--cached");
        }
        
        # rm --force/cached   no files 
    }
}

# checks validity of files given with the command rm
sub check_rm_file_errors {
    my ($file) = shift @_;

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
}

# checks if files can be removed from either/both the current directory and the index
sub check_removable {
    my ($file) = shift @_;
    my ($forced) = shift @_;
    my ($cached) = shift @_;
    
    my $last_commit = newest_commit;
    $last_commit--;

    # file in index is different to both current directory and in repository
    if ($forced == 0 && $file_status{$file} eq "$DIFF_CHANGES") {
        print STDERR "legit.pl: error: '$file' in index is different to both working file and repository\n";
        my_exit;
    }
    
    if ($forced == 0 && $cached == 0) {
        # file has changed in index since last commit
        if ($file_status{$file} eq "$STAGED" || $file_status{$file} eq "added to index") {
            print STDERR "legit.pl: error: '$file' has changes staged in the index\n";
            my_exit;
        }

        # file not in last commit  or  file has changed in current directory since last commit
        if (!(-e ".legit/commit_$last_commit/$file") || $file_status{$file} eq "$NOT_STAGED") {
            print STDERR "legit.pl: error: '$file' in repository is different to working file\n";
            my_exit;
        }
    }
}

# removes files from current directory  or  current directory and the index
sub rm_files {
    my ($forced) = shift @_;
    my ($cached) = shift @_;
    my (@files) = @_;
    
    foreach my $file (@files) {
        check_rm_file_errors $file;        
        check_removable $file, $forced, $cached;        
        
        # change file status
        $file_status{$file} = "untracked";  
        unlink ".legit/index/$file";    
        rename ".legit/index/.n", ".legit/index/.y" if (-e ".legit/index/.n");

        # remove file from current directory        
        if ($cached == 0) {
            # change file status
            $file_status{$file} = "deleted";
            $file_status{$file} = "" if ($forced == 1);
            unlink $file; 
        }   
    }
}

# checks validity of commits/files given with the command show
sub check_show_input_errors {
    my (@args) = @_;
    
    # no arguments or too many arguments
    if (@args != 1) {
        print STDERR "usage: legit.pl show <commit>:<filename>\n";
        my_exit;
    }
    
    # singular word argument 
    if (!($args[0] =~ /:/)) {
        print STDERR "legit.pl: error: invalid object $args[0]\n";    
        my_exit;
    }
    
    my ($commit, $file) = split ':', $args[0];
    
    # show :fileName but fileName not in the index
    if ($commit eq "" && !(-e ".legit/index/$file")) {
        print STDERR "legit.pl: error: '$file' not found in index\n";
        my_exit;
    }
    
    # not valid commit
    if ($commit ne "" && !(-e ".legit/commit_$commit")) {
        print STDERR "legit.pl: error: unknown commit '$commit'\n";
        my_exit;
    }

    # not valid file 
    if ($file eq "" || (valid_file $file) == 0) {
        print STDERR "legit.pl: error: invalid filename '$file'\n";
        my_exit;
    }
    
    # file doesnt exist in the commit
    if ($commit ne "" && !(-e ".legit/commit_$commit/$file")) {
        print STDERR "legit.pl: error: '$file' not found in commit $commit\n";
        my_exit;
    }
}

# show file contents in the specified commit
sub show_commit_file {
    my (@args) = @_;
    my ($commit, $file) = split ':', $args[0];
    
    # show :fileName 
    if ($commit eq "") {
        check_show_input_errors @args;
        open my $F, '<', ".legit/index/$file";
        print <$F>;
        close $F;
        
    # show commit:fileName 
    } else {
        check_show_input_errors @args;
        open my $G, '<', ".legit/commit_$commit/$file";
        print <$G>;
        close $G;
    }
}

# prints current status of all files in the current directory
sub print_file_statuses {
    foreach my $file (sort keys %file_status) {
    	print "$file - $file_status{$file}\n";
    }
}

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
	 
	    # file is different to the file in the index  =>  $NOT_STAGED  or  same as repo
        } elsif (compare($file, ".legit/index/$file") == 1) {
            $file_status{$file} = "$NOT_STAGED" if (!($file_status{$file} eq "$STAGED" || $file_status{$file} eq "$DIFF_CHANGES"));
            $file_status{$file} = "$DIFF_CHANGES" if ($file_status{$file} eq "$STAGED");

            # file in current directory is also the same as the file in the repository
            if (-e ".legit/commit_$last_commit/$file" && compare($file, ".legit/commit_$last_commit/$file") == 0) {
                $file_status{$file} = "same as repo" if ($file_status{$file} ne "$DIFF_CHANGES");
            }
        }
    }    

    # check for files that have been deleted in current repository    
    foreach $file (glob ".legit/index/*") {
        $file =~ s/\.legit\/index\///g;
        if (!(-e $file)) {
            $file_status{$file} = "file deleted";
            #rename ".legit/index/.n", ".legit/index/.y" if (-e ".legit/index/.n");  cant commit if rm file from current directory 
        }
    }
}




# get command 
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
    } 
    
    # create the repository
    init_sub_dir;
    init_repo_files;
}

# using legit without legit initiated 
elsif (!(-e ".legit") && $command ne "init") {
    print STDERR "legit.pl: error: no .legit directory containing legit repository exists\n";
    my_exit;
}

# add files to the index
elsif ($command eq "add") {
    read_status;    
    add_files @ARGV;
    update_file_status;
}

# adds files in the index to the repository
elsif ($command eq "commit") {
    read_status;
    read_commit_flags @ARGV;
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
    }
            
    # show log file
    print_log;
}

# prints contents of specified file as of the specified commit
elsif ($command eq "show") {
    # no commits
    if (!(-e ".legit/commit_0")) {
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
        my_exit;
    }
    check_show_input_errors @ARGV;
    show_commit_file @ARGV;    

} elsif ($command eq "rm") {
    # no commits
    if (!(-e ".legit/commit_0")) {
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
        my_exit;
    }
    read_status;
    read_rm_flags @ARGV;
    update_file_status;

} elsif ($command eq "status") {
    # no commits
    if (!(-e ".legit/commit_0")) {
        print STDERR "legit.pl: error: your repository does not have any commits yet\n";
        my_exit;
    }
    read_status;
    print_file_statuses;   
    update_file_status;

} elsif ($command eq "branch" || $command eq "checkout" || $command eq "merge") {  

# invalid command
} else {
    print_commands;
}
