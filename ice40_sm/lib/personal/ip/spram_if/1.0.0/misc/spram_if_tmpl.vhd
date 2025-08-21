component spram_if is
    port(
        HCLK: in std_logic;
        HRESETn: in std_logic;
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
        sram_addr: out std_logic_vector(31 downto 0);
        sram_we: out std_logic;
        sram_maskwe: out std_logic_vector(3 downto 0);
        sram_re: out std_logic;
        sram_din: out std_logic_vector(31 downto 0);
        sram_dout: in std_logic_vector(31 downto 0);
        sram_write_done: in std_logic;
        sram_read_valid: in std_logic
    );
end component;

__: spram_if port map(
    HCLK=>,
    HRESETn=>,
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
    sram_addr=>,
    sram_we=>,
    sram_maskwe=>,
    sram_re=>,
    sram_din=>,
    sram_dout=>,
    sram_write_done=>,
    sram_read_valid=>
);
