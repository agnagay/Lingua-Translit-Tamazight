## $Id: 03_translit.t 30 2008-02-07 10:22:13Z alinke $

use strict;
use Test::More tests => 5;

my $truth;

my $script = "$ENV{PWD}/blib/script/translit";


$truth = -e $script;

# 1
is($truth, 1, "translit found");


$truth = system($script, "-h");

# 2
is($truth, 0, "translit supports -h switch");


$truth = system($script, "--help");

# 3
is($truth, 0, "translit supports --help switch");


$truth = system($script, "-l");

# 4
is($truth, 0, "translit supports -l switch");


$truth = system($script, "--list");

# 5
is($truth, 0, "translit supports --list switch");
