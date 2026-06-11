----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multby2 is
    Port ( 
        clk     :  in std_logic;
        i_data  :  in std_logic_vector(7 downto 0);
        o_data  : out std_logic_vector(7 downto 0)
    );
end multby2;

architecture Behavioral of multby2 is

    constant C_IRR_POLY : std_logic_vector(7 downto 0) := x"1b";
begin

    process (clk) 
    begin
        if rising_edge(clk) then
            if i_data(7) = '1' then
                o_data <= (i_data(6 downto 0) & '0') xor C_IRR_POLY;
            else
                o_data <= (i_data(6 downto 0) & '0');
            end if;
        end if;
    end process;

end Behavioral;
