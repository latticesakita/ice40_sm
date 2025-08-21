component ice40_ip_if is
    port(
        clk: in std_logic;
        resetn: in std_logic;
        int_o: out std_logic;
        HADDR: in std_logic_vector(31 downto 0);
        HBURST: in std_logic_vector(2 downto 0);
        HTRANS: in std_logic_vector(1 downto 0);
        HSIZE: in std_logic_vector(2 downto 0);
        HWRITE: in std_logic;
        HSEL: in std_logic;
        HREADY: in std_logic;
        HWDATA: in std_logic_vector(31 downto 0);
        HRDATA: out std_logic_vector(31 downto 0);
        HREADYOUT: out std_logic;
        HRESP: out std_logic;
        ip_addr_o: out std_logic_vector(7 downto 0);
        ip_wdata_o: out std_logic_vector(7 downto 0);
        ip_rdata_i: in std_logic_vector(7 downto 0);
        ip_we_o: out std_logic;
        ip_stb_o: out std_logic;
        ip_int_i: in std_logic_vector(1 downto 0);
        ip_ack_i: in std_logic
    );
end component;

__: ice40_ip_if port map(
    clk=>,
    resetn=>,
    int_o=>,
    HADDR=>,
    HBURST=>,
    HTRANS=>,
    HSIZE=>,
    HWRITE=>,
    HSEL=>,
    HREADY=>,
    HWDATA=>,
    HRDATA=>,
    HREADYOUT=>,
    HRESP=>,
    ip_addr_o=>,
    ip_wdata_o=>,
    ip_rdata_i=>,
    ip_we_o=>,
    ip_stb_o=>,
    ip_int_i=>,
    ip_ack_i=>
);
