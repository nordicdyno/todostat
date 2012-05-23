use inc::Module::Install;
#name 'App-TodoStat';
name 'todostat';
version_from 'lib/App/TodoStat.pm';
perl_version '5.008001';

configure_requires 'version', 0.77;

requires 'File::Find::Rule';
# TODO: replace by File::Next 
#requires File::Next;
requires 'List::MoreUtils';
requires 'YAML::Tiny';
requires 'Term::ANSIColor';

install_script 'bin/todostat';

resources
    homepage   => 'https://github.com/nordicdyno/todostat',
    bugtracker => 'https://github.com/nordicdyno/todostat/issues',
;


WriteAll;
