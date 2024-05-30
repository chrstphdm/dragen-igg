#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Path qw(make_path);


my $input_directory;
my $output_directory;
my $cohort_name;
my $force = 0;
my $batch_size = 1000;
my $single_cohort_mode=0;
my $batches_dirname = 'CONFIG/BATCHES';
my $yamls_dirname = 'CONFIG/NEXTFLOW_YAML';
my $samples_list;
my %samples_list_hash;



GetOptions(
    "input=s"         => \$input_directory,   # Input directory option
    "output=s"        => \$output_directory, 
    "cohort=s"        => \$cohort_name,  # Output directory option
    "force"           => \$force,
    "batch_size=i"    => \$batch_size,
    "samples_list=s"  => \$samples_list
) or die "Usage: $0 --input <input_directory> --output <output_batches_dir> [--force]\n";

if ((defined $cohort_name) && ($cohort_name ne '')){
    $single_cohort_mode = 1;
}

if ($force && (!$single_cohort_mode)){
    die "ERROR: Cannot use force mode, without specifying the cohort name (--cohort)\n";
}


# Input and output directories from command-line arguments
unless (defined $input_directory) {
    print "ERROR: '--input' is a MANDATORY parameter.\n";
    exit 1;
}
unless (defined $output_directory) {
    print "ERROR: '--output' is a MANDATORY parameter.\n";
    exit 1;
}

# Check if input directory exists
unless (-e $input_directory && -d $input_directory) {
    die "ERROR: Input directory $input_directory does not exist or is not a directory.\n";
    exit 1;
}
# Check if output directory exists
unless (-e $output_directory && -d $output_directory) {
    die "ERROR: Output directory $output_directory does not exist or is not a directory.\n";
    exit 1;
}

if (defined $samples_list && $samples_list ne '') {
    unless($single_cohort_mode){
        die "ERROR: --cohort option is mandatory when a sample_list is provided";
    }
    unless (-e $samples_list && -r $samples_list && !-z $samples_list) {
        die "ERROR: samples_list file [$samples_list] does not exist OR is not readable OR is empty.\n";
    }
    open(my $fh, '<', "$samples_list") or die "Unable to open file '$samples_list': $!";
    while (my $line = <$fh>) {
        chomp $line;
        $samples_list_hash{$line}=1;
    }
    close($fh);
}



# close $lst;

# Get list of files in input directory
my %hash_to_agg;
my @cohorts;

opendir(my $dh, $input_directory) or die "ERROR: Unable to open input directory: $!";

    if ($single_cohort_mode){
        push(@cohorts, $cohort_name);
    }else{
        @cohorts = grep { $_ ne '.' && $_ ne '..' && -d "$input_directory/$_" } readdir($dh);
    }

    foreach my $cohort (sort @cohorts){
        print "INFO: Analyzing COHORT [$cohort]\n";
        opendir(my $sdh, "$input_directory/$cohort") or die "ERROR: Unable to open input directory: $!";
            my @samples;
            my @samples_tmp = grep { -f "$input_directory/$cohort/$_" && (/\Q.QC_OK\E$/ || /\Q.QC_FORCED\E$/) } readdir($sdh);

            if (defined $samples_list && $samples_list ne '') {
                foreach my $actual_uuid (@samples_tmp){
                    my @tmp_array = split(/_/,$actual_uuid);
                    my $actual_sample=$tmp_array[0];
                    if(defined $samples_list_hash{$actual_sample}){
                        push(@samples,$actual_uuid);
                    }
                }
            }else{
                @samples = @samples_tmp;
            }

            $hash_to_agg{$cohort}=\@samples;
        closedir($sdh);
    }
closedir($dh);

# foreach my $key (sort keys %hash_to_agg) {
#     print "$key =>". join(', ', @{$hash_to_agg{$key}})."\n";
# }



#######
# Read existing batches
#
# Initialize variables

my %included_samples;

foreach my $cohort (sort @cohorts){


        my @samples_array = @{$hash_to_agg{$cohort}};
        unless (@samples_array) {
            print "ERROR: No samples to analyze in the cohort folder [$cohort]\n";
            next;
        }
        my $output_batches_dir  = "$output_directory/$cohort/$batches_dirname";
        my $output_nxf_yaml_dir = "$output_directory/$cohort/$yamls_dirname";
        unless (-d $output_batches_dir) {
            # Create the directory tree
            make_path($output_batches_dir) or die "ERROR: Failed to create folder tree: $!";
            print "INFO: Created folder tree: $output_batches_dir\n";
        } 

        unless (-d $output_nxf_yaml_dir) {
            # Create the directory tree
            make_path($output_nxf_yaml_dir) or die "ERROR: Failed to create folder tree: $!";
            print "INFO: Created folder tree: $output_nxf_yaml_dir\n";
        }

        my $max_digit = 0;

        opendir(my $odh, $output_batches_dir) or die "ERROR: Unable to open output_batches_dir: $!";
        while (my $file = readdir($odh)) {
            next unless $file =~ /^Batch_(\d+)\.gvcfs.list$/; # Match files with the specified filename format
            my $digit = $1; # Extract the digit from the filename
            $max_digit = $digit if $digit > $max_digit; # Update max_digit if necessary

            open(my $fh, '<', "$output_batches_dir/$file") or die "ERROR: Unable to open file '$file': $!";
            while (my $line = <$fh>) {
                chomp $line;
            
                unless (-e $line && -r $line) {
                    die "ERROR: Unable to open file : $line: $!";
                }
                $included_samples{$cohort}{$line}=1;
            }
            close($fh);


        }
        closedir($odh);

        my $continue_generation = 1;
        
        while ($continue_generation){

            my $batch_count = int($max_digit + 1);
            my $batch_filename = "Batch_$batch_count.gvcfs.list";
            my $batch_file  = "$output_batches_dir/$batch_filename";
            my $batch_file_tmp  = "$output_batches_dir/$batch_filename.tmp";



            my $added_samples=0;


            # Process each file in the input directory
            my @samples_array = @{$hash_to_agg{$cohort}};
            open(BT, '>', $batch_file_tmp) or die "ERROR: Unable to create batch file: $!";

            foreach my $sm (sort @samples_array){
                # print $sm."\n";
                last if ($added_samples == $batch_size);

                open(my $fh, '<', "$input_directory/$cohort/$sm") or die "ERROR: Unable to open file '$sm': $!";
                my $first_line = <$fh>;
                close($fh);
                chomp $first_line;

                unless (-e $first_line && -r $first_line) {
                    die "ERROR: Unable to open/read $first_line: $!";
                }

                unless (defined $included_samples{$cohort}{$first_line}){
                    print BT "$first_line\n";
                    $added_samples++;
                    $included_samples{$cohort}{$first_line}=1;
                }

            }
            
            close(BT);


            my $yaml_file = "${output_nxf_yaml_dir}/${batch_filename}.yaml";


            if (-e $yaml_file) {
                print STDERR "ERROR: File does exist already: $yaml_file\n";
                unlink($batch_file_tmp) or die "ERROR: Can't unlink $batch_file_tmp: $!";
                die;
            }

            if (($added_samples == $batch_size) || ($force && ($added_samples > 0))){
                rename($batch_file_tmp, $batch_file) || die ( "ERROR: Error in renaming" );
                print STDOUT "INFO: COHORT $cohort - BATCH $batch_count & YAML FILE CREATION - $added_samples samples\n";
                print STDOUT "\tOK\t$cohort/$batches_dirname/$batch_filename\n";

                ### create corresponding yaml file

                open (YAM, '>', $yaml_file) or die "ERROR: Unable to create $yaml_file file: $!";
                print YAM "---\n";
                print YAM "COHORT: $cohort\n";
                print YAM "input_file: \'$batch_file\'\n";
                print YAM "step: 1\n";
                close(YAM);
                print STDOUT "\tOK\t$cohort/$yamls_dirname/$batch_filename.yaml\n";

                $max_digit++;

            }else{
                print STDOUT "WARN: No enough samples to create batch file : $added_samples - For Cohort : $cohort (you may use --force -c $cohort)\n";
                unlink($batch_file_tmp) or die "ERROR: Can't unlink $batch_file_tmp: $!";
                $continue_generation = 0;
            }

        } ### STOP GENERATION, no more samples (while loop)

}



exit 0;

=begin comment



=cut
