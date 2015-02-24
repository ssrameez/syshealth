#!/usr/bin/perl

use strict;
use warnings;
use Shell;

#1. CPU Usage
#2. CPU Steal
#3. IOWait
#4. Free Memory
#5. SWAP usage
#6. Uptime (if above 30 days WARN 90 days CRIT)
#6. Load Average

#7. Open Files compare with limits.conf
#9. Filesystem availability (compare with /etc/fstab)
#10. Filesystem read only status.
#11. Filesystem space consumption.
#12. NTP Drift
#13. Defunct processes

#global variables#

my %results;

my ($str, $res, $val);

sub getresults {

#procs -----------memory---------- ---swap-- -----io---- --system-- -----cpu------
# r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
# 0  0    3 4 5 6    7    8     9    10    11                   12 13 14 15 16 17

  chomp(my $result = `vmstat|egrep -v 'procs|cache'`);
  if ($result =~ /^\s+\d+\s+\d+\s+(\d+)\s+(\d+).*\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/) {
    $results{'swap'} = $1;
    $results{'freemem'} = $2;
    $results{'cpuuser'} = $3;
    $results{'cpusystem'} = $4;
    $results{'cpuidle'} = $5;
    $results{'IOwait'} = $6;
    $results{'cpusteal'} = $7;
  }
  else {
    print "vmstat result doesn't seem to be matching the regex\n";
  }
  chomp(my $result2 = `uptime`);



}
##Main Starts Here##

getresults;

format Sanity =
Test: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<   @||||||||||
$str, $res, $val
.

$str = " 1. CPU Idle";
if ($results{'cpuidle'} > 60) {
  $res = 'OK';
}
elsif ($results{'cpuidle'} < 60 && $results{'cpuidle'} > 40) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $results{'cpuidle'};
$~ = 'Sanity';
write;

$str = " 1a. CPU User";
if ($results{'cpuuser'} < 60) {
  $res = 'OK';
}
elsif ($results{'cpuuser'} > 60 && $results{'cpuuser'} < 75) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $results{'cpuuser'};
$~ = 'Sanity';
write;

$str = " 1b. CPU System";
if ($results{'cpusystem'} <= 20) {
  $res = 'OK';
}
elsif ($results{'cpusystem'} > 20 && $results{'cpusystem'} < 30) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $results{'cpusystem'};
$~ = 'Sanity';
write;


$str = " 2. CPU Steal";
if ($results{'cpusteal'} < 10) {
  $res = 'OK';
}
elsif ($results{'cpusteal'} > 10 && $results{'cpusteal'} < 30) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $results{'cpusteal'};
$~ = 'Sanity';
write;

$str = " 3. CPU IOWait";
if ($results{'IOwait'} < 10) {
  $res = 'OK';
}
elsif ($results{'IOwait'} > 10 && $results{'IOwait'} < 30) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $results{'IOwait'};
$~ = 'Sanity';
write;


$str = " 4. Free Memory";
if ($results{'freemem'} > 1000) {
  $res = 'OK';
}
elsif ($results{'freemem'} < 1000 && $results{'freemem'} > 500) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $results{'freemem'};
$~ = 'Sanity';
write;


$str = " 5. SWAP Usage";
if ($results{'swap'} < 1000) {
  $res = 'OK';
}
elsif ($results{'swap'} > 1000 && $results{'swap'} < 3000) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $results{'swap'};
$~ = 'Sanity';
write;

my $uptime = uptime();
my $updays = 1;
$updays = $1 if ($uptime =~ /(\d+) days/);

$str = " 6. Uptime";
if ($updays <= 30) {
  $res = 'OK';
}
elsif ($updays > 30 && $updays < 90) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $updays;
$~ = 'Sanity';
write;

my $load=0;

$load = $1 if ($uptime =~ /load average:\s+(\d+.\d+),/);

chomp(my $cpucount = `cat /proc/cpuinfo |grep processor|wc -l`);

my $doublecpu = 2 * $cpucount;

$str = " 7. Load Average";
if ($load <= $cpucount) {
  $res = 'OK';
}
elsif ($load > $cpucount && $load < $doublecpu) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $load;
$~ = 'Sanity';
write;

$str = " 8. NTP Drift";
my @ntpdrift=`/usr/sbin/ntpq -nc peers | tail -n +3 | awk '{ print \$9 }' | tr -d '-'`;
my $ntpdrift=0;

foreach (@ntpdrift) {
  $ntpdrift = $_ if ($ntpdrift<$_);
}

if ($ntpdrift <= .5) {
  $res = 'OK';
}
elsif ($ntpdrift > .5 && $ntpdrift < 1) {
  $res = 'WARN';
}
else {
  $res = 'CRIT';
}
$val = $ntpdrift;
$~ = 'Sanity';
write;
