library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sbox_tb is
end sbox_tb;

architecture sim of sbox_tb is

    component sbox
        Port ( 
            clk     : in  std_logic;
            i_data  : in  std_logic_vector(7 downto 0);
            o_data  : out std_logic_vector(7 downto 0)
        );
    end component;

    signal clk     : std_logic := '0';
    signal i_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal o_data  : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    type ByteArray is array (natural range <>) of std_logic_vector(7 downto 0);
    constant inputs    : ByteArray := (x"00", x"01", x"02", x"03", x"04", x"FF");
    constant expected  : ByteArray := (x"63", x"7C", x"77", x"7B", x"F2", x"16");
    constant NUM_TESTS : integer := inputs'length;

begin

    -- Instantiate DUT
    uut: sbox
        port map (
            clk    => clk,
            i_data => i_data,
            o_data => o_data
        );

    -- Clock Process
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus and checker
    stimulus : process
    begin

        wait until rising_edge(clk);
        
        for i in 0 to NUM_TESTS - 1 loop
            -- Apply input
            i_data <= inputs(i);
            wait until rising_edge(clk);
        end loop;

        wait;
    end process;

end sim;
