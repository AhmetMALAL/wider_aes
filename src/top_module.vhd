----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
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
end top_module;

architecture Behavioral of top_module is

    -- Component declaration for rijndael_top
    component rijndael_top is
        generic (
            G_BLOCK_SIZE   : integer := 32;
            G_KEY_SIZE     : integer := 32
        );
        port (
            clk      : in  std_logic;
            i_start  : in  std_logic;
            i_key    : in  std_logic_vector(G_KEY_SIZE*8-1 downto 0);
            i_data   : in  std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_data   : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_done   : out std_logic
        );
    end component;

    -- Constants
    constant G_BLOCK_SIZE   : integer := 32;    -- 
    constant G_KEY_SIZE     : integer := 32;    -- 

    constant BLOCK_WORDS    : integer := 8; 

    -- Signals for input buffering
    signal key_buffer      : std_logic_vector(G_KEY_SIZE*8-1 downto 0) := (others => '0');
    signal data_buffer     : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0) := (others => '0');
    signal output_data     : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    signal load_count      : integer range 0 to BLOCK_WORDS := 0;

    -- Control signals
    signal start_reg       : std_logic := '0';
    signal encryption_done : std_logic;

    -- Output index tracking
    signal out_index       : integer range 0 to BLOCK_WORDS - 1 := 0;

    -- Output valid flag
    signal output_valid    : std_logic := '0';

begin

    -- Rijndael core instance
    uut_rijndael: rijndael_top
        generic map (
            G_BLOCK_SIZE    => G_BLOCK_SIZE,
            G_KEY_SIZE      => G_KEY_SIZE
        )
        port map (
            clk     => clk,
            i_start => start_reg,
            i_key   => key_buffer,
            i_data  => data_buffer,
            o_data  => output_data,
            o_done  => encryption_done
        );

    -- Input loading and control logic
    process(clk, rst)
    begin
        if rst = '1' then
            load_count   <= 0;
            key_buffer   <= (others => '0');
            data_buffer  <= (others => '0');
            start_reg    <= '0';
        elsif rising_edge(clk) then
            -- Load data/key in 32-bit chunks
            if i_load = '1' then
                key_buffer((7 - load_count)*32 + 31 downto (7 - load_count)*32) <= i_key_in;
                data_buffer((7 - load_count)*32 + 31 downto (7 - load_count)*32) <= i_data_in;
                if load_count = BLOCK_WORDS - 1 then
                    load_count <= 0;
                else
                    load_count <= load_count + 1;
                end if;
            end if;

            -- Start encryption
            if i_start = '1' then
                start_reg <= '1';
            else
                start_reg <= '0';
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
            output_valid <= '0';
        elsif rising_edge(clk) then
            if encryption_done = '1' then
                o_data_out <= output_data((7 - out_index)*32 + 31 downto (7 - out_index)*32);
                o_valid    <= '1';
                output_valid <= '1';

                if out_index = BLOCK_WORDS - 1 then
                    out_index <= 0;
                else
                    out_index <= out_index + 1;
                end if;
            else
                o_data_out <= (others => '0');
                o_valid    <= '0';
                output_valid <= '0';
            end if;
        end if;
    end process;

end Behavioral;
