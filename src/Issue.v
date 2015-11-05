`ifndef ISSUE_V
`define ISSUE_V

`include "./src/Scoreboard.v"
`include "./src/HazardDetector.v"

module Issue(
    input        clock,
    input        reset,

    // Inputs to repeat to execution stage
    input        id_iss_selalushift,
    input        id_iss_selimregb,
    input [2:0]  id_iss_aluop,
    input        id_iss_unsig,
    input [1:0]  id_iss_shiftop,
    input [4:0]  id_iss_shiftamt,
    input [31:0] id_iss_rega,
    input        id_iss_readmem,
    input        id_iss_writemem,
    input [31:0] id_iss_regb,
    input [31:0] id_iss_imedext,
    input        id_iss_selwsource,
    input [4:0]  id_iss_regdest,
    input        id_iss_writereg,
    input        id_iss_writeov,

    // These are the register addresses, we use them to access the register file
    input [4:0]  id_iss_addra,
    input [4:0]  id_iss_addrb,
    // These connect to the register file
    // Output from register file is connected to inputs above
    output [4:0] iss_reg_addra,
    output [4:0] iss_reg_addrb,
    // These are register values from the register file
    input [31:0] reg_iss_ass_dataa,
    input [31:0] reg_iss_ass_datab,

    // Represents number of register operands (1 => 3 registers, 0 => 2 registers)
    input        id_iss_selregdest,

    // Opcode and funct, received from Decode in order to find out which func-
    // tional unit should be enabled
   
    input [5:0] id_iss_op,
    input [5:0] id_iss_funct, 

    // Repeated to execution stage
    output reg        iss_ex_selalushift,
    output reg        iss_ex_selimregb,
    output reg [2:0]  iss_ex_aluop,
    output reg        iss_ex_unsig,
    output reg [1:0]  iss_ex_shiftop,
    output     [4:0]  iss_ex_shiftamt,
    output     [31:0] iss_ex_rega,
    output reg        iss_ex_readmem,
    output reg        iss_ex_writemem,
    output     [31:0] iss_ex_regb,
    output reg [31:0] iss_ex_imedext,
    output reg        iss_ex_selwsource,
    output reg [4:0]  iss_ex_regdest,
    output reg        iss_ex_writereg,
    output reg        iss_ex_writeov,


    // Functional unit to be used
    output reg iss_am_oper,
    output reg iss_mem_oper,
    output reg iss_mul_oper,

    // Issue-related stall
    output       iss_stall

);

    assign iss_ex_selalushift = id_iss_selalushift;
    assign iss_ex_selimregb = id_iss_selimregb;
    assign iss_ex_aluop = id_iss_aluop;
    assign iss_ex_unsig = id_iss_unsig;
    assign iss_ex_shiftop = id_iss_shiftop;
    assign iss_ex_readmem = id_iss_readmem;
    assign iss_ex_writemem = id_iss_writemem;
    assign iss_ex_imedext = id_iss_imedext;
    assign iss_ex_selwsource = id_iss_selwsource;
    assign iss_ex_regdest = id_iss_regdest;
    assign iss_ex_writereg = id_iss_writereg;
    assign iss_ex_writeov = id_iss_writeov;
    assign iss_ex_rega = reg_iss_ass_dataa;
    assign iss_ex_regb = reg_iss_ass_datab;
    assign iss_ex_shiftamt = reg_iss_ass_dataa;

    // Register to read from file
    assign iss_reg_addra = id_iss_addra;
    assign iss_reg_addrb = id_iss_addrb;


    wire       a_pending;
    wire       b_pending;

    wire [4:0] ass_row_a;
    wire [4:0] ass_row_b;

    wire [1:0] ass_unit_a;
    wire [1:0] ass_unit_b;

    wire [1:0] registerunit;

    wire [4:0] writeaddr;
    wire       enablewrite;

    Scoreboard SB (.clock(clock),
                   .reset(reset),

                   .ass1_addr(id_iss_addra),
                   .ass1_pending(a_pending),
                   .ass1_unit(ass_unit_a),
                   .ass1_row(ass_row_a),

                   .ass2_addr(id_iss_addrb),
                   .ass2_pending(b_pending),
                   .ass2_unit(ass_unit_b),
                   .ass2_row(ass_row),

                   .writeaddr(writeaddr),
                   .registerunit(registerunit),
                   .enablewrite(enablewrite)
        );

    HazardDetector HDETECTOR(.ass_pending_a(a_pending),
                             .ass_row_a(ass_row_a),
                             .ass_pending_b(b_pending),
                             .ass_row_b(ass_row_b),
                             .selregdest(id_iss_selregdest),
                             .stalled(iss_stall)
    );

    // 2'b00: AluMisc
    // 2'b01: Mem
    // 2'b10: Mult
    reg [1:0] functional_unit;

    assign iss_am_oper = functional_unit === 2'b00;
    assign iss_mem_oper = functional_unit === 2'b01;
    assign iss_mul_oper = functional_unit === 2'b10;

    always @(posedge clock or negedge reset) begin
        if (reset) begin
            if(~iss_stall) begin
                if (id_iss_op === 6'b101011 || id_iss_op === 6'b100011) begin
                    // Load, store
                    functional_unit <= 2'b01;
                end else if (id_iss_op === 6'b000000 && id_iss_funct === 6'b011000) begin
                    functional_unit <= 2'b10;
                end else begin
                    functional_unit <= 2'b00;
                end
            end else begin
                functional_unit <= 2'b11;
            end
        end
    end

endmodule

`endif