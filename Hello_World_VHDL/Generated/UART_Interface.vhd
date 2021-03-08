  
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 


ENTITY UART_Interface IS
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
END UART_Interface;

ARCHITECTURE BEHAVIORAL OF UART_Interface IS

  TYPE    tx_machine      IS  (idle, transmit);                       
  TYPE    rx_machine      IS  (idle, receive);                        
  SIGNAL  tx_state        :   tx_machine;                             
  SIGNAL  rx_state        :   rx_machine;                             
  SIGNAL  baud_pulse      :   STD_LOGIC := '0';                       
  SIGNAL  os_pulse        :   STD_LOGIC := '0';                       
  SIGNAL  parity_error    :   STD_LOGIC;                              
  SIGNAL  rx_parity       :   STD_LOGIC_VECTOR(D_Width DOWNTO 0);     
  SIGNAL  tx_parity       :   STD_LOGIC_VECTOR(D_Width DOWNTO 0);     
  SIGNAL  rx_buffer       :   STD_LOGIC_VECTOR(Parity+D_Width DOWNTO 0) := (OTHERS => '0');   
  SIGNAL  tx_buffer       :   STD_LOGIC_VECTOR(Parity+D_Width+1 DOWNTO 0) := (OTHERS => '1');
  
BEGIN
  rx_parity(0) <= Parity_EO;
  tx_parity(0) <= Parity_EO;
  CLK_GENERATOR : PROCESS (CLK)  
    VARIABLE count_baud :   INTEGER RANGE 0 TO CLK_Frequency/Baud_Rate-1 := 0;          
    VARIABLE count_os   :   INTEGER RANGE 0 TO CLK_Frequency/Baud_Rate/OS_Rate-1 := 0;  

    
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (Reset = '1') THEN
      baud_pulse <= '0';                                                  
      os_pulse <= '0';                                                    
      count_baud := 0;                                                    
      count_os := 0;
    ELSE
      IF (count_baud < CLK_Frequency/Baud_Rate-1) THEN
        count_baud := count_baud + 1;                                   
        baud_pulse <= '0';
      ELSE
        count_baud := 0;                                                
        baud_pulse <= '1';                                              
        count_os := 0;
      END IF;
      IF (count_os < CLK_Frequency/Baud_Rate/OS_Rate-1) THEN
        count_os := count_os + 1;                                       
        os_pulse <= '0';
      ELSE
        count_os := 0;                                                  
        os_pulse <= '1';
      END IF;
    END IF;
  END IF;
  END PROCESS;
  RECEIVE_PROCESS : PROCESS (CLK)  
    VARIABLE rx_count   :   INTEGER RANGE 0 TO Parity+D_Width+2 := 0;       
    VARIABLE os_count   :   INTEGER RANGE 0 TO OS_Rate-1 := 0;              

    
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (Reset = '1') THEN
      os_count := 0;                                                      
      rx_count := 0;                                                      
      RX_Busy <= '0';                                                     
      RX_Error <= '0';                                                    
      RX_Data <= (OTHERS => '0');                                         
      rx_state <= idle;
    ELSIF (os_pulse = '1') THEN
      CASE (rx_state) IS
        WHEN idle =>
          RX_Busy <= '0';
          IF (RX = '0') THEN
            IF (os_count < OS_Rate/2) THEN
              os_count := os_count + 1;                           
              rx_state <= idle;
            ELSE
              os_count := 0;                                      
              rx_count := 0;                                      
              RX_Busy <= '1';                                     
              rx_state <= receive;
            END IF;
          ELSE
            os_count := 0;                                          
            rx_state <= idle;
          END IF;
        WHEN receive =>
          IF (os_count < OS_Rate-1) THEN
            os_count := os_count + 1;                               
            rx_state <= receive;
          ELSIF (rx_count < Parity+D_Width) THEN
            os_count := 0;                                              
            rx_count := rx_count + 1;                                   
            rx_buffer <= RX & rx_buffer(Parity+D_Width DOWNTO 1);       
            rx_state <= receive;
          ELSE
            RX_Data <= rx_buffer(D_Width DOWNTO 1);                     
            RX_Error <= rx_buffer(0) OR parity_error OR NOT RX;         
            RX_Busy <= '0';                                             
            rx_state <= idle;
          END IF;
        
      END CASE;
    
    END IF;
  END IF;
  END PROCESS;

  rx_parity_logic: FOR i IN 0 to D_Width-1 GENERATE
  rx_parity(i+1) <= rx_parity(i) XOR rx_buffer(i+1);
  END GENERATE;
  WITH Parity SELECT parity_error <= rx_parity(D_Width) XOR rx_buffer(Parity+D_Width) WHEN 1, '0' WHEN OTHERS;
  TRANSMIT_PROCESS : PROCESS (CLK)  
    VARIABLE tx_count   :   INTEGER RANGE 0 TO Parity+D_Width+3 := 0;
  BEGIN
  IF RISING_EDGE(CLK) THEN
    IF (Reset = '1') THEN
      tx_count := 0;                                                              
      TX <= '1';                                                                  
      TX_Busy <= '1';                                                             
      tx_state <= idle;
    ELSE
      CASE (tx_state) IS
        WHEN idle =>
          IF (TX_Enable = '1') THEN
            tx_buffer(D_Width+1 DOWNTO 0) <=  TX_Data & '0' & '1';
            IF (Parity = 1) THEN
              tx_buffer(Parity+D_Width+1) <= tx_parity(D_Width);
            END IF;
            TX_Busy <= '1';                                                 
            tx_count := 0;                                                  
            tx_state <= transmit;
          ELSE
            TX_Busy <= '0';                                                 
            tx_state <= idle;
          END IF;
        WHEN transmit =>
          IF (baud_pulse = '1') THEN
            tx_count := tx_count + 1;                                       
            tx_buffer <= '1' & tx_buffer(Parity+D_Width+1 DOWNTO 1);
          
          END IF;
          IF (tx_count < Parity+D_Width+3) THEN
            tx_state <= transmit;
          ELSE
            tx_state <= idle;
          END IF;
      END CASE;
      TX <= tx_buffer(0);
    END IF;
  END IF;
  END PROCESS;

  tx_parity_logic: FOR i IN 0 to D_Width-1 GENERATE
  tx_parity(i+1) <= tx_parity(i) XOR TX_Data(i);
  END GENERATE;
  
END BEHAVIORAL;