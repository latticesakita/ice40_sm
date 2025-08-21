component timer is
    port(
        int_o: out std_logic;
        ahbl_haddr_i: in std_logic_vector(31 downto 0);
        ahbl_hburst_i: in std_logic_vector(2 downto 0);
        ahbl_hrdata_o: out std_logic_vector(31 downto 0);
        ahbl_hsize_i: in std_logic_vector(2 downto 0);
        ahbl_htrans_i: in std_logic_vector(1 downto 0);
        ahbl_hwdata_i: in std_logic_vector(31 downto 0);
        ahbl_hready_i: in std_logic;
        ahbl_hreadyout_o: out std_logic;
        ahbl_hresp_o: out std_logic;
        ahbl_hsel_i: in std_logic;
        ahbl_hwrite_i: in std_logic;
        systime_o: out std_logic_vector(31 downto 0);
        clk_i: in std_logic;
        resetn_i: in std_logic
    );
end component;

__: timer port map(
    int_o=>,
    ahbl_haddr_i=>,
    ahbl_hburst_i=>,
    ahbl_hrdata_o=>,
    ahbl_hsize_i=>,
    ahbl_htrans_i=>,
    ahbl_hwdata_i=>,
    ahbl_hready_i=>,
    ahbl_hreadyout_o=>,
    ahbl_hresp_o=>,
    ahbl_hsel_i=>,
    ahbl_hwrite_i=>,
    systime_o=>,
    clk_i=>,
    resetn_i=>
);
