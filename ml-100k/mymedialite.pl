#!/usr/bin/perl

# MyMediaLite experiments for the page http://recsyswiki.com/wiki/MovieLens_100k_benchmark_results
# Zeno Gantner <zeno.gantner@gmail.com>

use strict;
use warnings;
use English qw( -no_match_vars );

my $URL = "https://github.com/zenogantner/recsys-benchmark/ml-100k/mymedialite.pl";
my $program_version = "MyMediaLite 3.07";
my $data_dir = $ARGV[0] or die "Usage: $PROGRAM_NAME DATA_DIR\n";

sub extract_rmse {
    my ($text) = @_;

    if ($text =~ m/ RMSE (\d+\.\d+)/) {
	return $1;
    }

    return;
}

sub experiments {
    my ($method, $parameters) = @_;

    my $sum = 0;
    foreach my $i (1 .. 5) {
	my $output = `rating_prediction --recommender=$method --training-file=${data_dir}/u${i}.base --test-file=${data_dir}/u${i}.test --recommender-options="$parameters"`;
	$sum += extract_rmse($output);
    }
    my $cv_mean = $sum / 5;

    $sum = 0;
    foreach my $i (qw/a b/) {
	my $output = `rating_prediction --recommender=$method --training-file=${data_dir}/u${i}.base --test-file=${data_dir}/u${i}.test --recommender-options="$parameters"`;
	$sum += extract_rmse($output);
    }
    my $all_but_10_mean = $sum / 2;

    print  "|-\n";
    printf "| [$URL $program_version] || $method || %.4f || %.4f \n", $cv_mean, $all_but_10_mean;
}


foreach my $method (qw/GlobalAverage UserAverage ItemAverage/) {
    experiments($method, '');
}


my @SETTINGS = (
    ['UserItemBaseline', 'reg_u=5 reg_i=2'],
    ['UserKNN', 'k=60 shrinkage=25 reg_u=12 reg_i=1 correlation=Pearson'],
    ['ItemKNN', 'k=40 shrinkage=2500 reg_u=12 reg_i=1 correlation=Pearson'],
    ['BiasedMatrixFactorization', 'num_factors=5 bias_reg=0.1 reg_u=0.1 reg_i=0.1 learn_rate=0.07 num_iter=100 bold_driver=true'],
    ['SVDPlusPlus', 'num_factors=4 regularization=1 bias_reg=0.05 learn_rate=0.01 bias_learn_rate=0.07 num_iter=50 frequency_regularization=true'],
    ['SigmoidUserAsymmetricFactorModel', 'num_factors=5 regularization=0.003 bias_reg=0.01 learn_rate=0.006 bias_learn_rate=0.7 num_iter=70'],
    );
foreach my $pair_ref (@SETTINGS) {
    my ($method, $parameters) = @$pair_ref;
    experiments($method, $parameters);
}
