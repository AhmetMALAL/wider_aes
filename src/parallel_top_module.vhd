----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity parallel_top_module is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        i_data_in  : in  std_logic_vector(31 downto 0);  -- 32-bit input
        i_key_in   : in  std_logic_vector(31 downto 0);  -- 32-bit key input
        i_load     : in  std_logic;                      -- triggers loading of chunks
        i_start    : in  std_logic;                      -- triggers encryption
        o_data_out : out std_logic_vector(31 downto 0);  -- 32-bit output
        o_valid    : out std_logic                       -- valid when output is ready
    );
end parallel_top_module;

architecture Behavioral of parallel_top_module is

    -- Component declaration for rijndael_top
    component rijndael_parallel_top is
        generic (
            G_BLOCK_SIZE    : integer := 32;
            G_KEY_SIZE      : integer := 32;
            G_NUM_OF_CORES  : integer := 2
        );
        port (
            clk     : in std_logic;
            i_start : in std_logic_vector(G_NUM_OF_CORES-1 downto 0);
            i_key   : in std_logic_vector(G_NUM_OF_CORES*G_KEY_SIZE*8-1 downto 0);
            i_data  : in std_logic_vector(G_NUM_OF_CORES*G_BLOCK_SIZE*8-1 downto 0);
            o_data  : out std_logic_vector(G_NUM_OF_CORES*G_BLOCK_SIZE*8-1 downto 0);
            o_done  : out std_logic_vector(G_NUM_OF_CORES-1 downto 0)
        );
    end component;
    
    -- Constants
    constant G_BLOCK_SIZE   : integer := 32;    -- 
    constant G_KEY_SIZE     : integer := 32;    -- 
    constant G_NUM_OF_CORES : integer := 2;    -- 
    constant BLOCK_WORDS    : integer := G_KEY_SIZE; 

    -- Signals for input buffering
    signal par_key_buffer      : std_logic_vector(G_NUM_OF_CORES*G_KEY_SIZE*8-1 downto 0) := (others => '0');
    signal par_data_buffer     : std_logic_vector(G_NUM_OF_CORES*G_BLOCK_SIZE*8-1 downto 0) := (others => '0');
    signal par_output_data     : std_logic_vector(G_NUM_OF_CORES*G_BLOCK_SIZE*8-1 downto 0);
    signal par_start_reg       : std_logic_vector(G_NUM_OF_CORES-1 downto 0) := (others => '0');
    signal par_encryption_done : std_logic_vector(G_NUM_OF_CORES-1 downto 0);
    constant par_done_expected : std_logic_vector(G_NUM_OF_CORES-1 downto 0) := (others => '1');

    -- Output index tracking
    signal out_index            : integer range 0 to G_NUM_OF_CORES*BLOCK_WORDS - 1 := 0;
    signal load_count           : integer range 0 to G_NUM_OF_CORES*BLOCK_WORDS := 0;

begin

    -- Rijndael Parallel core instance
    uut_rijndael_parallel: rijndael_parallel_top
    generic map (
        G_BLOCK_SIZE    => G_BLOCK_SIZE,
        G_KEY_SIZE      => G_KEY_SIZE,
        G_NUM_OF_CORES  => G_NUM_OF_CORES
    )
    port map (
        clk     => clk,
        i_start => par_start_reg,
        i_key   => par_key_buffer,
        i_data  => par_data_buffer,
        o_data  => par_output_data,
        o_done  => par_encryption_done
    );

    -- Input loading and control logic
    process(clk, rst)
    begin
        if rst = '1' then
            load_count       <= 0;
            par_key_buffer   <= (others => '0');
            par_data_buffer  <= (others => '0');
            par_start_reg    <= (others => '0');
        elsif rising_edge(clk) then
            -- Load data/key in 32-bit chunks
            if i_load = '1' then
                par_key_buffer((G_NUM_OF_CORES*BLOCK_WORDS - 1 - load_count)*32 + 31 downto (G_NUM_OF_CORES*BLOCK_WORDS - 1 - load_count)*32) <= i_key_in;
                par_data_buffer((G_NUM_OF_CORES*BLOCK_WORDS - 1 - load_count)*32 + 31 downto (G_NUM_OF_CORES*BLOCK_WORDS - 1 - load_count)*32) <= i_data_in;
                if load_count = G_NUM_OF_CORES*BLOCK_WORDS - 1 then
                    load_count <= 0;
                else
                    load_count <= load_count + 1;
                end if;
            end if;
            -- Start encryption
            if i_start = '1' then
                par_start_reg <= (others=>'1');
            else
                par_start_reg <= (others=>'0');
            end if;
        end if;
    end process;

    -- Output logic
    process(clk, rst)
    begin
        if rst = '1' then
            o_data_out   <= (others => '0');
            o_valid      <= '0';
            out_index    <= 0;
        elsif rising_edge(clk) then
            if par_encryption_done = par_done_expected then
                o_data_out <= par_output_data((G_NUM_OF_CORES*BLOCK_WORDS - 1 - out_index)*32 + 31 downto (G_NUM_OF_CORES*BLOCK_WORDS - 1 - out_index)*32);
                o_valid    <= '1';

                if out_index = G_NUM_OF_CORES*BLOCK_WORDS - 1 then
                    out_index <= 0;
                else
                    out_index <= out_index + 1;
                end if;
            else
                o_data_out <= (others => '0');
                o_valid    <= '0';
            end if;
        end if;
    end process;

end Behavioral;
