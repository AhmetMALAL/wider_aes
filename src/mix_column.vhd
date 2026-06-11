----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mix_column is
    Port ( 
        clk     :  in std_logic;
        i_data  :  in std_logic_vector(31 downto 0);
        o_data  : out std_logic_vector(31 downto 0)
    );
end mix_column;

architecture Behavioral of mix_column is

    -- Component declarations
    component multby2 is
        Port ( 
            clk     :  in std_logic;
            i_data  :  in std_logic_vector(7 downto 0);
            o_data  : out std_logic_vector(7 downto 0)
        );
    end component;
    component multby3 is
        Port ( 
            clk     :  in std_logic;
            i_data  :  in std_logic_vector(7 downto 0);
            o_data  : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Signal declarations
    signal inp0 : std_logic_vector(7 downto 0);
    signal inp1 : std_logic_vector(7 downto 0);
    signal inp2 : std_logic_vector(7 downto 0);
    signal inp3 : std_logic_vector(7 downto 0);

    signal inp0by2 : std_logic_vector(7 downto 0);
    signal inp1by2 : std_logic_vector(7 downto 0);
    signal inp2by2 : std_logic_vector(7 downto 0);
    signal inp3by2 : std_logic_vector(7 downto 0);

    signal inp0by3 : std_logic_vector(7 downto 0);
    signal inp1by3 : std_logic_vector(7 downto 0);
    signal inp2by3 : std_logic_vector(7 downto 0);
    signal inp3by3 : std_logic_vector(7 downto 0);

    signal col : std_logic_vector(31 downto 0);
    
begin   
    gen_inp0by2: multby2 port map (clk => clk, i_data => i_data(31 downto 24), o_data  => inp0by2);
    gen_inp1by2: multby2 port map (clk => clk, i_data => i_data(23 downto 16), o_data  => inp1by2);
    gen_inp2by2: multby2 port map (clk => clk, i_data => i_data(15 downto  8), o_data  => inp2by2);
    gen_inp3by2: multby2 port map (clk => clk, i_data => i_data( 7 downto  0), o_data  => inp3by2);
    gen_inp0by3: multby3 port map (clk => clk, i_data => i_data(31 downto 24), o_data  => inp0by3);
    gen_inp1by3: multby3 port map (clk => clk, i_data => i_data(23 downto 16), o_data  => inp1by3);
    gen_inp2by3: multby3 port map (clk => clk, i_data => i_data(15 downto  8), o_data  => inp2by3);
    gen_inp3by3: multby3 port map (clk => clk, i_data => i_data( 7 downto  0), o_data  => inp3by3);
    
    col(31 downto 24) <= inp0by2 xor inp1by3 xor inp2 xor inp3;
    col(23 downto 16) <= inp1by2 xor inp2by3 xor inp0 xor inp3;
    col(15 downto  8) <= inp2by2 xor inp3by3 xor inp0 xor inp1;
    col( 7 downto  0) <= inp3by2 xor inp0by3 xor inp1 xor inp2;

    process (clk)
    begin
        if rising_edge(clk) then
                inp0    <= i_data(31 downto 24);
                inp1    <= i_data(23 downto 16);
                inp2    <= i_data(15 downto  8);        
                inp3    <= i_data( 7 downto  0);
                o_data  <= col;
        end if;
    end process;



end Behavioral;
