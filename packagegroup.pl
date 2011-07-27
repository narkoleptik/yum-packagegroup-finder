#!/usr/bin/perl
# Author: Brad McDuffie <bmcduffi@redhat.com>
# Wed Jul 27 08:24:09 EDT 2011
# Perl script to query yum repositories for package groups and show which
# packages are included in each group.
#
# Description:
# This script lists out all of the packagegroups installed on a particular
# system, and can show which packages are in those groups.  In addition
# to the package list, it also includes a description of each package
# 

# Setup some variables
$packagegroup = "";
@installed = ();
@language = ();
@available = ();

$cmd = "yum grouplist";
open(CMD, "$cmd 2>&1 |") or die "cmd $cmd failed with: $1";
while(<CMD>)
{
	chomp();
	$_ =~ s/^\s+//;
	# parse the command stuff here
	if (/^Installed Groups:/) {
		$packagegroup = "installed";
	}
	elsif (/^Installed Language Groups:/) {
		# We don't care about language groups
		$packagegroup = "language";
	}
	elsif (/^Available Groups:/) {
		$packagegroup = "available";
	}
	elsif (/^Available Language Groups:/) {
		# We don't care about language groups
		$packagegroup = "language";
	}
	else {
		if ($packagegroup eq "installed") {
			push (@installed, "$_");
		}
		# If you also wanted to do available package groups, this will
		# push them into an array
		elsif ($packagegroup eq "available") {
			push (@available, "$_");
		}
	}
}
close(CMD);

# Setup some variables for our next loop.  Yes, this should probably be
# at the top and declared with the others.
@installeddefaultpackages = ();
@installedoptionalpackages = ();
# Clear out the $packagegroup (reuse of variables is good, no?)
$packagegroup = "";

# This just loops through all of the installed package groups and then
# does a groupinfo on them. After that, it loops through all of the packages
# included in each group and puts a description beside them.
####
## Known Bug: on RHEL6, it prints out "Summary" on a line by itself after 
##            each printed description.  I don't know why... yet.
###
for $group (@installed) {
	print "$group\n";
	$cmd = "yum groupinfo \"$group\"";
	open(CMD, "$cmd 2>&1 |") or die "cmd $cmd failed with: $1";
	while(<CMD>) {
		chomp();
		if ((/^ Mandatory/) || (/^ Default/)) {
			print "\tMandatory and Default Packages\n";
			$packagegroup = "default";
		}
		elsif (/^ Optional/) {
			print "\tOptional Packages\n";
			$packagegroup = "optional";
		}
		elsif (/^Loaded plugins:/) {
			$packagegroup = "done";
		}
		else {
			$_ =~ s/^\s+//;
			if ($packagegroup eq "default") {
				@summary = split(/:/, `yum info $_ | grep "^Summary"`);
				chomp($summary[1]);
				print "\t\t$_ - $summary[1]\n";
			}
			elsif ($packagegroup eq "optional") {
				@summary = split(/:/, `yum info $_ | grep "^Summary"`);
				chomp($summary[1]);
				print "\t\t$_ - $summary[1]\n";
			}
		}
	}
	close(CMD);
}

######################################################################
# Things below here are just some snipits of code that do some things
# that are intersting and may be added later.
######################################################################
#my %unique = ();
#foreach my $item (@installeddefaultpackages)
#{
#    $unique{$item} ++;
#}
#my @installeddefaultpackages = keys %unique;
#
#for $pkg (@installeddefaultpackages) {
#	print "$pkg\n";
#}
#
##print "Installed Packages\n";
##print "\@installeddefaultpackages = " . scalar(@installeddefaultpackages) . "\n";
##print "\@installedoptionalpackages = " . scalar(@installedoptionalpackages) . "\n";
######
#
