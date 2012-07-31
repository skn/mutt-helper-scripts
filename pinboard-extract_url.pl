#!/usr/bin/env perl

# Copyright 2012 Srijith K. Nair. All rights reserved.
# 
# Bookmark script that works with the Kyle Wheeler's extract_url.pl
# to send selected URLs to pinboard for bookmarking.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#    2. Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY KYLE WHEELER ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL KYLE WHEELER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use strict;
use Curses qw(KEY_ENTER);
use Curses::UI; 
use URI;
use URI::Escape;
use Net::Delicious;
use LWP::UserAgent;

#config
my $pinboard_username = 'USERNAME'; # <---- change me
my $pinboard_password = 'PASSWORD'; # <---- change me
my $tag = 'frommutt';               # <---- change (?)
#end of config

$Curses::UI::debug = 0;
my $DEBUG = 0;          # some debug prints enabled if set to 1
my $title_entry = '';

my $url='';

if ($ARGV[0] eq '') {
    print "Error";
}

#Get redirected URL's permalink
my $ua = LWP::UserAgent->new(
    requests_redirectable => [],
);
my $res = $ua->get($ARGV[0]);
if ($res->code == 301)
	{$url = $res->header( 'location');}
else
	{$url = $ARGV[0];}

my $urlobj = URI->new($url);
my @pathseg = $urlobj->path_segments( );

if ($DEBUG) {
    print "Number of segments: " . scalar @pathseg . "\n";
    for (my $i=0; $i < @pathseg; $i++) {
        print "\t $i - {$pathseg[$i]}\n";
    }
}

my $chopchr = chop ($url);
if ($DEBUG) {print "chopper chr: $chopchr\n";}
my $backpedal;
($chopchr eq '/') ? ($backpedal = 2): ($backpedal = 1);
if ($DEBUG) {print "backpedal: $backpedal \n";}
my $path=uri_unescape($pathseg[scalar @pathseg - $backpedal]);
$path =~ s/-/ /g;
if ($DEBUG) {print "title: $path";}
    
my $cui = new Curses::UI( -color_support => 1 );
my $win1 = $cui->add('win1', 'Window',
    -border => 0,
    -y => 1,
    -bfg  => 'red',
    -height => 30,
    -width => 70,
    -centered => 1,
    );

$win1->add("d1", "TextEntry",
    -border => 0,
    -fg => "green",
    -x => 2,
    -y => 1,
    -width => 15,
    -text => "Bookmark Title",
    -focusable => 0,
    -readonly => 1,
    );

$title_entry = $win1->add("ent1", "TextEntry",
    -text => $path,
    -pos => 999,
    -border => 1,
    -bfg => "green",
    -x => 19 ,
    -width => 50,
    );

$cui->set_binding( sub{exit 0;}, "q");
$cui->set_binding(\&send_off,KEY_ENTER());
$cui->mainloop; 

sub send_off() {
    my $title = $title_entry->get();
    print "Title: $title\n" if $DEBUG;
    eval
    {
        require Proc::Daemon;
        Proc::Daemon->import();
    };
    unless($@)
    {
        # Proc::Daemon loaded and imported successfully
        Proc::Daemon::Init();
    }
                                                                                                                                                                                                                                                 
    my $pin = Net::Delicious->new({
        user => $pinboard_username,
        pswd => $pinboard_password,
        endpoint => "https://api.pinboard.in/v1/",
        #debug    => 1
    });
    my $result = $pin->add_post({
        url   => $url,
        description => $title, 
        tags => $tag,
    });
    if (!$result) {
        # Must be an error
        # No idea what to do though other than exit...
    }
    exit 0;                                                                                                                                                                                                                                                                            
}
