----------------------------------------------------------------------------------
-- Testbench for mix_columns
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity tb_rijndael is
end tb_rijndael;

architecture Behavioral of tb_rijndael is

    -- Component Declaration for the Unit Under Test (UUT)
    component rijndael_top
        generic (
            G_BLOCK_SIZE    : integer := 32;
            G_KEY_SIZE      : integer := 32
        );
        Port ( 
            clk     : in std_logic;
            i_start : in std_logic;
            i_key   : in std_logic_vector(G_KEY_SIZE*8-1 downto 0);
            i_data  : in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_done  : out std_logic
        );
    end component;

    component rijndael_parallel_top is
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
    end component;

    -- Constants
    constant CLK_PERIOD     : time := 10 ns;    -- 100 MHz clock

    constant G_BLOCK_SIZE   : integer := 32;    -- 
    constant G_KEY_SIZE     : integer := 32;    -- 
    constant G_NUM_OF_CORES : integer := 4;    -- 

    -- Signals
    signal rst     : std_logic := '0';
    signal clk     : std_logic := '0';

    signal i_par_alg_inp    : std_logic_vector(G_NUM_OF_CORES*G_BLOCK_SIZE*8-1 downto 0) := (2=>'1',others => '0');
    signal o_par_alg_out    : std_logic_vector(G_NUM_OF_CORES*G_BLOCK_SIZE*8-1 downto 0);
    signal i_par_key        : std_logic_vector(G_NUM_OF_CORES*G_KEY_SIZE*8-1 downto 0) := (0 => '1', 1 => '1', others => '0');
    signal i_par_start      : std_logic_vector(G_NUM_OF_CORES-1 downto 0):= (others=>'0'); 
    signal o_par_done       : std_logic_vector(G_NUM_OF_CORES-1 downto 0);

    signal i_alg_inp : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0) := (2=>'1',others => '0');
    signal o_alg_out : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    signal i_key : std_logic_vector(G_KEY_SIZE*8-1 downto 0) := (0 => '1', 1 => '1', others => '0');
    signal i_start : std_logic := '0';
    signal o_done : std_logic;
    signal temp_ctr : integer := 0;
    signal check : boolean := TRUE;

    constant C_NUM_OF_TESTS : integer := 8;
    type t_array_128 is array (0 to C_NUM_OF_TESTS-1) of std_logic_vector(127 downto 0);
    type t_array_256 is array (0 to C_NUM_OF_TESTS-1) of std_logic_vector(255 downto 0);

    constant expected_b32k32 : t_array_256 := (--(rijndael-256,256)
        -- pre_computed values for 256-bit block; 256-bit key 
        x"9b64ac976508363a7f413c8c2c35d949a805e58c24217d8782fd023d43388ca2", 
        x"57c0144c818b33f1a776376d39f5e3aee1192bcb98775f2bcc951f3286776919",
        x"31cd231b839ce857d078cccef9eac2b92db4f22fca4256d3320443deff6355db",
        x"115f56000b719d1969b7740c1e28ac59695a2c036c658306858dbd976bbe9664",
        x"1f13e30a14983ab129018c390edec82edd522a87af1543e59663d8715a367feb",
        x"4ef870b2ac8f597357502b4bc4cc40ec4239996d3c27f3a3e76204f066d5f2fc",
        x"3d55f5c7af1f2ab7296f110be0771e86a6069bbe40bd70961d37bd63f9d89be9",
        x"cb426e788c980876b51219b302142025277bcf59cab65afbf31f567029062287"
    );
    constant expected_b16k16 : t_array_128 := (--(rijndael-128,128)
        -- pre_computed values for 128-bit block; 128-bit key 
        x"e4433c76dd6b8440b218b74df27ddfc5", 
        x"90755a620011e7968e9c4a19b68f50eb",
        x"afd9d94764c222dccbf6cc2524d0dde1",
        x"d35bf9aa866af5e9c1854edb4dda36f9",
        x"fb6e0728c057dafbcee96db871d974d6",
        x"5ed2e8af890cc5a3490e086b90bf6e17",
        x"024e3ae1876ecec4f63f52cf8852b8e3",
        x"a382c6f94ec0af50b22bac1f2df90d37"
    );
    constant expected_b16k32 : t_array_128 := (--rijndael-(128,256)
        -- pre_computed values for 128-bit block; 256-bit key 
        x"e9e0405eff807fb926df027da373e00d", 
        x"6f3cf24ea0de3f632e9c8917ea3afd6e",
        x"dd7c3ad353579349c3a2ade767a3a23c",
        x"72095fdaa8e48108284db8cfd3d6eb0a",
        x"4b8557025adca1dadeac8ef6a0857c87",
        x"60ade6f34a832aaa4b4583044401438c",
        x"e207da02a59340c1b1d5a946ee95993d",
        x"80e593b850662b2c38118c3d5ca67cc9"
    );

    signal index : integer range 0 to C_NUM_OF_TESTS := 0;

begin

    process (rst, clk)
    begin
        if rst = '1' then
            temp_ctr <= 0;
        elsif rising_edge(clk) then
            temp_ctr <= temp_ctr + 1;
        end if;
    end process;
    
    -- DUT Instantiation
    rijndael_top_inst: rijndael_top
    generic map(
        G_BLOCK_SIZE    => G_BLOCK_SIZE,
        G_KEY_SIZE      => G_KEY_SIZE
        )
     port map(
        clk     => clk,
        i_start => i_start,
        i_key   => i_key,
        i_data  => i_alg_inp,
        o_data  => o_alg_out,
        o_done  => o_done
    );

    -- DUT Instantiation
--    rijndael_parallel_top_inst: rijndael_parallel_top
--    generic map(
--        G_BLOCK_SIZE    => G_BLOCK_SIZE,
--        G_KEY_SIZE      => G_KEY_SIZE,
--        G_NUM_OF_CORES  => G_NUM_OF_CORES
--    )
--    port map(
--        clk     => clk,
--        i_start => i_par_start,
--        i_key   => i_par_key,
--        i_data  => i_par_alg_inp,
--        o_data  => o_par_alg_out,
--        o_done  => o_par_done
--    );

    process (clk)
    begin   
        if rst = '1' then
            i_key <= (others => '0');
            i_alg_inp <= (others => '0');
        elsif rising_edge(clk) then
            if temp_ctr mod 4 = 0 or temp_ctr mod 5 = 0 then
                i_key       <= (0 => '1', 1 => '1', others => '0');
                i_alg_inp <= std_logic_vector(unsigned(i_alg_inp)+1);
                i_start <= '1';
                i_par_start <= (others=>'1');
            else
                i_start <= '0';
            end if;
        end if;
        
    end process;

    -- Clock Process
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Reset Process
    rst_process: process
    begin
        rst <= '1';
        wait for 10*CLK_PERIOD;
        wait until rising_edge(clk);
        rst <= '0'; 
        wait;
    end process;


    process (clk)
    begin
        if rising_edge(clk) then
            if o_done = '1' then
                if index < C_NUM_OF_TESTS then
                    if G_BLOCK_SIZE = 32 and G_KEY_SIZE = 32 then
                        if o_alg_out = expected_b32k32(index)(G_BLOCK_SIZE*C_NUM_OF_TESTS-1 downto 0) then
                            check <= True;
                            report "Encryption successful!" severity note;
                        else
                            check <= False;
                            report "Encryption failed!" severity error;
                        end if;
                    elsif G_BLOCK_SIZE = 16 and G_KEY_SIZE = 16 then
                        if o_alg_out = expected_b16k16(index)(G_BLOCK_SIZE*C_NUM_OF_TESTS-1 downto 0) then
                            check <= True;
                            report "Encryption successful!" severity note;
                        else
                            check <= False;
                            report "Encryption failed!" severity error;
                        end if;
                    elsif G_BLOCK_SIZE = 16 and G_KEY_SIZE = 32 then
                        if o_alg_out = expected_b16k32(index)(G_BLOCK_SIZE*C_NUM_OF_TESTS-1 downto 0) then
                            check <= True;
                            report "Encryption successful!" severity note;
                        else
                            check <= False;
                            report "Encryption failed!" severity error;
                        end if;
                    end if;
                    index <= index + 1;
                end if;

                if index = C_NUM_OF_TESTS then
                    report "All tests completed!" severity note;
                    assert false report "End of Simulation" severity failure;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
