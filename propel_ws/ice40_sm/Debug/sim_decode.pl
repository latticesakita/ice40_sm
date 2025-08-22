#!perl

# decode transcript data of simulation result
# # Time: Address, Data
# # 2999110000: 000009c0, 0c4002ef
# # 3002068000: 00000a84, ff010113
# # 3003652000: 00000a88, 01212023

if(scalar(@ARGV)!=2){
	printf "sim_decode.pl file1.lst file2.txt\n";
	exit;
}

if(length($ARGV[1])>0){
	$file = $ARGV[1];
}
else{
	$file = "transcript.txt" ;
}

open $fp, "<", $file or die "can't open $file ";

%funcname;
&get_funcname(\%funcname, $ARGV[0]);


while (<$fp>) {
	chomp;
	# ($dmy, $tm, $addr, $inst) = split /[:, ]+/;
	($tm, $addr, $inst) = split /[:, ]+/;
	$riscv_addr = hex $addr;
	# printf "$_ // %s %x \n", $addr, $riscv_addr;
	printf "$_ // %s \n", $funcname{$riscv_addr};
}


sub get_funcname {
	my $list = shift;
	my $dumpfile = shift; #"dump.dump";
	my $funcname = "";
	my $ignore = 1;

	open my $fh, "<", $dumpfile or die "can't open dump file";

	while(<$fh>){
		chomp;
		if($ignore ==1){
			if(m/Disassembly of section .text/){
printf "ignore 0 $.\n";
				$ignore = 0;
				next;
			}
		}
		elsif(m/Disassembly of section/){
printf "ignore 1 $.\n";
			$ignore = 1;
			next;
		}
		if($ignore == 0) {
			s/^\s+//;
			if(m/^[0-9a-f]+\s\<([^\>]+)\>/){
				# printf "func = %s\n", $1;
				$funcname = $1;
				next;
			}
			if(m/^([0-9a-f]+):/){
				my $addr = hex $1;
				$list->{$addr} = $funcname;
			}
		}
		
	}
	close $fh;
	return ;

}
