library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity VHDL_Lab is
    port(
        CLK : in     std_logic;
        LED : buffer std_logic := '0';
        RX            : IN STD_LOGIC  := '1';
        TX            : OUT STD_LOGIC  := '1'
    );
end entity VHDL_Lab;

architecture rtl of VHDL_Lab is
    signal counter : integer range 0 to 1000000 := 0;
    
    component UART_Interface is
        generic
        (
            CLK_Frequency : INTEGER  := 12000000;
            Baud_Rate     : INTEGER  := 19200;
            OS_Rate       : INTEGER  := 16;
            D_Width       : INTEGER  := 8;
            Parity        : INTEGER  := 0;
            Parity_EO     : STD_LOGIC  := '0'
        );
        port
        (
            CLK           : IN STD_LOGIC;
            Reset         : IN STD_LOGIC  := '0';
            RX            : IN STD_LOGIC  := '1';
            TX            : OUT STD_LOGIC  := '1';
            TX_Enable     : IN STD_LOGIC  := '0';
            TX_Busy       : OUT STD_LOGIC  := '0';
            TX_Data       : IN STD_LOGIC_VECTOR (D_Width-1 DOWNTO 0) := (others => '0');
            RX_Busy       : OUT STD_LOGIC  := '0';
            RX_Data       : OUT STD_LOGIC_VECTOR (D_Width-1 DOWNTO 0) := (others => '0');
            RX_Error      : OUT STD_LOGIC  := '0'
        );
    end component;
    
    signal TX_Enable     : STD_LOGIC  := '0';
    signal TX_Busy       : STD_LOGIC  := '0';
    signal TX_Data       : STD_LOGIC_VECTOR (8-1 DOWNTO 0) := (others => '0');
    signal RX_Busy       : STD_LOGIC  := '0';
    signal RX_Data       : STD_LOGIC_VECTOR (8-1 DOWNTO 0) := (others => '0');
    signal RX_Error      : STD_LOGIC  := '0';
    
    component Random_Number is
        generic
        (
            init_seed : std_logic_vector (127 downto 0) := x"0123456789abcdef0123456789abcdef";
            pipeline  : boolean  := true
        );
        port
        (
            clk       : IN std_logic ;
            rst       : IN std_logic  := '0';
            reseed    : IN std_logic  := '0';
            newseed   : IN std_logic_vector (127 downto 0) := (others => '0');
            out_ready : IN std_logic  := '1';
            out_valid : OUT std_logic ;
            out_data  : OUT std_logic_vector (31 downto 0)
        );
    end component;
    
    signal out_data  : std_logic_vector (31 downto 0);
begin

    blink: process(clk)
    begin
        if rising_edge(clk) then
            if counter < 1000000 then
                counter <= counter + 1;
            else
                counter <= 0;
                LED     <= NOT LED;
            end if;
        end if;
    end process blink;
    
    process(clk)
    variable state : NATURAL range 0 to 6 := 0;
    variable number_range : NATURAL range 1 to 10 := 1;
    variable random : NATURAL range 0 to 9 := 0;
    begin
        if rising_edge(clk) then
            if state = 0 then
                if RX_Busy = '1' then
                    state := 1;
                end if;
            elsif state = 1 then
                if RX_Busy = '0' then
                    number_range := TO_INTEGER(UNSIGNED(RX_Data)) - 47;
                    random := TO_INTEGER(UNSIGNED(out_data(7 downto 0))) mod number_range;
                    TX_Data <= STD_LOGIC_VECTOR(TO_UNSIGNED(random + 48, TX_Data'LENGTH));
                    TX_Enable <= '1';
                    state := 2;
                end if;
            elsif state = 2 then
                if TX_Busy = '1' then
                    TX_Enable <= '0';
                    state := 3;
                end if;
            elsif state = 3 then
                if TX_Busy = '0' then
                    state := 0;
                end if;
            end if;
        end if;
    end process;
    
    uart: UART_Interface
    generic map
    (
        CLK_Frequency => 12000000,
        Baud_Rate     => 19200,
        OS_Rate       => 16,
        D_Width       => 8,
        Parity        => 0,
        Parity_EO     => '0'
    )
    port map
    (
        CLK           => CLK,
        Reset         => '0',
        RX            => RX,
        TX            => TX,
        TX_Enable     => TX_Enable,
        TX_Busy       => TX_Busy,
        TX_Data       => TX_Data,
        RX_Busy       => RX_Busy,
        RX_Data       => RX_Data,
        RX_Error      => RX_Error
    );
    
    rand: Random_Number
    generic map
    (
        init_seed => x"0123456789abcdef0123456789abcdef",
        pipeline  => true
    )
    port map
    (
        clk       => CLK,
        
        out_data  => out_data
    );
    
    

end architecture rtl;