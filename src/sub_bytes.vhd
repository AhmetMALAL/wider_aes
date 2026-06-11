----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity sub_bytes is
    generic (
        G_BLOCK_SIZE    : integer := 16;
        G_KEY_SIZE      : integer := 32
    );
    Port ( 
        clk     :  in std_logic;
        i_data  :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
        o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
    );
end sub_bytes;

architecture Behavioral of sub_bytes is
 

    component sbox is
        Port ( 
            clk     :  in std_logic;
            i_data  :  in std_logic_vector(7 downto 0);
            o_data  : out std_logic_vector(7 downto 0)
        );
    end component;

begin

    gen_sbox: for i in 0 to G_BLOCK_SIZE-1 generate
        sbox_inst: sbox
            port map (
                clk     => clk,
                i_data  => i_data(i*8+7 downto i*8),
                o_data  => o_data(i*8+7 downto i*8)
            );
    end generate;

end Behavioral;
