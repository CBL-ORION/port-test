requires 'Test::Most';
requires 'Data::Printer'; # needed to dump output .mat file contents
requires 'Capture::Tiny';
requires 'List::UtilsBy';
requires 'Memoize';
requires 'Log::Log4perl';
requires 'YAML::XS';

# handling data
requires 'Moo';
requires 'PDL', '2.008';
requires 'Inline::C', '0.64';
requires 'Hash::Merge';
requires 'Type::Tiny';
requires 'Statistics::NiceR';
requires 'Tree::Simple';

# for parsing functions
requires 'Path::Tiny';
requires 'Path::Iterator::Rule';
requires 'Parse::RecDescent';

# needed for handling MATLAB debugger
requires 'Expect';
requires 'IO::Stty';
