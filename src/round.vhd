----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD.ALL;

entity round is
    generic (
        G_BLOCK_SIZE    : integer := 16;
        G_KEY_SIZE      : integer := 32
    );
    Port ( 
        clk         :  in std_logic;

        i_key       :  in std_logic_vector(G_KEY_SIZE*8-1 downto 0);
        i_round_inp :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
        i_rnd_cnt   :  in std_logic_vector(3 downto 0);

        o_key       : out std_logic_vector(G_KEY_SIZE*8-1 downto 0);
        o_round_inp : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
        o_rnd_cnt   : out std_logic_vector(3 downto 0)
    );
end round;

architecture Behavioral of round is
    -- component declarations
    component sub_bytes is
        generic (
            G_BLOCK_SIZE    : integer := 16;
            G_KEY_SIZE      : integer := 32
        );
        Port ( 
            clk     :  in std_logic;
            i_data  :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
        );
    end component;
    component shift_rows is
        generic (
            G_BLOCK_SIZE    : integer := 16;
            G_KEY_SIZE      : integer := 32
        );
        Port ( 
            clk     :  in std_logic;
            i_data  :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
        );
    end component;
    component mix_columns is
        generic (
            G_BLOCK_SIZE    : integer := 16;
            G_KEY_SIZE      : integer := 32
        );
        Port ( 
            clk     :  in std_logic;
            i_data  :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
        );
    end component;
    component add_round_key is
        generic (
            G_BLOCK_SIZE    : integer := 16
        );
        Port ( 
            clk     :  in std_logic;
            i_data  :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            i_key   :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
        );
    end component;
    component key_gen is
        generic (
            G_BLOCK_SIZE    : integer := 16;
            G_KEY_SIZE      : integer := 32
        );
        Port ( 
            clk         :  in std_logic;
            i_key       :  in std_logic_vector(G_KEY_SIZE*8-1 downto 0);
            i_rnd_cnt   :  in std_logic_vector(3 downto 0);
            o_key       : out std_logic_vector(G_KEY_SIZE*8-1 downto 0);
            o_rnd_cnt   : out std_logic_vector(3 downto 0)
        );
    end component;    
    -- signal declarations
    signal add_round_key_out : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    signal sub_bytes_out     : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    signal shift_rows_out    : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    signal mix_columns_out   : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    signal key_gen_out       : std_logic_vector(G_KEY_SIZE*8-1 downto 0);
begin

    gen_sub_bytes: sub_bytes
        generic map (
            G_BLOCK_SIZE => G_BLOCK_SIZE,
            G_KEY_SIZE   => G_KEY_SIZE
        )
        port map (
            clk     => clk,
            i_data  => i_round_inp,
            o_data  => sub_bytes_out
        );
    gen_shift_rows: shift_rows  
        generic map (
            G_BLOCK_SIZE => G_BLOCK_SIZE,
            G_KEY_SIZE   => G_KEY_SIZE
        )
        port map (
            clk     => clk,
            i_data  => sub_bytes_out,
            o_data  => shift_rows_out
        );
    gen_mix_columns: mix_columns
        generic map (
            G_BLOCK_SIZE => G_BLOCK_SIZE,
            G_KEY_SIZE   => G_KEY_SIZE
        )
        port map (
            clk     => clk,
            i_data  => shift_rows_out,
            o_data  => mix_columns_out
        );

    gen_add_round_key: add_round_key
        generic map (
            G_BLOCK_SIZE => G_BLOCK_SIZE
        )
        port map (
            clk     => clk,
            i_data  => mix_columns_out,
            i_key   => key_gen_out(G_KEY_SIZE*8-1 downto G_KEY_SIZE*8-G_BLOCK_SIZE*8),
            o_data  => add_round_key_out
        );

    gen_key_gen: key_gen
        generic map (
            G_BLOCK_SIZE    => G_BLOCK_SIZE,
            G_KEY_SIZE      => G_KEY_SIZE
        )
        port map (
            clk         => clk,
            i_key       => i_key,
            i_rnd_cnt   => i_rnd_cnt,
            o_key       => key_gen_out,
            o_rnd_cnt   => o_rnd_cnt
        );


    --o_key <= key_gen_out;
    o_round_inp <= add_round_key_out;

    -- Process 
    process (clk) 
    begin
        if rising_edge(clk) then
            o_key <= key_gen_out;
        end if;
    end process;



end Behavioral;
