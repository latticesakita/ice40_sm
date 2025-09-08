#!perl

$mem = "ice40_sm_Code.mem";
$log = "spram_init.log";

open( $fh_m, "<", $mem) or die $mem;
open( $fh_l, "<", $log) or die $log;

while(!eof($fh_m)){
	chomp($mtxt = <$fh_m>);
	chomp($ltxt = <$fh_l>);
	$mdata = hex $mtxt;
	$ldata = hex $ltxt;
	if($mdata != $ldata){
		printf "$. $mtxt != $ltxt\n";
	}
	else{
		printf "$. $mtxt == $ltxt\n";
	}
}

