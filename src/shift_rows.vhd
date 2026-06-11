----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity shift_rows is
    generic (
        G_BLOCK_SIZE : integer := 16;
        G_KEY_SIZE   : integer := 32
    );
    port (
        clk     : in  std_logic;
        i_data  : in  std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
        o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
    );
end shift_rows;

architecture behavioral of shift_rows is

    -- Function to perform cyclic left rotation on a row
    function rot_left(row : std_logic_vector(G_BLOCK_SIZE*2-1 downto 0); shift_amount : integer) return std_logic_vector is
        variable rotated : std_logic_vector(G_BLOCK_SIZE*2-1 downto 0);
    begin
        rotated := row;
        for i in 1 to shift_amount loop
            rotated := rotated(G_BLOCK_SIZE*2-1-8 downto 0) & rotated(G_BLOCK_SIZE*2-1 downto G_BLOCK_SIZE*2-8); -- Shift left by one byte
        end loop;
        return rotated;
    end function;

    -- Function to perform cyclic left rotation on a row
    function get_byte(state : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0); index : integer) return std_logic_vector is
        variable res : std_logic_vector(7 downto 0);
    begin
        res := state(state'high -8*index downto state'length-8-8*index);
        return res;
    end function;

    -- Internal signals
    signal state, res : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    signal row0, row1, row2, row3   : std_logic_vector(G_BLOCK_SIZE*2-1 downto 0);
    signal sr0, sr1, sr2, sr3       : std_logic_vector(G_BLOCK_SIZE*2-1 downto 0);

begin

    gen_rows: for i in 0 to G_BLOCK_SIZE/4-1 generate
        row0(row0'high-8*i downto row0'length-8-8*i) <= get_byte(i_data,4*i);
        row1(row0'high-8*i downto row0'length-8-8*i) <= get_byte(i_data,4*i+1);
        row2(row0'high-8*i downto row0'length-8-8*i) <= get_byte(i_data,4*i+2);
        row3(row0'high-8*i downto row0'length-8-8*i) <= get_byte(i_data,4*i+3);
    end generate;

    sr0 <= rot_left(row0,0);
    sr1 <= rot_left(row1,1);

    gen_shifted_rows: if G_BLOCK_SIZE = 16 or G_BLOCK_SIZE = 20 or G_BLOCK_SIZE = 24 generate
        sr2 <= rot_left(row2,2);
        sr3 <= rot_left(row3,3);
    end generate;

    gen_shifted_rows_nb7: if G_BLOCK_SIZE = 28 generate
        sr2 <= rot_left(row2,2);
        sr3 <= rot_left(row3,4);
    end generate;

    gen_shifted_rows_nb8: if G_BLOCK_SIZE = 32 generate
        sr2 <= rot_left(row2,3);
        sr3 <= rot_left(row3,4);
    end generate;

    gen_out:for i in 0 to G_BLOCK_SIZE/4-1 generate
        state(state'high-8*4*i downto state'length-8*4*i-32) <= sr0(sr0'high-8*i downto sr0'high-8*(i+1)+1) & 
                                                             sr1(sr1'high-8*i downto sr1'high-8*(i+1)+1) & 
                                                             sr2(sr2'high-8*i downto sr2'high-8*(i+1)+1) & 
                                                             sr3(sr3'high-8*i downto sr3'high-8*(i+1)+1);   
    end generate;


    gen_G_BLOCK_SIZE_16: if G_BLOCK_SIZE = 16 generate
        o_data  <= state;
    end generate;

    gen_G_BLOCK_SIZE_32: if G_BLOCK_SIZE = 32 generate
        process (clk)
        begin
            if rising_edge(clk) then
                o_data  <= state;
            end if;
        end process;
    end generate;
  
end behavioral;
