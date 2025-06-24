#!/usr/bin/env perl
use strict;
use warnings;
use List::Util qw(max);
use Getopt::Long;

my($error_depth, $id);
GetOptions(
	"e:i"	=>	\$error_depth,
	"id:s"	=>	\$id
);

$error_depth||=5;



my($kmer_accumulator,@info_array);
open IN,shift;
while(<IN>){
	((/^(\d+)\s+\d+/) && ($1 > $error_depth)) || next;
	(/^(\d+)\s+(\d+)/) && (my($depth, $frequence) = ($1, $2));

	push(@info_array, "$depth\t$frequence");
	$kmer_accumulator += $depth*$frequence;
}
close IN;



my(%spikes);
for my $i(1..scalar @info_array -2){
	my $last_frequence = (split/\t/,$info_array[$i-1])[1];
	my $current_frequence = (split/\t/,$info_array[$i])[1];
	my $next_frequence = (split/\t/,$info_array[$i+1])[1];

	#print "$last_frequence\t$current_frequence\t$next_frequence\n";
	(($current_frequence > 10000) && ($current_frequence > $last_frequence) && ($current_frequence > $next_frequence)) || next;
	my($depth, $frequence) = split/\t/,$info_array[$i];
	$spikes{$depth} = $frequence;
}


my $max_frequence = max(values %spikes);
my $max_freq_depth = (grep {$spikes{$_} == $max_frequence}(keys %spikes))[0];




my @main_spikes = grep {$_%$max_freq_depth <= 3 || $max_freq_depth%$_ <= 3}(keys %spikes); # 主峰
#my @count_spikes = keys %spikes; # 所有峰

print ">$ID\nDepth\tEstimated Genome Size(Mb)\n";
for my $spike_depth (sort { $a <=> $b } keys %spikes){
	my $Est_Genomesize = int(($kmer_accumulator/$spike_depth)/1000000);
	$Est_Genomesize =~ s/(?<=\d)(?=(\d{3})+$)/,/g;
 	if(grep {$_ == $spike_depth}(@main_spikes)){ #主峰标记
		print "<!>$spike_depth\t$Est_Genomesize\n";
  	}else{
   		print "$spike_depth\t$Est_Genomesize\n";
	}
}
