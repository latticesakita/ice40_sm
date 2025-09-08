#!perl

$mem = "ice40_sm_Code.mem";
$log = "spram_init.log";
$err = 0;
open( $fh_m, "<", $mem) or die $mem;
open( $fh_l, "<", $log) or die $log;

while(!eof($fh_m)){
	chomp($mtxt = <$fh_m>);
	chomp($ltxt = <$fh_l>);
	$mdata = hex $mtxt;
	$ldata = hex $ltxt;
	if($mdata != $ldata){
		printf "$. $mtxt != $ltxt\n";
		$err++;
	}
	else{
		printf "$. $mtxt == $ltxt\n";
	}
}


printf "Error count = %d\n", $err;
