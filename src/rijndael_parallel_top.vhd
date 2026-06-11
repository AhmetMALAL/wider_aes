----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rijndael_parallel_top is
    generic (
        G_BLOCK_SIZE    : integer := 32;
        G_KEY_SIZE      : integer := 32;
        G_NUM_OF_CORES  : integer := 4
    );
    port (
        clk     : in std_logic;
        i_start : in std_logic_vector(G_NUM_OF_CORES-1 downto 0);
        i_key   : in std_logic_vector(G_NUM_OF_CORES*G_KEY_SIZE*8-1 downto 0);
        i_data  : in std_logic_vector(G_NUM_OF_CORES*G_BLOCK_SIZE*8-1 downto 0);
        o_data  : out std_logic_vector(G_NUM_OF_CORES*G_BLOCK_SIZE*8-1 downto 0);
        o_done  : out std_logic_vector(G_NUM_OF_CORES-1 downto 0)
    );
end rijndael_parallel_top;

architecture Behavioral of rijndael_parallel_top is

    component rijndael_top is
        generic (
            G_BLOCK_SIZE    : integer := 32;
            G_KEY_SIZE      : integer := 32
        );
        port (
            clk     : in std_logic;
            i_start : in std_logic;
            i_key   : in std_logic_vector(G_KEY_SIZE*8-1 downto 0);
            i_data  : in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_done  : out std_logic
        );
    end component;

begin   
    -- Generate the cores
    gen_rounds: for i in 1 to G_NUM_OF_CORES generate
        round_inst: entity work.rijndael_top
            generic map (
                G_BLOCK_SIZE => G_BLOCK_SIZE,
                G_KEY_SIZE   => G_KEY_SIZE
            )
            port map (
                clk     => clk,
                i_start => i_start(i-1),
                i_key   => i_key(i*G_KEY_SIZE*8-1 downto (i-1)*G_KEY_SIZE*8),
                i_data  => i_data(i*G_BLOCK_SIZE*8-1 downto (i-1)*G_BLOCK_SIZE*8),
                o_data  => o_data(i*G_BLOCK_SIZE*8-1 downto (i-1)*G_BLOCK_SIZE*8),
                o_done  => o_done(i-1)
            );
    end generate;


end Behavioral;
