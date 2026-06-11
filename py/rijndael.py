# Author    : Ahmet MALAL
# Date      : 02.02.2025
# Project   : Python Implementation of Rijndael Algorithm
# File      : rijndael.py

################################################################

PRINT_LOG = False

class Rijndael:
    def __init__(self, key, key_size, block_size):
        self.key = key
        self.key_size = key_size
        self.block_size = block_size
        self.Nb = int(block_size / 32)
        self.Nk = int(key_size / 32)
        self.Nr = self.get_rounds()
        self.rcon = self.generate_rcon()
        self.sbox = self.generate_sbox()
        self.inv_sbox = self.generate_inv_sbox()

    def get_rounds(self):

        if self.block_size == 128:
            return self.Nk + 6
        elif self.block_size == 160:
            if (self.Nk == 4) or (self.Nk == 5):
                return 11
            else:
                return self.Nk + 6
        elif self.block_size == 192:
            if (self.Nk == 4) or (self.Nk == 5):
                return 12
            else:
                return self.Nk + 6
        elif self.block_size == 224:
            if (self.Nk == 4) or (self.Nk == 5) or (self.Nk == 6):
                return 13
            else:
                return self.Nk + 6
        elif self.block_size == 256:
            return 14
        else:
            raise ValueError("Invalid key size")

    def generate_sbox(self):
        C_SBOX = [
            0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
            0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
            0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
            0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
            0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
            0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
            0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
            0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
            0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
            0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
            0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
            0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
            0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
            0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
            0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
            0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16]
        return C_SBOX
    
    def generate_inv_sbox(self):
        C_INVSBOX = [
            0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
            0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
            0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
            0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
            0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
            0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
            0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
            0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
            0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
            0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
            0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
            0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
            0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
            0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
            0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
            0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d]
        return C_INVSBOX

    def generate_rcon(self):
        C_RCON = [ 
            0x00, 0x01, 0x02, 0x04, 0x08, 
            0x10, 0x20, 0x40, 0x80, 0x1B, 
            0x36, 0x6C, 0xD8, 0xAB, 0x4D, 
            0x9A, 0x2F, 0x5E, 0xBC, 0x63, 
            0xC6, 0x97, 0x35, 0x6A, 0xD4,
            0xB3, 0x7D, 0xFA, 0xEF, 0xC5, 0x91 ]
        return C_RCON
    
    def key_expansion(self, key_hex):

        #print("key_hex:,",key_hex)
        #print("self.Nk:,",self.Nk)
        #print("self.Nb:,",self.Nb)
        
        key = [0]*(4*self.Nk)
        for i in range(0,len(key)):
            key[len(key)-i-1]  =  key_hex & 0xFF
            key_hex = key_hex >> 8

        W = [0]*4*self.Nb*(self.Nr+1)

        if self.Nk <= 6: 
            for i in range(0,self.Nk):
                for j in range(0,4):
                    W[i*4+j] = key[i*4+j]
            
            for j in range(self.Nk, self.Nb*(self.Nr+1)):
                if j % self.Nk == 0:
                    W[4*j] = W[4*(j-self.Nk)] ^ self.sbox[W[1+4*(j-1)]] ^ self.rcon[int(j/self.Nk)]
                    for i in range(1,4):
                        W[i+4*j] = W[i+4*(j-self.Nk)] ^ self.sbox[W[((1+i)%4)+4*(j-1)]]
                else:
                    for i in range(0,4):
                        W[i+4*j] = W[i+4*(j-self.Nk)] ^ W[i+4*(j-1)]
        else:
            for i in range(0,self.Nk):
                for j in range(0,4):
                    W[i*4+j] = key[i*4+j]
            
            for j in range(self.Nk, self.Nb*(self.Nr+1)):
                if j % self.Nk == 0:
                    W[4*j] = W[4*(j-self.Nk)] ^ self.sbox[W[1+4*(j-1)]] ^ self.rcon[int(j/self.Nk)]
                    for i in range(1,4):
                        W[i+4*j] = W[i+4*(j-self.Nk)] ^ self.sbox[W[((1+i)%4)+4*(j-1)]]
                elif j % self.Nk == 4:
                    for i in range(0,4):
                        W[i+4*j] = W[i+4*(j-self.Nk)] ^ self.sbox[W[i+4*(j-1)]]                        
                else:
                    for i in range(0,4):
                        W[i+4*j] = W[i+4*(j-self.Nk)] ^ W[i+4*(j-1)]    
        
        if PRINT_LOG:
            print("\nW:",end=' ')
            for i in range(0,len(W)):
                if i % 16 == 0:
                    print()
                print(f"0x{W[i]:02x}", end=' ')
            print()
        return W

    def add_round_key(self, state, round_key):
        res = [0]*(self.Nb*4)
        if PRINT_LOG:
            print("add_round_key_in         :",end=' ')
            for i in range(0,len(state)):
                print(hex(state[i]),end=' ')
            print()
            print("add_round_key_ round_key :",end=' ')
            for i in range(0,len(state)):
                print(hex(round_key[i]),end=' ')
            print()
        
        
        for i in range(0,len(state)):
            res[i] = state[i] ^ round_key[i]

        if PRINT_LOG:
            print("add_round_key_out        :",end=' ')
            for i in range(0,len(res)):
                print(hex(res[i]),end=' ')
            print()
        return res

    def sub_bytes(self, state):
        if PRINT_LOG: 
            print("sub_bytes in             :",end=' ')
            for i in range(0,len(state)):
                print(hex(state[i]),end=' ')
            print()
        res = [0]*(self.Nb*4)
        for i in range(0,len(state)):
            res[i] = self.sbox[state[i]]
        if PRINT_LOG: 
            print("sub_bytes out            :",end=' ')
            for i in range(0,len(state)):
                print(hex(res[i]),end=' ')
            print()
        return res

    def inv_sub_bytes(self, state):
        res = [0]*self.Nb*32
        for i in range(0,len(state)):
            res[i] = self.inv_sbox[state[i]]
        return res
    
    def rot_left(self,row,rot):
        res = [0]*len(row)
        for i in range(0,len(row)):
            res[i] = row[(i+rot)%len(row)]
        return res

    def shift_rows(self, state):

        if PRINT_LOG:
            print("sr_in                    :",end=' ')
            for i in range(0,len(state)):
                print(hex(state[i]),end=' ')
            print()
    
        res = [0]*self.Nb*4

        row0 = [0]*self.Nb
        row1 = [0]*self.Nb
        row2 = [0]*self.Nb
        row3 = [0]*self.Nb

        for i in range(0,self.Nb):
            row0[i] = state[4*i+0]
            row1[i] = state[4*i+1]
            row2[i] = state[4*i+2]
            row3[i] = state[4*i+3]

        if self.Nb == 4 or self.Nb == 5 or self.Nb == 6:
            row0 = self.rot_left(row0,0)
            row1 = self.rot_left(row1,1)
            row2 = self.rot_left(row2,2)
            row3 = self.rot_left(row3,3)    
        elif self.Nb == 7:
            row0 = self.rot_left(row0,0)
            row1 = self.rot_left(row1,1)
            row2 = self.rot_left(row2,2)
            row3 = self.rot_left(row3,4)  
        elif self.Nb == 8:
            row0 = self.rot_left(row0,0)
            row1 = self.rot_left(row1,1)
            row2 = self.rot_left(row2,3)
            row3 = self.rot_left(row3,4)  
        else: 
            raise ValueError("Invalid Nb")

        for i in range(0,self.Nb):
            res[4*i+0] = row0[i]
            res[4*i+1] = row1[i]
            res[4*i+2] = row2[i]
            res[4*i+3] = row3[i]

        if PRINT_LOG:
            print("sr_out                   :",end=' ')
            for i in range(0,len(res)):
                print(hex(res[i]),end=' ')
            print()
    

        return res

    def inv_shift_rows(self, state):
        res = [0]*self.Nb*4
        # TODO:
        return res

    def inv_mix_columns(self, state):
        res = [0]*self.Nb*4
        # TODO:
        return res

    def mix_columns(self, state):
        # MixColumns transformation
        
        if PRINT_LOG: 
            print("mix_in                   :",end=' ')
            for i in range(0,len(state)):
                print(hex(state[i]),end=' ')
            print()
        res = [0]*self.Nb*4

        for i in range(0,self.Nb):
            res[4*i+0] = self.mulby2(state[4*i+0])  ^ self.mulby3(state[4*i+1]) ^ state[4*i+2]              ^ state[4*i+3]
            res[4*i+1] = state[4*i+0]               ^ self.mulby2(state[4*i+1]) ^ self.mulby3(state[4*i+2]) ^ state[4*i+3]
            res[4*i+2] = state[4*i+0]               ^ state[4*i+1]              ^ self.mulby2(state[4*i+2]) ^ self.mulby3(state[4*i+3])
            res[4*i+3] = self.mulby3(state[4*i+0])  ^ state[4*i+1]              ^ state[4*i+2]              ^ self.mulby2(state[4*i+3]) 
        
        if PRINT_LOG:
            print("mix_out                  :",end=' ')
            for i in range(0,len(res)):
                print(hex(res[i]),end=' ')
            print()

        return res

    def mulby2(self, byte):
        # Multiply byte by 2 in GF(2^8)
        return ((byte << 1) ^ (0x1b if (byte & 0x80) else 0)) & 0xff
    
    def mulby3(self, byte):
        # Multiply byte by 2 in GF(2^8)
        return byte ^ self.mulby2(byte)

    def inv_mulby2(self, byte):
        # Multiply byte by 1/2 in GF(2^8)
        return (byte >> 1) ^ (0x8d if (byte & 0x01) else 0)

    def encrypt(self, plaintext):
        
        state = [0]*(self.Nb*4)

        for i in range(0,len(state)):
            state[len(state)-i-1] = plaintext & 0xFF
            plaintext = plaintext >> 8
    
        self.round_keys = self.key_expansion(self.key)

        state = self.add_round_key(state, self.round_keys[0:4*self.Nb])
        
        for round in range(1, self.Nr):
            if PRINT_LOG:
                print("----------------------------------------------------------------")
                print("Round: ",round)
            state = self.sub_bytes(state)
            state = self.shift_rows(state)
            state = self.mix_columns(state)
            state = self.add_round_key(state, self.round_keys[(4*self.Nb*round):(4*self.Nb*round+4*self.Nb)])

        state = self.sub_bytes(state)
        state = self.shift_rows(state)
        state = self.add_round_key(state, self.round_keys[(4*self.Nb*self.Nr):(4*self.Nb*self.Nr+4*self.Nb)])
        res = 0x0 
        for i in state:
            res = (res << 8) | i

        if PRINT_LOG:
            print("----------------------------------------------------------------")
            print("Ciphertext: ",end=' ')
            for i in range(0,len(state)):
                print(hex(state[i]),end=' ')
            print()
            print("Ciphertext_hex: ",hex(res))
            print()
        return res

    def decrypt(self, ciphertext):
        res = 0x0 
        # TODO!
        return res
################################################################
def verify_nist_vectors():
    # Implement verification against test vectors
    test_vector_key128 = [
        0x66E94BD4EF8A2C3B884CFA59CA342B2E,
        0xF795BD4A52E29ED713D313FA20E98DBC,
        0x9E38B8EB1D2025A1665AD4B1F5438BB5CAE1AC3F,
        0x939C167E7F916D45670EE21BFC939E1055054A96,
        0xA92732EB488D8BB98ECD8D95DC9C02E052F250AD369B3849,
        0x106F34179C3982DDC6750AA01936B7A180E6B0B9D8D690EC,
        0x0623522D88F7B9C63437537157F625DD5697AB628A3B9BE2549895C8,
        0x93F93CBDABE23415620E6990B0443D621F6AFBD6EDEFD6990A1965A8,
        0xA693B288DF7DAE5B1757640276439230DB77C4CD7A871E24D6162E54AF434891,
        0x5F05857C80B68EA42CCBC759D42C28D5CD490F1D180C7A9397EE585BEA770391]

    test_vector_key160 = [
        0x94B434F8F57B9780F0EFF1A9EC4C112C,
        0x35A00EC955DF43417CEAC2AB2B3F3E76,
        0x33B12AB81DB7972E8FDC529DDA46FCB529B31826,
        0x97F03EB018C0BB9195BF37C6A0AECE8E4CB8DE5F,
        0x528E2FFF6005427B67BB1ED31ECC09A69EF41531DF5BA5B2,
        0x71C7687A4C93EBC35601E3662256E10115BEED56A410D7AC,
        0x58A0C53F3822A32464704D409C2FD0521F3A93E1F6FCFD4C87F1C551,
        0xD8E93EF2EB49857049D6F6E0F40B67516D2696F94013C065283F7F01,
        0x938D36E0CB6B7937841DAB7F1668E47B485D3ACD6B3F6D598B0A9F923823331D,
        0x7B44491D1B24A93B904D171F074AD69669C2B70B134A4D2D773250A4414D78BE]

    test_vector_key192 = [
        0xAAE06992ACBF52A3E8F4A96EC9300BD7,
        0x52F674B7B9030FDAB13D18DC214EB331,
        0x33060F9D4705DDD2C7675F0099140E5A98729257,
        0x012CAB64982156A5710E790F85EC442CE13C520F,
        0xC6348BE20007BAC4A8BD62890C8147A2432E760E9A9F9AB8,
        0xEB9DEF13C253F81C1FC2829426ED166A65A105C6A04CA33D,
        0x3856B17BEA77C4611E3397066828AADDA004706A2C8009DF40A811FE,
        0x160AD76A97AE2C1E05942FDE3DA2962684A92CCC74B8DC23BDE4F469,
        0xF927363EF5B3B4984A9EB9109844152EC167F08102644E3F9028070433DF9F2A,
        0x4E03389C68B2E3F623AD8F7F6BFC88613B86F334F4148029AE25F50DB144B80C]

    test_vector_key224 = [
        0x73F8DFF62A36F3EBF31D6F73A56FF279,
        0x3A72F21E10B6473EA9FF14A232E675B4,
        0xE9F5EA0FA39BB6AD7339F28E58E2E7535F261827,
        0x06EF9BC82905306D45810E12D0807796A3D338F9,
        0xECBE9942CD6703E16D358A829D542456D71BD3408EB23C56,
        0xFD10458ED034368A34047905165B78A6F0591FFEEBF47CC7,
        0xFE1CF0C8DDAD24E3D751933100E8E89B61CD5D31C96ABFF7209C495C,
        0x515D8E2F2B9C5708F112C6DE31CACA47AFB86838B716975A24A09CD4,
        0xBC18BF6D369C955BBB271CBCDD66C368356DBA5B33C0005550D2320B1C617E21,
        0x60ABA1D2BE45D8ABFDCF97BCB39F6C17DF29985CF321BAB75E26A26100AC00AF]

    test_vector_key256 = [
        0xDC95C078A2408989AD48A21492842087,
        0x08C374848C228233C2B34F332BD2E9D3,
        0x30991844F72973B3B2161F1F11E7F8D9863C5118,
        0xEEF8B7CC9DBE0F03A1FE9D82E9A759FD281C67E0,
        0x17004E806FAEF168FC9CD56F98F070982075C70C8132B945,
        0xBED33B0AF364DBF15F9C2F3FB24FBDF1D36129C586EEA6B7,
        0x9BF26FAD5680D56B572067EC2FE162F449404C86303F8BE38FAB6E02,
        0x658F144A34AF44AAE66CFDDAB955C483DFBCB4EE9A19A6701F158A66,
        0xC6227E7740B7E53B5CB77865278EAB0726F62366D9AABAD908936123A1FC8AF3,
        0x9843E807319C32AD1EA3935EF56A2BA96E4BF19C30E47D88A2B97CBBF2E159E7]

    test_vectors = [
        test_vector_key128,
        test_vector_key160,
        test_vector_key192,
        test_vector_key224,
        test_vector_key256]

    flag = True

    for x in range(1,9):
        for j in range(0,len(test_vectors)):
            test_vector = test_vectors[j]
            for i in range(0,5):
                key         = 0x0
                plaintext   = 0x0 
                key_size    = 128 + 32*j
                block_size  = 128 + 32*i
                rijndael = Rijndael(key=key, key_size=key_size, block_size=block_size)
                ciphertext1 = rijndael.encrypt(plaintext=plaintext)
                ciphertext2 = rijndael.encrypt(plaintext=ciphertext1)
                if not (ciphertext1 == test_vector[2*i] and ciphertext2 == test_vector[2*i+1]):
                    flag = False

    if flag:
        print("\nAll Test Passed Successfully.\n")
    else:
        print("\nThe Test Failed.\n")

verify_nist_vectors()

 