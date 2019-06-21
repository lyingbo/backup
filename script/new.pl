#!/usr/bin/perl -w

# -*- perl -*-
#
# $Id: new.pl  2013-03-07 10:49:56 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2013-03-07 10:49:56
#    Description : Generate file head automatically
#************************************************************************

use strict;

my $ScpName = "run_test.pl";
my $ScpType = 0;
if(@ARGV > 0) {
    $ScpName = $ARGV[0];
    my $list = substr($ARGV[0], length($ARGV[0])-3);
    $ScpType = 1 if(".sh" eq $list);
}

open(FILE, ">$ScpName") || die("Can't create the file $ScpName !\n");

my ($sec,$min,$hour,$day,$mon,$year) = localtime(time);
    $year += 1900;$mon += 1;
my $CurTime = "$year-";
    $CurTime .= "0" if($mon<10);
    $CurTime .= "$mon-";
    $CurTime .= "0" if($day<10);
    $CurTime .= "$day ";
    $CurTime .= "0" if($hour<10);
    $CurTime .= "$hour:";
    $CurTime .= "0" if($min<10);
    $CurTime .= "$min:";
    $CurTime .= "0" if($sec<10);
    $CurTime .= "$sec";

my $head = "#!/usr/bin/perl -w\n\n# -*- perl -*-\n#\n";
   $head = "#!/bin/bash\n\n# -*- shell -*-\n#\n" if($ScpType eq 1);
   
my $id   = "# \$Id: $ScpName  $CurTime \$\n";

my $mark = "#************************************************************************\n";
my $auth = "NoName <lyingbo\@aliyun.com>";

my $code = "
use strict;

die(\"\\nUsage: \$0 [param]\\n\") unless \@ARGV > 0;

open(FILE,\"\>\$ARGV[0]\") || die(\"Can't open the file \$ARGV[0] !\\n\");

close(FILE);
";
   $code = "
if [ \$# -le 1 ]; then
    echo \"\\nUsage: \$0 [param]\\n\";
    exit 0;
fi
" if($ScpType eq 1);

my $cout = $head.$id.$mark."#    Author      : $auth\n";
    $cout .= "#    Date        : $CurTime\n";
    $cout .= "#    Description : \n";
    $cout .= "$mark";
    $cout .= "$code\n";

print FILE $cout;

close(FILE);

print "\nCreate $ScpName success !\n"
