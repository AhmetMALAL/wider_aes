----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rijndael_top is
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
end rijndael_top;

architecture Behavioral of rijndael_top is

    function compute_latency(key_size : integer; block_size: integer) return integer is
    begin
        if key_size = 32 and block_size = 32 then
            return 126; --  Rijn(256,256) 14X9 = 126 
        elsif key_size = 32 and block_size = 16 then
            return 98;  --  Rijn(256,128) 14x7 = 98
        elsif key_size = 16 and block_size = 16 then
            return 70;  --  Rijn(128,128) 10x7 = 70 
        else 
            return 70;  -- default fallback
        end if;
    end function;

    function compute_num_of_rounds(key_size : integer; block_size : integer) return integer is
        variable Nk : integer := key_size / 4;
    begin
        if block_size = 16 then
            return Nk + 6;
        elsif block_size = 20 then
            if Nk = 4 or Nk = 5 then
                return 11;
            else
                return Nk + 6;
            end if;
        elsif block_size = 24 then
            if Nk = 4 or Nk = 5 then
                return 12;
            else
                return Nk + 6;
            end if;
        elsif block_size = 28 then
            if Nk = 4 or Nk = 5 or Nk = 6 then
                return 13;
            else
                return Nk + 6;
            end if;
        elsif block_size = 32 then
            return 14;
        else
            report "Invalid block size" severity failure;
            return 1; -- default fallback
        end if;
    end function;
    
    constant C_LATENCY : integer := compute_latency(G_KEY_SIZE,G_BLOCK_SIZE);    
    constant G_NUM_OF_ROUNDS : integer := compute_num_of_rounds(G_KEY_SIZE,G_BLOCK_SIZE);    

    -- Type definitions for signal arrays across pipeline stages
    type data_array_t is array (0 to G_NUM_OF_ROUNDS) of std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    type key_array_t is array (0 to G_NUM_OF_ROUNDS) of std_logic_vector(G_KEY_SIZE*8-1 downto 0);
    type count_array_t is array (0 to G_NUM_OF_ROUNDS) of std_logic_vector(3 downto 0);

    -- Signals to connect stages
    signal data_pipe : data_array_t;
    signal key_pipe  : key_array_t;
    signal cnt_pipe  : count_array_t;
    signal data      : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    signal key       : std_logic_vector(G_KEY_SIZE*8-1 downto 0);

    signal o_valid_pipe : std_logic_vector(C_LATENCY-1 downto 0) := (others => '0'); 
begin

    process (clk) 
    begin
        if rising_edge(clk) then
            o_valid_pipe <= o_valid_pipe(C_LATENCY-2 downto 0) & i_start;
            o_done <= o_valid_pipe(C_LATENCY-1);
            data <= i_data;
            key <= i_key;
        end if;
    end process;

    -- Initial input assignment
    data_pipe(0) <= data xor key(G_KEY_SIZE*8-1 downto G_KEY_SIZE*8-G_BLOCK_SIZE*8);
    key_pipe(0)  <= key;
    cnt_pipe(0)  <= (others => '0');

    -- Generate the rounds
    gen_rounds: for i in 0 to G_NUM_OF_ROUNDS - 2 generate
        round_inst: entity work.round
            generic map (
                G_BLOCK_SIZE => G_BLOCK_SIZE,
                G_KEY_SIZE   => G_KEY_SIZE
            )
            port map (
                clk         => clk,
                i_key       => key_pipe(i),
                i_round_inp => data_pipe(i),
                i_rnd_cnt   => cnt_pipe(i),
                o_key       => key_pipe(i+1),
                o_round_inp => data_pipe(i+1),
                o_rnd_cnt   => cnt_pipe(i+1)
            );
    end generate;

    last_round_inst: entity work.round_last
        generic map (
            G_BLOCK_SIZE => G_BLOCK_SIZE,
            G_KEY_SIZE   => G_KEY_SIZE
        )
        port map (
            clk         => clk,
            i_key       => key_pipe(G_NUM_OF_ROUNDS - 1),
            i_round_inp => data_pipe(G_NUM_OF_ROUNDS - 1),
            i_rnd_cnt   => cnt_pipe(G_NUM_OF_ROUNDS - 1),
            o_round_inp => data_pipe(G_NUM_OF_ROUNDS)
        );

    o_data <= data_pipe(G_NUM_OF_ROUNDS);

end Behavioral;
