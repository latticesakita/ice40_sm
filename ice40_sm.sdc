create_clock -name {osc0/CLKHF} -period 20.8333333333333 [get_nets oclk]
create_clock -name {clk_i} -period 83.3333333333333 [get_nets clk_soc]
