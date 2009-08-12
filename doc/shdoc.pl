#! /usr/bin/perl

use Getopt::Std;

getopt("ct");
require $opt_c;

use File::Find;
use File::Glob;
use File::Basename;
use File::Path;

use IO::Compress::Gzip;

my $generator = "CDoc";

my $doc_type = $opt_t;
my $doc_input = @ARGV[0];
my $doc_output = @ARGV[1];

sub read_source {
  my $source_name = shift;
  my $module = shift;
  my $variables = shift;
  my $functions = shift;
  my $references = shift;

  $$module{source} = basename($source_name);
  $$module{name} = $$module{source};
  $$module{name} =~ s/$source_pattern//;

  my $in_block = 0;
  my @block;

  my $source = "";
  open(source_file, $source_name);
  while (<source_file>) {
    $line = $_;

    if ($line =~ /$comment_pattern/) {
      my $comment = $1;
  
      if ($comment =~ /$block_pattern/) {
        $in_block = 1;
        @block = ($1);
      }
      elsif ($in_block) {
        @block = (@block, $1);
      }
      else {
        @block = ($comment);
      }
    }
    else {
      my $brief;
      my @function_params = ();
      my @non_directive = ();

      my $in_variable = 0;
      my $in_parameter = 0;

      for my $block_line (@block) {
        if ($block_line =~ /$directive_pattern/) {
          my $directive = $1;
          my $arguments = $2;

          if ($directive =~ /$module_pattern/) {
            $$module{name} = $arguments;
          }

          if ($directive =~ /$brief_pattern/) {
            $brief = $arguments;
          }

          if ($directive =~ /$variable_pattern/) {
            if ($arguments =~ /$variable_arguments_pattern/) {
              $in_variable = 1;

              my $variable_name = $1;
              my $variable_description = $2;
                        
              @$variables = (@$variables, {
                name => $variable_name,
                description => $variable_description
              });
            }
          }
          else {
            $in_variable = 0;
          }

          if ($directive =~ /$param_pattern/) {
            $in_parameter = 1;

            my $param_tag = $1;
            my $param_spec = $2;

            if ($arguments =~ /$param_arguments_pattern/) {
              my $param_key = $1;
              my $param_name = $2;
              my $param_type = $value_pattern;
              my $param_description = $3;

              foreach my $param_type_key (keys %param_type_patterns) {
                if ($param_spec =~ /$param_type_patterns{$param_type_key}/) {
                  $param_type = $param_type_key;
                  break;
                }
              }

              @function_params = (@function_params, {
                tag => $param_tag,
                key => $param_key,
                name => $param_name,
                type => $param_type,
                description => $param_description
              });
            }
          }
          else {
            $in_parameter = 0;
          }
        }
        else {
          if ($in_variable) {
            $$variables[$#$variables]->{description} .= " $block_line";
          }
          elsif ($in_parameter) {
            $function_params[$#function_params]->{description} .= 
              " $block_line";
          }
          else {
            @non_directive = (@non_directive, $block_line);
          }
        }
      }

      if ($line =~ /$include_pattern/) {
        my $include = $1;
        if ($include =~ /$name_pattern/) {
          $$references{$include} = $include;
        }
      }
      elsif ($line =~ /$function_pattern/) {
        my $name = $1;
        @$functions = (@$functions, {
          name => $name,
          brief => $brief,
          description => join("\n", @non_directive),
          parameters => [@function_params]
        });
      }
      elsif (!@$functions) {
        if (!$$module{brief}) {
          $$module{brief} = $brief;
        }
        if ($$module{brief} and !$$module{description}) {
          $$module{description} = join("\n", @non_directive);
        }
      }

      @block = ();
      $in_block = 0;
    }
  }
  close(source_file);
}

sub generate_man {
  my $man_name = shift;
  my $module = shift;
  my $variables = shift;
  my $functions = shift;
  my $references = shift;
  my $man = shift;

  my @time = localtime();
  my $date = sprintf("%d-%02d-%02d", $time[5]+1900, $time[4], 
    $time[3]);

  $$man .= ".TH \"".uc($man_name)."\" $man_extension \"$date\" ".
    "Linux \"$project_name Module Documentation\"\n";
  $$man .= ".SH NAME\n";
  my @function_names;
  for my $function (@$functions) {
    @function_names = (@function_names, $function->{name});
  }
  $$man .= join(", ", @function_names);
  if ($$module{brief}) {
    $$man .= " - $$module{brief}";
  }
  $$man .= "\n";

  $$man .= ".SH SYNOPSIS\n";
  $$man .= ".BR \"include \"\"$$module{source}\"\"\n";
  $$man .= ".sp\n";
  for my $function (@$functions) {
    my $function_signature;
    my @param_signatures;

    for my $param (@{$function3->{parameters}}) {
      my $param_signature;

      if ($param->{name}) {
        if ($param->{type} =~ /$list_pattern/) {
          $param_signature = "\" $param->{name}1 \" [\" $param->{name}2 \" ...]";
        }
        elsif ($param->{type} =~ /$option_pattern/) {
          $param_signature = "$param->{name}";
        }
        else {
          $param_signature = "\" ".$param->{name}." \"";
        }
      }
      if ($param->{key}) {
        $param_signature = "$param->{key} $param_signature";
      }
      $param_signature =~ s/^\s*|\s*$//g;
      if ($param->{tag} =~ /$optional_pattern/) {
        $param_signature = "[$param_signature]";
      }

      @param_signatures = (@param_signatures, $param_signature);
    }
    $function_signature = join(" ", @param_signatures);
    $function->{signature} = $function_signature;

    $$man .= ".BR \"$function->{name}($function->{signature})\"\n";
    $$man .= ".br\n";
  }

  $$man .= ".SH DESCRIPTION\n";
  if ($$module{description}) {
    my $description = $$module{description};

    $description =~ s/\n\n/\n.PP\n/g;
    $$man .= "$description\n";
  }
  elsif ($$module{name} =~ /^$project_name$/) {
    $$man .= "$project_summary\n";
  }
  else {
    $$man .= "This module requires documentation.\n";
  }

  if (@$variables) {
    $$man3 .= ".SH VARIABLES\n";
    for my $variable (@$variables) {
      $$man .= ".TP\n";
      $$man .= ".B \"$variable->{name}\"\n";
  
      if ($variable->{description}) {
        $$man .= "$variable->{description}\n";
      }
    }
  }

  $$man .= ".SH FUNCTIONS\n";
  for my $function (@$functions) {
    $$man .= ".TP\n";
    $$man .= ".BI \"$function->{name}($function->{signature})\"\n";
    $$man .= ".RS\n";

    if ($function->{brief}) {
      $$man .= "$function->{brief}\n";
      $$man .= ".PP\n";
    }

    if ($function->{description}) {
      my $function_description = $function->{description};

      $function_description =~ s/\n\n/\n.PP\n/g;
      $$man .= "$function_description\n";
    }

    if (!($function->{brief}) and !($function->{description})) {
      $$man .= "This function requires documentation.\n";
    }

    for my $param (@{$function->{parameters}}) {
      $$man .= ".TP\n";

      if ($param->{key}) {
        $$man .= ".RI \"$param->{key} \"";
      }
      else {
        $$man .= ".IR";
      }

      if ($param->{name}) {
        if ($param->{type} =~ /$list_pattern/) {
          $$man .= " \"$param->{name}1 $param->{name}2 \"...\n";
        }
        elsif ($param->{type} =~ /$option_pattern/) {
          $$man .= " $param->{name}\n";
        }
        else {
          $$man .= " \"$param->{name}\"\n";
        }
      }
      else {
        $$man .= "\n";
      }

      if ($param->{description}) {
        my $param_description = $param->{description};
  
        $param_description =~ s/\n\n/\n.PP\n/g;
        $$man .= "$param_description\n";
      }
      else {
        $$man .= "This parameter requires documentation.\n";
      }
    }

    $$man .= ".RE\n";
  }

  $$man .= ".SH AUTHOR\n";
  $$man .= "Written by $project_author.\n";  

  $$man .= ".SH REPORTING BUGS\n";
  $$man .= "Report bugs to <$project_contact>.\n";  

  $$man .= ".SH COPYRIGHT\n";
  $$man .= "$project_name is published under the $project_license.\n";

  if (%$references) {
    $$man .= ".SH SEE ALSO\n";
    $$man .= join(" ", values(%$references))."\n";
  }

  $$man .= ".SH COLOPHON\n";
  $$man .= "This page is part of version $project_version, ".
    "release $project_release of the $project_name project.\n";
  $$man .= ".PP\n";
  $$man .= "A description of the project, and information about ".
    "reporting bugs, can be found at ".$project_home.".\n";  

  for my $reference_key (keys %$references) {
    $$man =~ s/$reference_key/$$references{$reference_key}/g;
  }
  $$man =~ s/$man_reference_pattern/\n.BR \1 \2/g;
}

sub find_source {
  my %module;
  my @variables;
  my @functions;
  my %references;
  
  my $source_name = $File::Find::name;
  
  return unless -f $source_name;
  return unless basename($source_name)  =~ /$source_pattern/;

  print "$generator: Parsing ".basename($source_name)."\n";
  read_source($source_name, \%module, \@variables, \@functions, \%references);
  print "$generator: - $module{name}: ".@functions." function(s), ".
    keys(%references)." reference(s)\n";

  my $man_name = lc($project_name)."_".lc($module{name});

  foreach $reference_key (keys %references) {
    if ($reference_key =~ /$name_pattern/) {
      $references{$reference_key} = lc($project_name)."_".lc($1).
        "($man_extension)";
    }
  }
  
  my $man;
  print "$generator: - $module{name}: Generating $man_name($man_extension)\n";
  generate_man($man_name, \%module, \@variables, \@functions, \%references,
    \$man);

  if ($doc_type =~ /man/) {
    my $doc_name = "man${man_extension}/$man_name.$man_extension.gz";
    print "Writing $doc_name\n";
    mkpath("${doc_output}/man${man_extension}");
    my $z = new IO::Compress::Gzip "$doc_output/$doc_name" or 
      die("Error: Failed to compress $doc_name!\n");
    print $z $man;
    close $z;
  }
  else {
    my $doc_name = "$man_name.".lc($doc_type);
    print "Writing $doc_name\n";
    mkpath(${doc_output});
    my $pid = open(file, "| $groff_executable -t -e -man -T${doc_type} - >".
      "$doc_output/$doc_name") or 
      die("Error: Failed to execute groff!\n");
    print file $man;
  }
}

find(\&find_source, $doc_input);
