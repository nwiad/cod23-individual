`define TYPE_I 3'b001
`define TYPE_S 3'b010
`define TYPE_B 3'b011
`define TYPE_U 3'b100
`define TYPE_J 3'b101

`define ALU_ADD 4'b0001
`define ALU_SUB 4'b0010
`define ALU_AND 4'b0011
`define ALU_OR  4'b0100
`define ALU_XOR 4'b0101
`define ALU_NOT 4'b0110
`define ALU_SLL 4'b0111
`define ALU_SRL 4'b1000
`define ALU_SRA 4'b1001
`define ALU_ROL 4'b1010

`define IS_RTYPE (inst_reg[6:0] == 7'b011_0011)
`define IS_ITYPE (inst_reg[6:0] == 7'b001_0011) // 不包括 load
`define IS_LOAD  (inst_reg[6:0] == 7'b000_0011)
`define IS_STYPE (inst_reg[6:0] == 7'b010_0011)
`define IS_BTYPE (inst_reg[6:0] == 7'b110_0011)
`define IS_LUI   (inst_reg[6:0] == 7'b011_0111)

`define IS_ADD  (`IS_RTYPE && (inst_reg[14:12] == 3'b000))
`define IS_ADDI (`IS_ITYPE && (inst_reg[14:12] == 3'b000))
`define IS_ANDI (`IS_ITYPE && (inst_reg[14:12] == 3'b111))
`define IS_LB   (`IS_LOAD  && (inst_reg[14:12] == 3'b000))
`define IS_SB   (`IS_STYPE && (inst_reg[14:12] == 3'b000))
`define IS_SW   (`IS_STYPE && (inst_reg[14:12] == 3'b010))
`define IS_BEQ  (`IS_BTYPE && (inst_reg[14:12] == 3'b000))

`define RD  inst_reg[11:7]
`define RS1 inst_reg[19:15]
`define RS2 inst_reg[24:20]

`define PC_INIT 32'h8000_0000
