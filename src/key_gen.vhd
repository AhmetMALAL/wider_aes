----------------------------------------------------------------------------------
-- Author       : Ahmet MALAL
-- Project Name : FPGA Implementation of Rijndael  
-- Date         : 16.03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.NUMERIC_STD.ALL;

entity key_gen is
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
end key_gen;

architecture Behavioral of key_gen is
 
    -- component declarations
    component sub_bytes is
        generic (
            G_BLOCK_SIZE    : integer := 16
        );
        Port ( 
            clk     :  in std_logic;
            i_data  :  in std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
            o_data  : out std_logic_vector(G_BLOCK_SIZE*8-1 downto 0)
        );
    end component;

    -- type declarations
    type rcon_array is array (0 to 29) of std_logic_vector(7 downto 0);
    -- constant declarations
    constant C_RCON : rcon_array := (
        x"01", x"02", x"04", x"08", x"10", 
        x"20", x"40", x"80", x"1B", x"36", 
        x"6C", x"D8", x"AB", x"4D", x"9A", 
        x"2F", x"5E", x"BC", x"63", x"C6", 
        x"97", x"35", x"6A", x"D4", x"B3", 
        x"7D", x"FA", x"EF", x"C5", x"91"
    );
    --signal declarations
    signal a0,b0,c0,d0,e0,f0,g0,h0,i0,j0,k0,l0,m0,n0,o0,p0 : std_logic_vector(31 downto 0);
    signal a1,b1,c1,d1,e1,f1,g1,h1,i1,j1,k1,l1,m1,n1,o1,p1 : std_logic_vector(31 downto 0);
    signal a2,b2,c2,d2,e2,f2,g2,h2,i2,j2,k2,l2,m2,n2,o2,p2 : std_logic_vector(31 downto 0);
    signal a3,b3,c3,d3,e3,f3,g3,h3,i3,j3,k3,l3,m3,n3,o3,p3 : std_logic_vector(31 downto 0);
    signal a4,b4,c4,d4,e4,f4,g4,h4,i4,j4,k4,l4,m4,n4,o4,p4 : std_logic_vector(31 downto 0);
    signal a5,b5,c5,d5,e5,f5,g5,h5,i5,j5,k5,l5,m5,n5,o5,p5 : std_logic_vector(31 downto 0);
    signal a6,b6,c6,d6,e6,f6,g6,h6,i6,j6,k6,l6,m6,n6,o6,p6 : std_logic_vector(31 downto 0);
    signal a7,b7,c7,d7,e7,f7,g7,h7,i7,j7,k7,l7,m7,n7,o7,p7 : std_logic_vector(31 downto 0);
    signal a8,b8,c8,d8,e8,f8,g8,h8,i8,j8,k8,l8,m8,n8,o8,p8 : std_logic_vector(31 downto 0);

    signal r1,r2,r3,r4: std_logic_vector(7 downto 0);

    signal i_key_low : std_logic_vector(127 downto 0);

    signal h_rot : std_logic_vector(31 downto 0);
    signal d_rot : std_logic_vector(31 downto 0);
    signal h_sub : std_logic_vector(31 downto 0);
    signal d_sub : std_logic_vector(31 downto 0);
    signal l_sub : std_logic_vector(31 downto 0);
    signal rcon1 : std_logic_vector( 7 downto 0);

    signal o_key_reg : std_logic_vector(G_KEY_SIZE*8-1 downto 0);
    signal i_key_reg : std_logic_vector(G_KEY_SIZE*8-1 downto 0);

    signal o_rnd_cnt_reg0 : std_logic_vector(3 downto 0);
    signal o_rnd_cnt_reg1 : std_logic_vector(3 downto 0);
    signal o_rnd_cnt_reg2 : std_logic_vector(3 downto 0);
    signal o_rnd_cnt_reg3 : std_logic_vector(3 downto 0);
    signal o_rnd_cnt_reg4 : std_logic_vector(3 downto 0);
    signal o_rnd_cnt_reg5 : std_logic_vector(3 downto 0);
    signal o_rnd_cnt_reg6 : std_logic_vector(3 downto 0);
    signal o_rnd_cnt_reg7 : std_logic_vector(3 downto 0);
    signal i_key_low_reg0 : std_logic_vector(127 downto 0);
    signal i_key_low_reg1 : std_logic_vector(127 downto 0);
    signal i_key_low_reg2 : std_logic_vector(127 downto 0);
    signal i_key_low_reg3 : std_logic_vector(127 downto 0);
    signal i_key_low_reg4 : std_logic_vector(127 downto 0);
    signal i_key_low_reg5 : std_logic_vector(127 downto 0);
    signal i_key_low_reg6 : std_logic_vector(127 downto 0);

    signal s_in : std_logic_vector(31 downto 0);
    signal s_out: std_logic_vector(31 downto 0);
    constant C_LAT_SBOX : integer := 4;
begin

    gen_128_128: if G_BLOCK_SIZE = 16 and G_KEY_SIZE = 16 generate

        a0 <= i_key(127 downto 96);
        b0 <= i_key(95 downto 64);
        c0 <= i_key(63 downto 32);
        d0 <= i_key(31 downto 0);    
    
        d_rot <= d0(23 downto 0) & d0(31 downto 24);
    
        ----------------------------------------------------------------
        sub_bytes_inst: sub_bytes
            generic map (
                G_BLOCK_SIZE => 4
            )
            port map (
                clk     => clk,
                i_data  => d_rot,
                o_data  => d_sub
            );
        ----------------------------------------------------------------
    
        i0 <= a4 xor d_sub xor (r4 & x"000000");
        j0 <= b4 xor i0;
    
        k0 <= c4 xor j0;
        l0 <= d4 xor k0;
        
        prc_reg: process (clk)
        begin
            if rising_edge(clk) then
                --i_key_reg <= i_key;
                
                a1 <= a0; b1 <= b0; c1 <= c0; d1 <= d0;
                a2 <= a1; b2 <= b1; c2 <= c1; d2 <= d1;
                a3 <= a2; b3 <= b2; c3 <= c2; d3 <= d2;
                a4 <= a3; b4 <= b3; c4 <= c3; d4 <= d3;

                r1 <= C_RCON(to_integer(unsigned(i_rnd_cnt)));
                r2 <= r1;
                r3 <= r2;
                r4 <= r3;

                o_key_reg(127 downto 0)   <= i0 & j0 & k0 & l0;
                o_key <= o_key_reg;

                o_rnd_cnt_reg0 <= i_rnd_cnt;
                o_rnd_cnt_reg1 <= o_rnd_cnt_reg0;
                o_rnd_cnt_reg2 <= std_logic_vector(unsigned(o_rnd_cnt_reg1)+1);
                o_rnd_cnt_reg3 <= o_rnd_cnt_reg2;
                o_rnd_cnt      <= o_rnd_cnt_reg3;

            end if;
        end process;

    end generate;

    gen_128_256: if G_BLOCK_SIZE = 16 and G_KEY_SIZE = 32 generate

        a0 <= i_key(255 downto 224);
        b0 <= i_key(223 downto 192);
        c0 <= i_key(191 downto 160);
        d0 <= i_key(159 downto 128);

        h0 <= i_key( 31 downto   0);

        i_key_low <= i_key(127 downto 0);
    
        h_rot <= h0(23 downto 0) & h0(31 downto 24); 
        
        s_in <= h_rot when i_rnd_cnt(0) = '0' else h0; 
    
        ----------------------------------------------------------------
        sub_bytes_inst: sub_bytes
            generic map (
                G_BLOCK_SIZE => 4
            )
            port map (
                clk     => clk,
                i_data  => s_in,
                o_data  => s_out
            );
        ----------------------------------------------------------------
    
        i0 <= a4 xor s_out xor (r4 & x"000000") when i_rnd_cnt(0) = '0' else 
              a4 xor s_out;

        j0 <= b4 xor i0;
    
        k0 <= c4 xor j0;
        l0 <= d4 xor k0;
        
        prc_reg: process (clk)
        begin
            if rising_edge(clk) then
                --i_key_reg <= i_key;
                
                a1 <= a0; b1 <= b0; c1 <= c0; d1 <= d0;
                a2 <= a1; b2 <= b1; c2 <= c1; d2 <= d1;
                a3 <= a2; b3 <= b2; c3 <= c2; d3 <= d2;
                a4 <= a3; b4 <= b3; c4 <= c3; d4 <= d3;

                i_key_low_reg0 <= i_key_low;
                i_key_low_reg1 <= i_key_low_reg0;
                i_key_low_reg2 <= i_key_low_reg1;
                i_key_low_reg3 <= i_key_low_reg2;
                i_key_low_reg4 <= i_key_low_reg3;
                i_key_low_reg5 <= i_key_low_reg4;
                i_key_low_reg6 <= i_key_low_reg5;

                r1 <= C_RCON(to_integer(unsigned(i_rnd_cnt)/2));
                r2 <= r1;
                r3 <= r2;
                r4 <= r3;

                o_key_reg(127 downto 0)   <= i0 & j0 & k0 & l0;
                o_key <= i_key_low_reg4 & o_key_reg(127 downto 0);

                o_rnd_cnt_reg0 <= i_rnd_cnt;
                o_rnd_cnt_reg1 <= o_rnd_cnt_reg0;
                o_rnd_cnt_reg2 <= std_logic_vector(unsigned(o_rnd_cnt_reg1)+1);
                o_rnd_cnt_reg3 <= o_rnd_cnt_reg2;
                o_rnd_cnt      <= o_rnd_cnt_reg3;

            end if;
        end process;

    end generate;
        
    gen_256_256: if G_BLOCK_SIZE = 32 and G_KEY_SIZE = 32 generate

        a0 <= i_key(255 downto 224);
        b0 <= i_key(223 downto 192);
        c0 <= i_key(191 downto 160);
        d0 <= i_key(159 downto 128);
        e0 <= i_key(127 downto 96);
        f0 <= i_key(95 downto 64);
        g0 <= i_key(63 downto 32);
        h0 <= i_key(31 downto 0);    
    
    
        h_rot <= h0(23 downto 0) & h0(31 downto 24);
    
        ----------------------------------------------------------------
        sub_bytes_inst: sub_bytes
            generic map (
                G_BLOCK_SIZE => 4
            )
            port map (
                clk     => clk,
                i_data  => h_rot,
                o_data  => h_sub
            );
        ----------------------------------------------------------------
        sub_bytes_inst2: sub_bytes
            generic map (
                G_BLOCK_SIZE => 4
            )
            port map (
                clk     => clk,
                i_data  => l0,
                o_data  => l_sub
            );
        ----------------------------------------------------------------
    
        i0 <= a4 xor h_sub xor (r4 & x"000000");
        j0 <= b4 xor i0;
    
        k0 <= c4 xor j0;
        l0 <= d4 xor k0;

        m0 <= e8 xor l_sub;
        n0 <= f8 xor m0;

        o0 <= g8 xor n0;
        p0 <= h8 xor o0;  


        o_key <= i4 & j4 & k4 & l4 & m0 & n0 & o0 & p0;
        
        prc_reg: process (clk)
        begin
            if rising_edge(clk) then
                --i_key_reg <= i_key;
                
                a1 <= a0; b1 <= b0; c1 <= c0; d1 <= d0; e1 <= e0; f1 <= f0; g1 <= g0; h1 <= h0;
                a2 <= a1; b2 <= b1; c2 <= c1; d2 <= d1; e2 <= e1; f2 <= f1; g2 <= g1; h2 <= h1;
                a3 <= a2; b3 <= b2; c3 <= c2; d3 <= d2; e3 <= e2; f3 <= f2; g3 <= g2; h3 <= h2;
                a4 <= a3; b4 <= b3; c4 <= c3; d4 <= d3; e4 <= e3; f4 <= f3; g4 <= g3; h4 <= h3;
                a5 <= a4; b5 <= b4; c5 <= c4; d5 <= d4; e5 <= e4; f5 <= f4; g5 <= g4; h5 <= h4;
                a6 <= a5; b6 <= b5; c6 <= c5; d6 <= d5; e6 <= e5; f6 <= f5; g6 <= g5; h6 <= h5;
                a7 <= a6; b7 <= b6; c7 <= c6; d7 <= d6; e7 <= e6; f7 <= f6; g7 <= g6; h7 <= h6;
                a8 <= a7; b8 <= b7; c8 <= c7; d8 <= d7; e8 <= e7; f8 <= f7; g8 <= g7; h8 <= h7;

                
                i1 <= i0; j1 <= j0; k1 <= k0; l1 <= l0;  
                i2 <= i1; j2 <= j1; k2 <= k1; l2 <= l1;  
                i3 <= i2; j3 <= j2; k3 <= k2; l3 <= l2;  
                i4 <= i3; j4 <= j3; k4 <= k3; l4 <= l3;
    
                r1 <= C_RCON(to_integer(unsigned(i_rnd_cnt)));
                r2 <= r1;
                r3 <= r2;
                r4 <= r3;

                o_rnd_cnt_reg0 <= i_rnd_cnt;
                o_rnd_cnt_reg1 <= o_rnd_cnt_reg0;
                o_rnd_cnt_reg2 <= o_rnd_cnt_reg1;
                o_rnd_cnt_reg3 <= o_rnd_cnt_reg2;
                o_rnd_cnt_reg4 <= o_rnd_cnt_reg3;
                o_rnd_cnt_reg5 <= std_logic_vector(unsigned(o_rnd_cnt_reg4)+1);
                o_rnd_cnt_reg6 <= o_rnd_cnt_reg5;
                o_rnd_cnt_reg7 <= o_rnd_cnt_reg6;
                o_rnd_cnt      <= o_rnd_cnt_reg7;

                --o_key <= o_key_reg;
            end if;
        end process; 
    
    end generate;

end Behavioral;
