#---------------------------------------------------------------------------
#
#       Description     : translate pesudo-asm vector risc-v code into verilog
#                         hex file
#       Author          : Guozhu Xin
#       Last modified   : 2018/3/16
#
#-----------------------------------------------------------------------------
import re

def detect_section(line):
    if re.match(r'\s*\.text', line):
        return '@200'
    elif re.match(r'\s*\.data', line):
        return '@1000'
    else:
        return None

def detect_code(line):
    if re.match(r'\w+', line):
        return line
    else:
        return None

def detect_data(line):
    if re.match(r'0x.+', line):
        return line[2:]
    else:
        return None

def main():
    FpRead =  open('test.asm', 'r')
    FpWrite =  open('test.hex', 'w')
    count = 0
    for Line in FpRead.readlines():
        if detect_section(Line) != None:
            addr = detect_section(Line)
            if addr == '@1000':
                FpWrite.write('\n')
            FpWrite.write(addr + '\n')
        elif detect_data(Line) != None:
            data = detect_data(Line)
            for i in range(0,4):
                FpWrite.write(data[6-2*i:8-2*i] + ' ')
            FpWrite.write('\n')
        elif detect_code(Line) != None:
            contents = re.split(r'\s+', Line)
            vp = '0'                                # 12
            rv32_op = '11'                          # 1:0
            if re.match(r'vadd$', contents[0]):
                rs3 = '00000'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'lui$', contents[0]):
                rs3 = '00000'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '00000'     # 24:20
                rs1 =  '00000'     # 19:15
                func2 = '00'                            # 14:13
                vp    = '1'
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '01101'                            # 6:2
            elif re.match(r'csrrwi$', contents[0]):                        # vl
                rs3 = '10000'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '00001'     # 24:20
                rs1 =   '%05d' % int(bin(int(contents[2]))[2:])
                func2 = '10'                            # 14:13
                vp    = '1'
                rd =  '00000'      # 11:7
                op = '11100'                            # 6:2
            elif re.match(r'ld$', contents[0]):
                imm_v =  '%012d' % int(bin(int(contents[3]))[2:])
                rs3 = imm_v[0:5]                           # 31:27
                func1 = imm_v[5]                             # 26
                imm = imm_v[6]                               # 25
                rs2 =  imm_v[7:12]                         # 24:20
                rs1 =   '%05d' % int(bin(int(contents[2][1:]))[2:])
                func2 = '01'                            # 14:13
                vp    = '0'
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '00000'                            # 6:2
            elif re.match(r'beq$', contents[0]):
                imm_v =  '%013d' % int(bin(int(contents[3]))[2:])
                rs3 = imm_v[0] + imm_v[2:6]                        # 31:27
                func1 = imm_v[6]                             # 26
                imm = imm_v[7]                               # 25
                rs2 =  '%05d' % int(bin(int(contents[2][1:]))[2:])
                rs1 =   '%05d' % int(bin(int(contents[1][1:]))[2:])
                func2 = '00'                            # 14:13
                vp    = '0'
                rd =  imm_v[8:12] + imm_v[1]      # 11:7
                op = '11000'                            # 6:2
            elif re.match(r'addi$', contents[0]):
                imm_v =  '%012d' % int(bin(int(contents[3]))[2:])
                rs3 = imm_v[0:5]                           # 31:27
                func1 = imm_v[5]                             # 26
                imm = imm_v[6]                               # 25
                rs2 =  imm_v[7:12]                         # 24:20
                rs1 =   '%05d' % int(bin(int(contents[2][1:]))[2:])
                func2 = '00'                            # 14:13
                vp    = '0'
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '00100'                            # 6:2
            elif re.match(r'vaddi$', contents[0]):
                imm_v =  '%08d' % int(bin(int(contents[3]))[2:])
                rs3 = '000' + imm_v[0:2]                # 31:27
                func1 = imm_v[2]                        # 26
                imm = '1'                               # 25
                rs2 = imm_v[3:8]                        # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vand$', contents[0]):
                rs3 = '00100'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vandi$', contents[0]):
                imm_v =  '%08d' % int(bin(int(contents[3]))[2:])
                rs3 = '001' + imm_v[0:2]                # 31:27
                func1 = imm_v[2]                        # 26
                imm = '1'                               # 25
                rs2 = imm_v[3:8]                        # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vor$', contents[0]):
                rs3 = '01000'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vori$', contents[0]):
                imm_v =  '%08d' % int(bin(int(contents[3]))[2:])
                rs3 = '010' + imm_v[0:2]                # 31:27
                func1 = imm_v[2]                        # 26
                imm = '1'                               # 25
                rs2 = imm_v[3:8]                        # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vsll$', contents[0]):
                rs3 = '01100'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vslli$', contents[0]):
                imm_v =  '%08d' % int(bin(int(contents[3]))[2:])
                rs3 = '011' + imm_v[0:2]                # 31:27
                func1 = imm_v[2]                        # 26
                imm = '1'                               # 25
                rs2 = imm_v[3:8]                        # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'
            elif re.match(r'vsra$', contents[0]):
                rs3 = '10000'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vsrai$', contents[0]):
                imm_v =  '%08d' % int(bin(int(contents[3]))[2:])
                rs3 = '100' + imm_v[0:2]                # 31:27
                func1 = imm_v[2]                        # 26
                imm = '1'                               # 25
                rs2 = imm_v[3:8]                        # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'
            elif re.match(r'vsrl$', contents[0]):
                rs3 = '10100'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vsrli$', contents[0]):
                imm_v =  '%08d' % int(bin(int(contents[3]))[2:])
                rs3 = '101' + imm_v[0:2]                # 31:27
                func1 = imm_v[2]                        # 26
                imm = '1'                               # 25
                rs2 = imm_v[3:8]                        # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'
            elif re.match(r'vxor$', contents[0]):
                rs3 = '11000'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vxori$', contents[0]):
                imm_v =  '%08d' % int(bin(int(contents[3]))[2:])
                rs3 = '110' + imm_v[0:2]                # 31:27
                func1 = imm_v[2]                        # 26
                imm = '1'                               # 25
                rs2 = imm_v[3:8]                        # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'
            elif re.match(r'vseq$', contents[0]):
                rs3 = '00000'                           # 31:27
                func1 = '1'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vsne$', contents[0]):
                rs3 = '00001'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vsge$', contents[0]):
                rs3 = '00001'                           # 31:27
                func1 = '1'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vslt$', contents[0]):
                rs3 = '00010'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vmax$', contents[0]):
                rs3 = '00010'                           # 31:27
                func1 = '1'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vmin$', contents[0]):
                rs3 = '00011'                           # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vselect$', contents[0]):
                rs3 = '00011'                           # 31:27
                func1 = '1'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vsub$', contents[0]):
                rs3 = '00100'                           # 31:27
                func1 = '1'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vmadd$', contents[0]):
                rs3 =  '%05d' % int(bin(int(contents[4][1:]))[2:])     # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '10'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vmsub$', contents[0]):
                rs3 =  '%05d' % int(bin(int(contents[4][1:]))[2:])     # 31:27
                func1 = '0'                             # 26
                imm = '1'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '10'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vmnadd$', contents[0]):
                rs3 =  '%05d' % int(bin(int(contents[4][1:]))[2:])     # 31:27
                func1 = '1'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '10'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vmnsub$', contents[0]):
                rs3 =  '%05d' % int(bin(int(contents[4][1:]))[2:])     # 31:27
                func1 = '1'                             # 26
                imm = '1'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[3][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '10'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '10101'                            # 6:2
            elif re.match(r'vld$', contents[0]):
                imm_v =  '%05d' % int(bin(int(contents[3]))[2:])
                rs3 = imm_v                        # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 = '00000'                        # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '11101'                            # 6:2
            elif re.match(r'vst$', contents[0]):
                rs3 = '%05d' % int(bin(int(contents[1][1:]))[2:])                        # 31:27
                func1 = '0'                             # 26
                imm = '0'                               # 25
                rs2 = '00000'                        # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '10'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[3]))[2:])                            # 11:7
                op = '11101'                            # 6:2
            elif re.match(r'vlds$', contents[0]):
                rs3 =  '%05d' % int(bin(int(contents[3]))[2:])     # 31:27   imm
                func1 = '0'                             # 26
                imm = '1'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[4][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '11101'                            # 6:2
            elif re.match(r'vsts$', contents[0]):
                rs3 =  '%05d' % int(bin(int(contents[1][1:]))[2:])     # 31:27 imm
                func1 = '0'                             # 26
                imm = '1'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[4][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '10'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[3]))[2:])      # 11:7
                op = '11101'                            # 6:2
            elif re.match(r'vldx$', contents[0]):
                rs3 =  '%05d' % int(bin(int(contents[3]))[2:])     # 31:27
                func1 = '1'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[4][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '00'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[1][1:]))[2:])      # 11:7
                op = '11101'                            # 6:2
            elif re.match(r'vstx$', contents[0]):
                rs3 =  '%05d' % int(bin(int(contents[1][1:]))[2:])     # 31:27
                func1 = '1'                             # 26
                imm = '0'                               # 25
                rs2 =  '%05d' % int(bin(int(contents[4][1:]))[2:])     # 24:20
                rs1 =  '%05d' % int(bin(int(contents[2][1:]))[2:])     # 19:15
                func2 = '10'                            # 14:13
                rd =  '%05d' % int(bin(int(contents[3]))[2:])      # 11:7
                op = '11101'                            # 6:2
            elif re.match(r'vcrypt.SHA256.init$', contents[0]):
                rs3 = '0000' + '0'
                func1 = '0'
                imm = '0'
                rs2 = '00000'
                rs1 = '00000'
                func2 = '00'
                vp = '0'
                rd = '00000'
                op = '11010'
            elif re.match(r'vcrypt.SHA256.hash$', contents[0]):
                rs3 = '0011' + '0'
                func1 = '0'
                imm = '0'
                rs2 = '%05d' % int(bin(int(contents[3][1:]))[2:])        # w second part
                rs1 = '%05d' % int(bin(int(contents[2][1:]))[2:])        # w first part
                func2 = '00'
                vp = '0'
                rd = '%05d' % int(bin(int(contents[1][1:]))[2:])
                op = '11010'
            elif re.match(r'vcrypt.AES.key_expan.128bit$', contents[0]):
                rs3 = '1101' + '0'
                func1 = '0'
                imm = '1'
                rs2 = '%05d' % int(bin(int(contents[1][1:]))[2:])   #key
                rs1 = '00000'
                func2 = '00'
                vp = '0'
                rd = '00000'
                op = '11010'
            elif re.match(r'vcrypt.AES.encrypt.128bit$', contents[0]):
                rs3 = '0001' + '0'
                func1 = '0'
                imm = '1'
                rs2 = '%05d' % int(bin(int(contents[3][1:]))[2:])        # key
                rs1 = '%05d' % int(bin(int(contents[2][1:]))[2:])        # msg
                func2 = '00'
                vp = '0'
                rd = '%05d' % int(bin(int(contents[1][1:]))[2:])        # ciphertext
                op = '11010'
            elif re.match(r'vcrypt.AES.decrypt.128bit$', contents[0]):
                rs3 = '0010' + '0'
                func1 = '0'
                imm = '1'
                rs2 = '%05d' % int(bin(int(contents[3][1:]))[2:])        # key
                rs1 = '%05d' % int(bin(int(contents[2][1:]))[2:])        # ciphertext
                func2 = '00'
                vp = '0'
                rd = '%05d' % int(bin(int(contents[1][1:]))[2:])         # msg
                op = '11010'
            else:
                print('something wrong!'+'\tcount='+str(count))
            code = '%08x' % int(rs3 + func1 + imm + rs2 + rs1 + func2 + vp + rd + op + rv32_op, base=2)
            count += 1
            for i in range(0,4):
                FpWrite.write(code[6-2*i:8-2*i] + ' ')
            if count % 4 == 0:
                FpWrite.write('\n')
        else:
            print('nothing detected!')
    FpWrite.close()
    FpRead.close()
main()
