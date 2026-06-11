----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add_round_key is
    generic (
        G_BLOCK_SIZE    : integer := 16
    );
    Port ( 
        clk     :  in std_logic;
        i_data  :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
        i_key   :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
        o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
    );
end add_round_key;

architecture Behavioral of add_round_key is

begin

    prc_sox: process(clk) begin
        if rising_edge(clk) then 
            o_data  <= i_data xor i_key;
        end if; 
    end process;
            
end Behavioral;
