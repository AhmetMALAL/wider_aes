----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 09.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sbox is
     Port ( 
          clk     :  in std_logic;
          i_data  :  in std_logic_vector(7 downto 0);
          o_data  : out std_logic_vector(7 downto 0)
      );
end sbox;

architecture Behavioral of sbox is

     type SBoxType is array (0 to 255) of STD_LOGIC_VECTOR(7 downto 0);

     -----------------------------------------------------------------------------
     -- Type definitions
     -----------------------------------------------------------------------------
     -- Array of bytes for storing constants required during the base conversion.
     subtype Byte is std_logic_vector(7 downto 0);
     type byteArrayType is array (0 to 7) of Byte;

     -----------------------------------------------------------------------------
     -- Constants
     -----------------------------------------------------------------------------
     -- aes_sbox
     constant A2X : byteArrayType := (x"98", x"F3", x"F2", x"48", x"09", x"81", x"A9", x"FF");
     constant X2S : byteArrayType := (x"58", x"2D", x"9E", x"0B", x"DC", x"04", x"03", x"24");

     --my_sbox
     --constant A2X : byteArrayType := (x"21", x"D3", x"81", x"4A", x"8A", x"B9", x"90", x"FF");
     --constant X2S : byteArrayType := (x"58", x"26", x"08", x"01", x"B4", x"94", x"B8", x"4D");

     constant ZERO_BYTE   : Byte   := (others => '0');

     -----------------------------------------------------------------------------
     -- Functions
     -----------------------------------------------------------------------------
     
     -- Multiply in GF(2^2).
     function mulG4 (
          inpOne : std_logic_vector(1 downto 0);
          inpTwo : std_logic_vector(1 downto 0))
          return std_logic_vector is
          variable a, b, c, d, e, p, q : std_logic;
     begin
          a := inpOne(1); b := inpOne(0);
          c := inpTwo(1); d := inpTwo(0);
          e := (a xor b) and (c xor d);
          p := (a and c) xor e;
          q := (b and d) xor e;
          return p & q;
     end function mulG4;

     -- Scale by N in GF(2^2) using normal basis.
     function sclNG4 (
          input : std_logic_vector(1 downto 0))
          return std_logic_vector is
     begin
          return (input(0) & (input(0) xor input(1)));
     end function sclNG4;

     -- Scale by N^2 in GF(2^2) using normal basis.
     function sclN2G4 (
          inp : std_logic_vector(1 downto 0))
          return std_logic_vector is
     begin
          return ((inp(0) xor inp(1)) & inp(1));
     end function sclN2G4;

     -- Square in GF(2^2) using normal basis (identical to inverse).
     function sqG4 (
          inp : std_logic_vector(1 downto 0))
          return std_logic_vector is
     begin
          return (inp(0) & inp(1));
     end function sqG4;

     -- Multiply in GF(2^4) using normal basis.
     function mulG16 (
          inpOne : std_logic_vector(3 downto 0);
          inpTwo : std_logic_vector(3 downto 0))
          return std_logic_vector is
          variable a, b, c, d, e, p, q : std_logic_vector(1 downto 0);
     begin
          a := inpOne(3 downto 2); b := inpOne(1 downto 0);
          c := inpTwo(3 downto 2); d := inpTwo(1 downto 0);
          e := mulG4(a xor b, c xor d);
          e := sclNG4(e);
          p := (mulG4(a, c) xor e);
          q := (mulG4(b, d) xor e);
          return p & q;
     end function mulG16;

     -- Square and scale by \nu in GF(2^4)/GF(2^2) using normal basis.
     function sqSclG16 (
          inp : std_logic_vector(3 downto 0))
          return std_logic_vector is
          variable p, q : std_logic_vector(1 downto 0);
     begin
          p := sqG4(inp(3 downto 2) xor inp(1 downto 0));
          q := sclN2G4(sqG4(inp(1 downto 0)));
          return p & q;
     end function sqSclG16;

     -- Inverse in GF(2^4) using normal basis.
     function invG16 (
          inp : std_logic_vector(3 downto 0))
          return std_logic_vector is
          variable a,b,c,d,e,p,q : std_logic_vector(1 downto 0);
     begin
          a := inp(3 downto 2); b := inp(1 downto 0);
          c := sclNG4(sqG4(a xor b));
          d := mulG4(a, b);
          e := sqG4(c xor d);
          p := mulG4(e, b);
          q := mulG4(e, a);
          return p & q;
     end function invG16;

     -- Inversion in GF(2^8) using normal basis.
     function invG256 (
          inp : std_logic_vector(7 downto 0))
          return std_logic_vector is
          variable a,b,c,d,e,p,q : std_logic_vector(3 downto 0);
     begin
          a := inp(7 downto 4); b:= inp(3 downto 0);
          c := sqSclG16(a xor b);
          d := mulG16(a, b);
          e := invG16(c xor d);
          p := mulG16(e, b);
          q := mulG16(e, a);
          return p & q;
     end function invG256;

     -- Base conversion in GF(2^8).
     function baseConv (
          input     : Byte;
          baseConst : byteArrayType)
          return Byte is
          variable tmp : Byte;
     begin
          tmp := ZERO_BYTE;
          for i in 0 to 7 loop
          if input(i) = '1' then
                tmp := tmp xor baseConst(7-i);
          end if;
          end loop;  -- i
          return tmp;
     end function baseConv;

     -----------------------------------------------------------------------------
     -- Signals
     -----------------------------------------------------------------------------
     signal NewBase_D : Byte;              --! @brief Value after first base conversion.
     signal Inverse_D : Byte;              --! @brief Inverse of input in new base.
     signal OldBase_D : Byte;              --! @brief Value after second base conversion.
     
     constant C_SBOX_TABLE : SBoxType := (
          --  AES S-Box lookup table (precomputed)
          x"63", x"7C", x"77", x"7B", x"F2", x"6B", x"6F", x"C5", x"30", x"01", x"67", x"2B", x"FE", x"D7", x"AB", x"76",
          x"CA", x"82", x"C9", x"7D", x"FA", x"59", x"47", x"F0", x"AD", x"D4", x"A2", x"AF", x"9C", x"A4", x"72", x"C0",
          x"B7", x"FD", x"93", x"26", x"36", x"3F", x"F7", x"CC", x"34", x"A5", x"E5", x"F1", x"71", x"D8", x"31", x"15",
          x"04", x"C7", x"23", x"C3", x"18", x"96", x"05", x"9A", x"07", x"12", x"80", x"E2", x"EB", x"27", x"B2", x"75",
          x"09", x"83", x"2C", x"1A", x"1B", x"6E", x"5A", x"A0", x"52", x"3B", x"D6", x"B3", x"29", x"E3", x"2F", x"84",
          x"53", x"D1", x"00", x"ED", x"20", x"FC", x"B1", x"5B", x"6A", x"CB", x"BE", x"39", x"4A", x"4C", x"58", x"CF",
          x"D0", x"EF", x"AA", x"FB", x"43", x"4D", x"33", x"85", x"45", x"F9", x"02", x"7F", x"50", x"3C", x"9F", x"A8",
          x"51", x"A3", x"40", x"8F", x"92", x"9D", x"38", x"F5", x"BC", x"B6", x"DA", x"21", x"10", x"FF", x"F3", x"D2",
          x"CD", x"0C", x"13", x"EC", x"5F", x"97", x"44", x"17", x"C4", x"A7", x"7E", x"3D", x"64", x"5D", x"19", x"73",
          x"60", x"81", x"4F", x"DC", x"22", x"2A", x"90", x"88", x"46", x"EE", x"B8", x"14", x"DE", x"5E", x"0B", x"DB",
          x"E0", x"32", x"3A", x"0A", x"49", x"06", x"24", x"5C", x"C2", x"D3", x"AC", x"62", x"91", x"95", x"E4", x"79",
          x"E7", x"C8", x"37", x"6D", x"8D", x"D5", x"4E", x"A9", x"6C", x"56", x"F4", x"EA", x"65", x"7A", x"AE", x"08",
          x"BA", x"78", x"25", x"2E", x"1C", x"A6", x"B4", x"C6", x"E8", x"DD", x"74", x"1F", x"4B", x"BD", x"8B", x"8A",
          x"70", x"3E", x"B5", x"66", x"48", x"03", x"F6", x"0E", x"61", x"35", x"57", x"B9", x"86", x"C1", x"1D", x"9E",
          x"E1", x"F8", x"98", x"11", x"69", x"D9", x"8E", x"94", x"9B", x"1E", x"87", x"E9", x"CE", x"55", x"28", x"DF",
          x"8C", x"A1", x"89", x"0D", x"BF", x"E6", x"42", x"68", x"41", x"99", x"2D", x"0F", x"B0", x"54", x"BB", x"16"
     );
     -- Synthesis directive to force LUT implementation
     attribute rom_style : string;
     attribute rom_style of C_SBOX_TABLE : constant is "distributed";  -- Xilinx
     attribute ramstyle : string;
     signal o_data_reg : std_logic_vector(7 downto 0);

     constant IS_LOOK_UP : BOOLEAN := FALSE; 
     signal a,b,c,d,e,p,q : std_logic_vector(3 downto 0);

     signal b1,b2 : std_logic_vector(3 downto 0);
     signal a1,a2 : std_logic_vector(3 downto 0);

     signal a_xor_b : std_logic_vector(3 downto 0);
     signal c_xor_d : std_logic_vector(3 downto 0);

begin


     gen_sbox: if IS_LOOK_UP = FALSE generate

          -- Perform inverse calculation in different basis.
          NewBase_D <= baseConv(i_data, A2X);
          a <= NewBase_D(7 downto 4); 
          b <= NewBase_D(3 downto 0);
          a_xor_b <= a xor b;
          c_xor_d <= c xor d;

          Inverse_D <= p & q; --invG256(NewBase_D);
          
          process(clk)
          begin
               if rising_edge(clk) then 

               -- stage-1
               c <= sqSclG16(a_xor_b);
               d <= mulG16(a, b);
               a1 <= a;
               b1 <= b;

               -- stage-2
               e <= invG16(c_xor_d);
               a2 <= a1;
               b2 <= b1;

               -- stage-3
               p <= mulG16(e, b2);
               q <= mulG16(e, a2);
               OldBase_D <= baseConv(Inverse_D, X2S);

               end if; 
          end process;

          -- Output assignment.
          o_data <= OldBase_D xor x"63";

     end generate gen_sbox;
        

     gen_sbox_lut: if IS_LOOK_UP = TRUE generate
        process(clk)
        begin
             if rising_edge(clk) then 
                   o_data <= o_data_reg;
             end if; 
        end process;
   
          o_data_reg  <= C_SBOX_TABLE(to_integer(unsigned(i_data)));
     end generate gen_sbox_lut;

end Behavioral;
