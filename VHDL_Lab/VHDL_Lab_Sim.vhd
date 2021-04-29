
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;


ENTITY VHDL_Lab_tb IS
END VHDL_Lab_tb;

ARCHITECTURE BEHAVIORAL OF VHDL_Lab_tb IS

    SIGNAL finished : STD_LOGIC:= '0';
    CONSTANT period_time : TIME := 83333 ps;
    SIGNAL CLK : std_logic ;
    SIGNAL LED : std_logic  := '0';
    SIGNAL RX : STD_LOGIC  := '1';
    SIGNAL TX : STD_LOGIC  := '1';
    SIGNAL UART_Interface_TX_Enable     : STD_LOGIC := '0';
    SIGNAL UART_Interface_TX_Busy       : STD_LOGIC := '0';
    SIGNAL UART_Interface_TX_Data       : STD_LOGIC_VECTOR (8-1 DOWNTO 0) := (others => '0');
    
    COMPONENT VHDL_Lab IS
        
        PORT (
            CLK : in     std_logic;
            LED : buffer std_logic := '0';
            RX            : IN STD_LOGIC  := '1';
            TX            : OUT STD_LOGIC  := '1'
        );
    END COMPONENT;
    
    COMPONENT UART_Interface IS
        GENERIC (
            CLK_Frequency   :   INTEGER     := 12000000;
            Baud_Rate       :   INTEGER     := 19200;
            OS_Rate         :   INTEGER     := 16;
            D_Width         :   INTEGER     := 8;
            Parity          :   INTEGER     := 0;
            Parity_EO       :   STD_LOGIC   := '0'
        );
        PORT (
            CLK : IN STD_LOGIC;
            Reset       : IN    STD_LOGIC := '0';
            RX          : IN    STD_LOGIC := '1';
            TX          : OUT   STD_LOGIC := '1';
            TX_Enable   : IN    STD_LOGIC := '0';
            TX_Busy     : OUT   STD_LOGIC := '0';
            TX_Data     : IN    STD_LOGIC_VECTOR(D_Width-1 DOWNTO 0) := (others => '0');
            RX_Busy     : OUT   STD_LOGIC := '0';
            RX_Data     : OUT   STD_LOGIC_VECTOR(D_Width-1 DOWNTO 0) := (others => '0');
            RX_Error    : OUT   STD_LOGIC := '0'
        );
    END COMPONENT;
    
BEGIN
    Sim_finished : PROCESS
    BEGIN
        wait for 10000 us;
        finished <= '1';
        wait;
    END PROCESS;
    
    VHDL_Lab1 : VHDL_Lab  PORT MAP (
        CLK => CLK,
        LED => LED,
        RX => RX,
        TX => TX
    );
    
    Sim_CLK : PROCESS
    BEGIN
        WHILE finished /= '1' LOOP
            CLK <= '1';
            wait for 83333 ps;
            CLK <= '0';
            wait for 83333 ps;
        END LOOP;
        
        wait;
    END PROCESS;
    
    PROCESS
    VARIABLE Thread7 : NATURAL range 0 to 5 := 0;
    BEGIN
        wait until rising_edge(clk);
        CASE (Thread7) IS
            WHEN 0 =>UART_Interface_TX_Data <= x"36";
                UART_Interface_TX_Enable <= '1';
                Thread7 := 1;
            WHEN 1 =>
                IF (UART_Interface_TX_Busy = '0') THEN
                ELSE
                    Thread7 := Thread7 + 1;
                END IF;
            WHEN 2 =>
                UART_Interface_TX_Enable <= '0';
                Thread7 := 3;
            WHEN 3 =>
                IF (UART_Interface_TX_Busy = '1') THEN
                ELSE
                    Thread7 := Thread7 + 1;
                END IF;
            WHEN 4 =>
                wait;
                Thread7 := 0;
            WHEN others => Thread7 := 0;
        END CASE;
    END PROCESS;
    
    UART_Interface1 : UART_Interface
    GENERIC MAP (
        CLK_Frequency => 12000000,
        Baud_Rate     => 19200,
        OS_Rate       => 16,
        D_Width       => 8,
        Parity        => 0,
        Parity_EO     => '0'
    ) PORT MAP (
        CLK => CLK,
        TX            => RX,
        TX_Enable     =>UART_Interface_TX_Enable,
        TX_Busy       =>UART_Interface_TX_Busy,
        TX_Data       =>UART_Interface_TX_Data
    );
    
END BEHAVIORAL;