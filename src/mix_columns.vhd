----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mix_columns is
    generic (
        G_BLOCK_SIZE    : integer := 16;
        G_KEY_SIZE      : integer := 32
    );
    Port ( 
        clk     :  in std_logic;
        i_data  :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
        o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
    );
end mix_columns;

architecture Behavioral of mix_columns is

    --component declarations
    component mix_column is
        Port ( 
            clk     :  in std_logic;
            i_data  :  in std_logic_vector(31 downto 0);
            o_data  : out std_logic_vector(31 downto 0)
        );
    end component;
    --signal declarations
    signal o_state : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
begin

    gen_mix_column: for i in 0 to G_BLOCK_SIZE/4-1 generate
        mix_column_inst: mix_column
            port map (
                clk     => clk,
                i_data  => i_data(i_data'high-32*i downto i_data'length-32*i-32),
                o_data  => o_state(o_state'high-32*i downto o_state'length-32*i-32)
            );
    end generate;

    gen_G_G_BLOCK_SIZE_16: if G_BLOCK_SIZE = 16 generate
        o_data  <= o_state;
    end generate;

    gen_G_G_BLOCK_SIZE_32: if G_BLOCK_SIZE = 32 generate
        prc_mc: process(clk) begin
            if rising_edge(clk) then 
                o_data  <= o_state;
            end if; 
        end process;
    end generate;

end Behavioral;
