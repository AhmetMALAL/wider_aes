library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mix_columns_tb is
end mix_columns_tb;

architecture behavior of mix_columns_tb is

    -- Constants
    constant C_CLK_PERIOD : time := 10 ns;

    -- Component under test
    component mix_columns
        generic (
            G_BLOCK_SIZE : integer := 16
        );
        port (
            clk     : in  std_logic;
            i_data  : in  std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
        );
    end component;

    -- Signals
    signal clk     : std_logic := '0';
    signal i_data  : std_logic_vector(127 downto 0) := (others => '0');
    signal o_data  : std_logic_vector(127 downto 0);

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: mix_columns
        generic map (
            G_BLOCK_SIZE => 16
        )
        port map (
            clk     => clk,
            i_data  => i_data,
            o_data  => o_data
        );

    -- Clock process
    clk_process : process
    begin
        while now < 200 ns loop
            clk <= '0';
            wait for C_CLK_PERIOD / 2;
            clk <= '1';
            wait for C_CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        wait for 20 ns;

        -- Example test vector (can replace with known plaintext for MixColumns)
        i_data <= x"00112233445566778899aabbccddeeff"; -- Example input
        wait for C_CLK_PERIOD;

        -- You can add more test vectors here
        wait for 50 ns;

        -- Finish simulation
        wait;
    end process;

end behavior;
