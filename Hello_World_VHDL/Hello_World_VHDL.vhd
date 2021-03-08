library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Hello_World_VHDL is
    port(
        CLK     : IN  STD_LOGIC := '0';
        UART_TX : OUT STD_LOGIC := '1'
    );
end entity Hello_World_VHDL;

architecture rtl of Hello_World_VHDL is
    SIGNAL MyString           : STD_LOGIC_VECTOR(103 downto 0) := x"48656c6c6f20576f726c64210a";
    
    SIGNAL UART_TX_Enable     : STD_LOGIC := '0';
    SIGNAL UART_TX_Busy       : STD_LOGIC := '0';
    SIGNAL UART_TX_Data       : STD_LOGIC_VECTOR (8-1 DOWNTO 0) := (others => '0');
    
    TYPE States is (Char_Select, Send, Delay);
    
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
    
begin

    HW_Send: process(CLK)
    VARIABLE charCounter   : NATURAL range 0 to (MyString'LENGTH)/8 := (MyString'LENGTH)/8;
    VARIABLE State         : States := Char_Select;
    VARIABLE Delay_Counter : NATURAL range 0 to 12000000 := 0;
    begin
        if rising_edge(CLK) then
            case State is
                when Char_Select =>
                    UART_TX_Data   <= MyString(charCounter*8-1 downto charCounter*8-8);
                    UART_TX_Enable <= '1';
                    if UART_TX_Busy = '1' then
                        State      := Send;
                    end if;
                when Send =>
                    UART_TX_Enable <= '0';
                    if UART_TX_Busy = '0' then
                        if charCounter > 1 then
                            charCounter := charCounter - 1;
                            State       := Char_Select;
                        else
                            charCounter := (MyString'LENGTH)/8;
                            State       := Delay;
                        end if;
                    end if;
                when Delay =>
                    if Delay_Counter < 12000000 then
                        Delay_Counter := Delay_Counter + 1;
                    else
                        Delay_Counter := 0;
                        State         := Char_Select;
                    end if;
            end case;
        end if;
    end process HW_Send;
    
    UART_0: UART_Interface
    generic map
    (
        CLK_Frequency => 12000000,
        Baud_Rate     => 19200
    )
    port map
    (
        CLK           => CLK,
        TX            => UART_TX,
        TX_Enable     => UART_TX_Enable,
        TX_Busy       => UART_TX_Busy,
        TX_Data       => UART_TX_Data
    );
    
end architecture rtl;