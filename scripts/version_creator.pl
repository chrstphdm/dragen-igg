#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Path qw(make_path);


my $input_directory;
my $aggdir;
my $cohort_name;
my $meta = 0;
my $list_cohorts_for_meta;
my $dry=0;
my $dry_mode=1;

GetOptions(
    "aggdir=s"              => \$aggdir, 
    "cohort=s"              => \$cohort_name,  # Output directory option
    "meta"                  => \$meta,
    "list=s"                => \$list_cohorts_for_meta,
    "dry=s"                   => \$dry,
) or die "Usage: $0 \n";


if ($dry ne 'false'){
    print "\n\n## DRY MODE ##\n\n";
}else{
    $dry_mode=0;
}

unless ((defined $cohort_name) && ($cohort_name ne '')){
    die "[ERROR] Cohort name is mandatory [--cohort]\n";
}

if ($meta && (!$list_cohorts_for_meta)){
    die "Cannot use META mode, without specifying the cohorts to aggregate name (--list)\n";
}

# Input and output directories from command-line arguments
unless (defined $aggdir) {
    die "'--aggdir' is a MANDATORY parameter.\n";
}

unless (-e $aggdir && -d $aggdir) {
    die "Aggregation directory $aggdir does not exist or is not a directory.\n";
}


my $cohorts_root = "${aggdir}/COHORTS/";

my $this_cohort_root;
if ($meta){
    $this_cohort_root = "${aggdir}/META_COHORTS/$cohort_name";
}else{
    $this_cohort_root = "${aggdir}/COHORTS/$cohort_name";
}



unless (-e $this_cohort_root && -d $this_cohort_root) {
    die "Cohort directory ($this_cohort_root) does not exist or is not a directory.\n";
}

my $yamls_dirname = "${this_cohort_root}/CONFIG/NEXTFLOW_YAML";
my $versions_dirname = "${this_cohort_root}/CONFIG/VERSIONS";

unless (-d $yamls_dirname) {
    # Create the directory tree
    make_path($yamls_dirname) or die "Failed to create folder tree: $!";
    print "Created folder tree: $yamls_dirname\n";
}
unless (-d $versions_dirname) {
    # Create the directory tree
    make_path($versions_dirname) or die "Failed to create folder tree: $!";
    print "Created folder tree: $versions_dirname\n";
}


#### Check cohort list, if mode META
my @cohorts_to_agg;
if ($meta){
    my @cohorts_to_agg_tmp = split (/,/,$list_cohorts_for_meta);
    @cohorts_to_agg = do {
        my %seen;
        grep !$seen{$_}++, sort @cohorts_to_agg_tmp;
    };
    my $size = $#cohorts_to_agg + 1;
    if ($size > 1){
        print "The list has $size cohorts.\n";
    }else{
        die "[ERROR]: You should give more than a cohort while in META mode (--list cohort1,cohort2)";
    }
    
}else{
    push @cohorts_to_agg, $cohort_name;
}


# Get list of files in input directory
my %hash_to_agg;

print "Fetching processed YAML files \n";
foreach my $cohort (sort @cohorts_to_agg){
    my $cohort_yaml_dir = "$cohorts_root/$cohort/CONFIG/NEXTFLOW_YAML/";
    print "Scanning : $cohort_yaml_dir\n";
    opendir(my $sdh, "$cohort_yaml_dir") or die "Unable to open yaml config directory: $cohort_yaml_dir \n $!";
        my @batches = grep { -f "$cohort_yaml_dir/$_" && (/^Batch_(\d+)\.gvcfs\.list\.yaml\.OK$/) } readdir($sdh);

        $hash_to_agg{$cohort}=\@batches;
    closedir($sdh);
}


my %included_samples;
my %included_batches;
print "Checking corresponding Batche files \n";
foreach my $cohort_name (sort keys %hash_to_agg) {

    foreach my $yml (@{$hash_to_agg{$cohort_name}}){
        my $corresponding_batch_filename = $yml;
        $corresponding_batch_filename =~ s/\.yaml\.OK$//;

        my $batch_digit;
        if ($corresponding_batch_filename =~ /Batch_(\d+)/) {
            $batch_digit=$1;
        } else {
            die "No number found in the string: $corresponding_batch_filename\n";
        }


        my $corresponding_batch_file_path = "$cohorts_root/$cohort_name/CONFIG/BATCHES/$corresponding_batch_filename"; ####
        unless (-e $corresponding_batch_file_path && -r $corresponding_batch_file_path) {
            print "The batch file '$corresponding_batch_file_path' do not exists or not readable.\n";
        }

        open(my $fh, '<', "$corresponding_batch_file_path") or die "Unable to open file '$corresponding_batch_file_path': $!";
        while (my $line = <$fh>) {
            chomp $line;
            if (defined $included_samples{$line}){
                die "$line : present in multiple batches - $cohort_name\n";
            }else{
                $included_samples{$line}=1;
            }
        }
        close($fh);

        $included_batches{$cohort_name}{$corresponding_batch_filename}=$batch_digit;
        # print "$cohort_name => $corresponding_batch_file_path \n";
    }
    # print "$cohort_name =>". join(', ', @{$hash_to_agg{$cohort_name}})."\n";
}






# my $yamls_dirname = "${this_cohort_root}/CONFIG/NEXTFLOW_YAML";
# my $versions_dirname = "${this_cohort_root}/CONFIG/VERSIONS";

my $max_digit = 0;

opendir(my $odh, $versions_dirname) or die "Unable to open $versions_dirname: $!";
while (my $file = readdir($odh)) {
    next unless $file =~ /^Version_(\d+)\.batches.list$/; # Match files with the specified filename format
    my $digit = $1; # Extract the digit from the filename
    $max_digit = $digit if $digit > $max_digit; # Update max_digit if necessary
}
closedir($odh);


my $version_count = int($max_digit + 1);
my $version_filename = "Version_$version_count.batches.list";
my $version_file  = "$versions_dirname/$version_filename";
my $version_file_tmp  = "$versions_dirname/$version_filename.tmp";


open(VER, '>', $version_file_tmp) or die "Unable to create version file: $!";

my $number_of_batches=0;
my $number_of_cohorts=0;
foreach my $cohort (sort keys %included_batches) {
    # print "Cohort: $cohort\n";
    foreach my $batch (sort { $included_batches{$cohort}{$a} <=> $included_batches{$cohort}{$b} } keys %{$included_batches{$cohort}}) {
        my $batch_number = $included_batches{$cohort}{$batch};
        # print "\t$batch: $batch_number\n";

        if ($meta){
            print VER "$batch_number,$cohort\n";
        }else{
            print VER "$batch_number\n";
        }
        $number_of_batches++;
    }
    $number_of_cohorts++;
}

close(VER);


my $size_samples = keys %included_samples;  # Scalar context is implied by the assignment to a scalar variable

print "The VERSION has :\n";
print "   COHORTS : $number_of_cohorts\n";
print "   BATCHES : $number_of_batches\n";
print "   SAMPLES : $size_samples\n";

print "\nPlease check the Version file to be created:\n$version_file_tmp\n\n";

if ($dry_mode){
    print "\nIf all seems OK, please re-run with [--dry false]\n\n";
}else{


    my $yaml_file = "${yamls_dirname}/${version_filename}.yaml";
    if (-e $yaml_file) {
        print STDERR "File does exist already: $yaml_file\n";
        unlink($version_file_tmp) or die "Can't unlink $version_file_tmp: $!";
        die;
    }

    rename($version_file_tmp, $version_file) || die ( "Error in renaming : $version_file_tmp \n" );

    print "VERSION FILE created : $version_file\n";

    open (YAM, '>', $yaml_file) or die "Unable to create $yaml_file file: $!";
    print YAM "---\n";
    print YAM "COHORT: $cohort_name\n";
    print YAM "input_file: \'$version_file\'\n";
    print YAM "step: 2\n";

    if ($meta){
        print YAM "meta: true\n";
    }

    close(YAM);
    print "YAML FILE created : $yaml_file\n";

}



=begin comment



            my $yaml_file = "${output_nxf_yaml_dir}/${batch_filename}.yaml";


            if (-e $yaml_file) {
                print STDERR "File does exist already: $yaml_file\n";
                unlink($batch_file_tmp) or die "Can't unlink $batch_file_tmp: $!";
                die;
            }

            if (($added_samples == $batch_size) || ($force && ($added_samples > 0))){
                rename($batch_file_tmp, $batch_file) || die ( "Error in renaming" );
                print STDOUT "COHORT $cohort - BATCH $batch_count & YAML FILE CREATION - $added_samples samples\n";
                print STDOUT "OK\t$cohort/$batches_dirname/$batch_filename\n";

                ### create corresponding yaml file

                open (YAM, '>', $yaml_file) or die "Unable to create $yaml_file file: $!";
                print YAM "---\n";
                print YAM "COHORT: $cohort\n";
                print YAM "input_file: \'$batch_file\'\n";
                print YAM "step: 1\n";
                close(YAM);
                print STDOUT "OK\t$cohort/$yamls_dirname/$batch_filename.yaml\n";

                $max_digit++;

            }else{
                print STDERR "[WARN] No enough samples to create batch file : $added_samples - For Cohort : $cohort (you may use --force -c $cohort)\n";
                unlink($batch_file_tmp) or die "Can't unlink $batch_file_tmp: $!";
                $continue_generation = 0;
            }

        } ### STOP GENERATION, no more samples (while loop)

}



exit 0;




=cut
