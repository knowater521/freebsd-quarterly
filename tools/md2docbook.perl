#!/usr/bin/env perl
#
# SPDX-License-Identfier: BSD-2-Clause-FreeBSD
#
# Copyright (c) 2020 Lorenzo Salvadore
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

use strict;
use warnings;

my $INTRODUCTION =	0b1;
my $PROJECT = 		0b10;
my $UL =		0b100;

my $flags = $INTRODUCTION;

my %CATEGORIES = (
	"# FreeBSD Team Reports #\n" => "team",
	"# Projects #\n" => "proj",
	"# Userland Programs #\n" => "bin",
	"# Kernel Projects #\n" => "kern",
	"# Architectures #\n" => "arch",
	"# Documentation #\n" => "doc",
	"# Ports #\n" => "ports",
	"# Third-Party Projects #\n" => "third",
	"# Miscellaneous #\n" => "misc" );
my $current_category;

open(report_template, '<', "report-template.xml") or
die "Could not open report-template.xml: $!";

foreach(1..28)
{
	my $line = <report_template>;
	print $line;
}
while(<>)
{
	next if($_ eq "\n");
	$_ =~ s,\[(.*)\](\(.*://.*\)),<a href='$2'>$1</a>,g;
	if(exists $CATEGORIES{$_})
	{
		if($flags & $INTRODUCTION)
		{
			<report_template> foreach (29..49);
			foreach(50..134)
			{
				my $line = <report_template>;
				print $line;
			}
			$flags = $flags & ~ $INTRODUCTION;
			$current_category = $CATEGORIES{$_};
		}
	}
	elsif($_ =~ m/^###.*###/)
	{
		$_ =~ s/### | ###|\n//g; 
		print <<"EOT";
<h3>$_</h3>
EOT
	}
	elsif($_ =~ m/^##.*##/)
	{
		if($flags & $UL)
		{
			print "</li></ul>\n";
			$flags = $flags & ~ $UL;
		}
		print "</project>\n" if($flags & $PROJECT);
		$_ =~ s/## | ##|\n//g; 
		print <<"EOT";
<project cat='$current_category'>
<title>$_</title>
EOT
		$flags = $flags | $PROJECT;
	}
	elsif($_ =~ m/^Contact: .*@.*/)
	{
		$_ =~ m-Contact:([^,]*)[ ,]*<(.*)>-;
		my $name = $1;
		my $email = $2;
		$name =~ s/^ *| *$//g;
		print <<"EOT";
<contact><person>
<name>$name</name>
<email>$email</email>
</person></contact>
EOT
	}
	elsif($_ =~ s/^[-\*] //)
	{
		$flags & $UL ? print "</li>\n" : print "<ul>\n";
		$flags = $flags | $UL;
		print "<li>".$_;
	}
	elsif($_ !~ m/^ / and $flags & $UL)
	{
		print "</li></ul>\n";
		$flags = $flags & ~ $UL;
	}
	else {print $_;}
}
print <report_template>