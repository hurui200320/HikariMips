//////////////////////////////////////////////////////////////////////////////////
// HikariMips
// 使用类SRAM接口，目前仅有指令寄存器的
// 标准SRAM五个信号线：read_addr  read_data  write_addr  write_data  write_valid
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module hikari_mips(
    input wire clk,
    input wire rst,

    // 指令ROM类SRAM接口
    input wire[`RegBus] rom_data_i,
    output wire[`RegBus] rom_addr_o,
    output wire rom_ce_o,

    // 数据RAM类SRAM接口
    input wire[`RegBus] ram_data_i,
    output wire[`RegBus] ram_data_o,
    output wire[`RegBus] ram_addr_o,
    output wire ram_ce_o,
    output wire ram_we_o,
    output wire[3:0] ram_sel_o,

    input wire[4:0] init_i
    );

    // PC -> IF/ID
    wire[`RegBus] pc;
    wire[`RegBus] id_pc_i;
    wire[`RegBus] id_pc_o;
    wire[`RegBus] id_inst_i;    
    wire[31:0] pc_exceptions_o;
    wire[31:0] id_exceptions_i;
    
    // ID -> ID/EX
    wire[`AluOpBus] id_aluop_o;
    wire[`AluSelBus] id_alusel_o;
    wire[`RegBus] id_reg1_o;
    wire[`RegBus] id_reg2_o;
    wire[`RegAddrBus] id_waddr_o;
    wire id_we_o;
    wire id_is_in_delayslot_o;
    wire[`RegBus] id_link_address_o;
    wire is_in_delayslot_i;
    wire is_nullified_i;
    wire next_inst_in_delayslot_o;
    wire next_inst_is_nullified_o;
    wire[`RegBus] id_inst_o;
    wire[31:0] id_exceptions_o;
    // ID -> PC
    wire id_is_branch_o;
    wire[`RegBus] branch_target_address_o;
    
    // ID/EX -> EX
    wire[`AluOpBus] ex_aluop_i;
    wire[`AluSelBus] ex_alusel_i;
    wire[`RegBus] ex_reg1_i;
    wire[`RegBus] ex_reg2_i;
    wire ex_we_i;
    wire[`RegAddrBus] ex_waddr_i;
    wire[`RegBus]  ex_link_address_i;
    wire ex_is_in_delayslot_i;
    wire[`RegBus] ex_inst_i;
    wire[`RegBus] ex_pc_i;
    wire[31:0] ex_exceptions_i;
    
    // EX -> EX/MEM
    wire ex_we_o;
    wire[`RegAddrBus] ex_waddr_o;
    wire[`RegBus] ex_wdata_o;
    wire ex_we_hilo_o; 
    wire[`RegBus] ex_hi_o;
    wire[`RegBus] ex_lo_o;
    wire[`AluOpBus] ex_aluop_o;
    wire[`RegBus] ex_mem_addr_o;
    wire[`RegBus] ex_reg2_o;
    wire ex_cp0_we_o;
    wire[7:0] ex_cp0_waddr_o;
    wire[`RegBus] ex_cp0_wdata_o;
    wire[`RegBus] ex_pc_o;
    wire[31:0] ex_exceptions_o;
    wire ex_is_in_delayslot_o;
    // EX -> CP0
    wire[7:0] ex_cp0_raddr_o;

    // EX/MEM -> MEM
    wire mem_we_i;
    wire[`RegAddrBus] mem_waddr_i;
    wire[`RegBus] mem_wdata_i;
    wire mem_we_hilo_i; 
    wire[`RegBus] mem_hi_i;
    wire[`RegBus] mem_lo_i;
    wire[`AluOpBus] mem_aluop_i;
    wire[`RegBus] mem_mem_addr_i;
    wire[`RegBus] mem_reg2_i;
    wire mem_cp0_we_i;
    wire[7:0] mem_cp0_waddr_i;
    wire[`RegBus] mem_cp0_wdata_i;
    wire[`RegBus] mem_pc_i;
    wire[31:0] mem_exceptions_i;
    wire mem_is_in_delayslot_i;

    // MEM -> MEM/WB
    wire mem_we_o;
    wire[`RegAddrBus] mem_waddr_o;
    wire[`RegBus] mem_wdata_o;
    wire mem_we_hilo_o; 
    wire[`RegBus] mem_hi_o;
    wire[`RegBus] mem_lo_o;
    wire mem_cp0_we_o;
    wire[7:0] mem_cp0_waddr_o;
    wire[`RegBus] mem_cp0_wdata_o;
    wire[`RegBus] mem_pc_o;
    wire mem_is_in_delayslot_o;
    wire mem_exception_occured_o;
    wire[4:0] mem_exc_code_o;
    wire[`RegBus] mem_bad_addr_o;
    
    // MEM/WB -> WB   
    wire wb_we_i;
    wire[`RegAddrBus] wb_waddr_i;
    wire[`RegBus] wb_wdata_i;
    wire wb_we_hilo_i;
    wire[`RegBus] wb_hi_i;
    wire[`RegBus] wb_lo_i;
    wire wb_cp0_we_i;
    wire[7:0] wb_cp0_waddr_i;
    wire[`RegBus] wb_cp0_wdata_i;
    
    // ID -> Regfile
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegAddrBus] reg2_addr;

    // HI/LO -> EX
    wire [`RegBus] hi;
    wire [`RegBus] lo;

    // CP0 -> EX
    wire[`RegBus] cp0_rdata_o;
    // CP0 <-> 各模块
    wire[`RegBus] cp0_status_o;
    wire[`RegBus] cp0_cause_o;
    wire[`RegBus] cp0_epc_o;

    // CTRL <-> 各模块
    wire[5:0] stall;
    wire stallreq_from_id;    
    wire stallreq_from_ex;
    wire[`RegBus] ctrl_epc_o;
    wire ctrl_flush_o;

    // EX <-> DIV
    wire[`DoubleRegBus] div_result;
    wire div_ready;
    wire[`RegBus] div_opdata1;
    wire[`RegBus] div_opdata2;
    wire div_start;
    wire div_annul;
    wire signed_div;

    // EX <-> mul
    wire[`DoubleRegBus] mul_result;
    wire mul_ready;
    wire[`RegBus] mul_opdata1;
    wire[`RegBus] mul_opdata2;
    wire mul_start;
    wire mul_annul;
    wire signed_mul;
  
    // PC -> ROM
    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .is_branch_i(id_is_branch_o),
        .branch_target_address_i(branch_target_address_o),
        .pc(pc),
        .ce(rom_ce_o),
        .flush(ctrl_flush_o),
        .epc(ctrl_epc_o),
        .exceptions_o(pc_exceptions_o)
    );
    assign rom_addr_o = pc;

    //  ROM -> IF/ID -> ID
    if_id if_id0(
        .clk(clk),
        .rst(rst),
        .flush(ctrl_flush_o),
        .stall(stall),
        .if_pc(pc),
        .if_inst(rom_data_i),
        .if_exceptions(pc_exceptions_o),
        .id_pc(id_pc_i),
        .id_inst(id_inst_i),
        .id_exceptions(id_exceptions_i)
    );
    
    // IF/ID -> ID -> ID/EX, PC
    id id0(
        .clk(clk),
        .rst(rst),

        .pc_i(id_pc_i),
        .pc_o(id_pc_o),
        .inst_i(id_inst_i),
        .inst_o(id_inst_o),

        // 读regfile请求
        .re1_o(reg1_read),   
        .raddr1_o(reg1_addr),
        .rdata1_i(reg1_data),
        .re2_o(reg2_read),    
        .raddr2_o(reg2_addr), 
        .rdata2_i(reg2_data),

        // EX反馈
        .ex_we_i(ex_we_o),
        .ex_wdata_i(ex_wdata_o),
        .ex_waddr_i(ex_waddr_o),
        // 解决Load相关，设置这个为`ALU_OP_NOP可以屏蔽相关处理
  	    .ex_aluop_i(ex_aluop_o),

        // MEM反馈
        .mem_we_i(mem_we_o),
        .mem_wdata_i(mem_wdata_o),
        .mem_waddr_i(mem_waddr_o),

        // 延迟槽
        .is_in_delayslot_i(is_in_delayslot_i),
        .is_nullified_i(is_nullified_i),
        .next_inst_in_delayslot_o(next_inst_in_delayslot_o),    
        .next_inst_is_nullified_o(next_inst_is_nullified_o),    
        .is_branch_o(id_is_branch_o),
        .branch_target_address_o(branch_target_address_o),       
        .link_addr_o(id_link_address_o),
        .is_in_delayslot_o(id_is_in_delayslot_o),

        // 异常
        .exceptions_i(id_exceptions_i),
        .exceptions_o(id_exceptions_o),

        //送到ID/EX模块的信息
        .aluop_o(id_aluop_o),
        .alusel_o(id_alusel_o),
        .reg1_data_o(id_reg1_o),
        .reg2_data_o(id_reg2_o),
        .waddr_o(id_waddr_o),
        .we_o(id_we_o),

        .stallreq(stallreq_from_id)
    );

    // 通用寄存器Regfile例化
    regfile regfile1(
        .clk (clk),
        .rst (rst),
        .we    (wb_we_i),
        .waddr (wb_waddr_i),
        .wdata (wb_wdata_i),
        .re1 (reg1_read),
        .raddr1 (reg1_addr),
        .rdata1 (reg1_data),
        .re2 (reg2_read),
        .raddr2 (reg2_addr),
        .rdata2 (reg2_data)
    );

    // ID/EX模块
    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        .flush(ctrl_flush_o),
        .stall(stall),
        
        //从译码阶段ID模块传递的信息
        .id_aluop(id_aluop_o),
        .id_alusel(id_alusel_o),
        .id_reg1(id_reg1_o),
        .id_reg2(id_reg2_o),
        .id_waddr(id_waddr_o),
        .id_we(id_we_o),
        .id_link_address(id_link_address_o),
        .id_is_in_delayslot(id_is_in_delayslot_o),
        .next_inst_in_delayslot_i(next_inst_in_delayslot_o),
        .next_inst_is_nullified_i(next_inst_is_nullified_o),
        .id_inst(id_inst_o),
        .id_pc(id_pc_o),
        .id_exceptions(id_exceptions_o),
    
        //传递到执行阶段EX模块的信息
        .ex_aluop(ex_aluop_i),
        .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i),
        .ex_reg2(ex_reg2_i),
        .ex_waddr(ex_waddr_i),
        .ex_we(ex_we_i),
        .ex_link_address(ex_link_address_i),
        .ex_is_in_delayslot(ex_is_in_delayslot_i),
        .is_in_delayslot_o(is_in_delayslot_i),
        .is_nullified_o(is_nullified_i),
        .ex_inst(ex_inst_i),
        .ex_pc(ex_pc_i),
        .ex_exceptions(ex_exceptions_i)
    );        
    
    // EX模块
    ex ex0(
        .clk(clk),
        .rst(rst),
    
        // hi/LO寄存器
        .hi_i(hi),
        .lo_i(lo),
        // 来自访存的反馈，同ID模块解决数据相关的思路
        .mem_hi_i(mem_hi_o),
        .mem_lo_i(mem_lo_o),
        .mem_we_hilo_i(mem_we_hilo_o),

        // CP0寄存器
        .cp0_rdata_i(cp0_rdata_o),
        .cp0_raddr_o(ex_cp0_raddr_o),
        .cp0_we_o(ex_cp0_we_o),
        .cp0_waddr_o(ex_cp0_waddr_o),
        .cp0_wdata_o(ex_cp0_wdata_o),
        // 来自MEM的反馈，解决数据相关
        .mem_cp0_we_i(mem_cp0_we_o),
        .mem_cp0_waddr_i(mem_cp0_waddr_o),
        .mem_cp0_wdata_i(mem_cp0_wdata_o),

        // 送到执行阶段EX模块的信息
        .aluop_i(ex_aluop_i),
        .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),
        .reg2_i(ex_reg2_i),
        .waddr_i(ex_waddr_i),
        .we_i(ex_we_i),
        .inst_i(ex_inst_i),
        .pc_i(ex_pc_i),
        .exceptions_i(ex_exceptions_i),
      
        // EX模块的输出到EX/MEM模块信息
        .waddr_o(ex_waddr_o),
        .we_o(ex_we_o),
        .wdata_o(ex_wdata_o),                
        .we_hilo_o(ex_we_hilo_o),
        .hi_o(ex_hi_o),
        .lo_o(ex_lo_o),

        // 访存指令
        // MEM_OP_xxx传递给MEM进一步决定如何访存
        .aluop_o(ex_aluop_o),
        .mem_addr_o(ex_mem_addr_o),
        .reg2_o(ex_reg2_o),

        // 延迟槽和分支跳转
        .link_address_i(ex_link_address_i),
        .is_in_delayslot_i(ex_is_in_delayslot_i),    

        // 异常
        .pc_o(ex_pc_o),
        .exceptions_o(ex_exceptions_o),
        .is_in_delayslot_o(ex_is_in_delayslot_o),

        // 除法模块
        .div_result_i(div_result),
        .div_ready_i(div_ready),
        .div_opdata1_o(div_opdata1),
        .div_opdata2_o(div_opdata2),
        .div_start_o(div_start),
        .signed_div_o(signed_div),

        // 乘法模块
        .mult_result_i(mul_result),
        .mult_ready_i(mul_ready),
        .mult_opdata1_o(mul_opdata1),
        .mult_opdata2_o(mul_opdata2),
        .mult_start_o(mul_start),
        .signed_mult_o(signed_mul),

        .stallreq(stallreq_from_ex)
    );

    div div0(
        .clk(clk),
        .rst(rst),
        
        .signed_div_i(signed_div),
        
        .opdata1_i(div_opdata1),
        .opdata2_i(div_opdata2),
        .start_i(div_start),
        .annul_i(ctrl_flush_o), // TODO 测试取消
        .result_o(div_result),
        .ready_o(div_ready)
    );

    mul mul0(
        .clk(clk),
        .rst(rst),
        
        .signed_mul_i(signed_mul),
        
        .opdata1_i(mul_opdata1),
        .opdata2_i(mul_opdata2),
        .start_i(mul_start),
        .annul_i(ctrl_flush_o), // TODO 取消机制需要测试
        .result_o(mul_result),
        .ready_o(mul_ready)
    );

    // EX/MEM模块
    ex_mem ex_mem0(
        .clk(clk),
        .rst(rst),
        .flush(ctrl_flush_o),
        .stall(stall),
      
        //来自执行阶段EX模块的信息    
        .ex_waddr(ex_waddr_o),
        .ex_we(ex_we_o),
        .ex_wdata(ex_wdata_o),
        .ex_hi(ex_hi_o),
        .ex_lo(ex_lo_o),
        .ex_we_hilo(ex_we_hilo_o),
        .ex_aluop(ex_aluop_o),
        .ex_mem_addr(ex_mem_addr_o),
        .ex_reg2(ex_reg2_o),
        .ex_cp0_we(ex_cp0_we_o),
        .ex_cp0_waddr(ex_cp0_waddr_o),
        .ex_cp0_wdata(ex_cp0_wdata_o),
        .ex_pc(ex_pc_o),
        .ex_exceptions(ex_exceptions_o),
        .ex_is_in_delayslot(ex_is_in_delayslot_o),
    
        //送到访存阶段MEM模块的信息
        .mem_waddr(mem_waddr_i),
        .mem_we(mem_we_i),
        .mem_wdata(mem_wdata_i),
        .mem_hi(mem_hi_i),
        .mem_lo(mem_lo_i),
        .mem_we_hilo(mem_we_hilo_i),
        .mem_aluop(mem_aluop_i),
        .mem_mem_addr(mem_mem_addr_i),
        .mem_reg2(mem_reg2_i),
        .mem_cp0_we(mem_cp0_we_i),
        .mem_cp0_waddr(mem_cp0_waddr_i),
        .mem_cp0_wdata(mem_cp0_wdata_i),
        .mem_pc(mem_pc_i),
        .mem_exceptions(mem_exceptions_i),
        .mem_is_in_delayslot(mem_is_in_delayslot_i)
    );
    
    // MEM模块例化
    mem mem0(
        .clk(clk),
        .rst(rst),
    
        //来自EX/MEM模块的信息    
        .waddr_i(mem_waddr_i),
        .we_i(mem_we_i),
        .wdata_i(mem_wdata_i),
        .hi_i(mem_hi_i),
        .lo_i(mem_lo_i),
        .we_hilo_i(mem_we_hilo_i),
        .aluop_i(mem_aluop_i),
        .mem_addr_i(mem_mem_addr_i),
        .reg2_i(mem_reg2_i),
        .cp0_we_i(mem_cp0_we_i),
        .cp0_waddr_i(mem_cp0_waddr_i),
        .cp0_wdata_i(mem_cp0_wdata_i),
        .exceptions_i(mem_exceptions_i),
        .pc_i(mem_pc_i),
        .is_in_delayslot_i(mem_is_in_delayslot_i),
      
        .cp0_status_i(cp0_status_o),
        .cp0_cause_i(cp0_cause_o),
        .cp0_epc_i(cp0_epc_o),

        .pc_o(mem_pc_o),
        .is_in_delayslot_o(mem_is_in_delayslot_o),
        .exception_occured_o(mem_exception_occured_o),
        .exc_code_o(mem_exc_code_o),
        .bad_addr_o(mem_bad_addr_o),

        //送到MEM/WB模块的信息
        .waddr_o(mem_waddr_o),
        .we_o(mem_we_o),
        .wdata_o(mem_wdata_o),
        .hi_o(mem_hi_o),
        .lo_o(mem_lo_o),
        .we_hilo_o(mem_we_hilo_o),
        .cp0_we_o(mem_cp0_we_o),
        .cp0_waddr_o(mem_cp0_waddr_o),
        .cp0_wdata_o(mem_cp0_wdata_o),

        // 数据RAM
        .mem_data_i(ram_data_i),
        .mem_addr_o(ram_addr_o),
        .mem_we_o(ram_we_o),
        .mem_sel_o(ram_sel_o),
        .mem_data_o(ram_data_o),
        .mem_ce_o(ram_ce_o)
    );

    // MEM/WB模块
    mem_wb mem_wb0(
        .clk(clk),
        .rst(rst),
        .flush(ctrl_flush_o),
        .stall(stall),

        //来自访存阶段MEM模块的信息    
        .mem_waddr(mem_waddr_o),
        .mem_we(mem_we_o),
        .mem_wdata(mem_wdata_o),
        .mem_hi(mem_hi_o),
        .mem_lo(mem_lo_o),
        .mem_we_hilo(mem_we_hilo_o),    
        .mem_cp0_we(mem_cp0_we_o),
        .mem_cp0_waddr(mem_cp0_waddr_o),
        .mem_cp0_wdata(mem_cp0_wdata_o),
    
        //送到回写阶段的信息
        .wb_waddr(wb_waddr_i),
        .wb_we(wb_we_i),
        .wb_wdata(wb_wdata_i),
        .wb_hi(wb_hi_i),
        .wb_lo(wb_lo_i),
        .wb_we_hilo(wb_we_hilo_i),
        .wb_cp0_we(wb_cp0_we_i),
        .wb_cp0_waddr(wb_cp0_waddr_i),
        .wb_cp0_wdata(wb_cp0_wdata_i)
    );

    // HI/LO寄存器
    hilo_reg hilo_reg0(
        .clk(clk),
        .rst(rst),
    
        .we(wb_we_hilo_i),
        .hi_i(wb_hi_i),
        .lo_i(wb_lo_i),
    
        .hi_o(hi),
        .lo_o(lo)    
    );

    cp0_reg cp0_reg0(
        .clk(clk),
        .rst(rst),

        .we_i(wb_cp0_we_i),
        .waddr_i(wb_cp0_waddr_i),
        .wdata_i(wb_cp0_wdata_i),

        .raddr_i(ex_cp0_raddr_o),
        .rdata_o(cp0_rdata_o),

        .init_i(init_i),
        
        .status_o(cp0_status_o),
        .cause_o(cp0_cause_o),
        .epc_o(cp0_epc_o),

        .exception_occured_i(mem_exception_occured_o),
        .exc_code_i(mem_exc_code_o),
        .pc_i(mem_pc_o),
        .is_in_delayslot_i(mem_is_in_delayslot_o),
        .bad_addr_i(mem_bad_addr_o) 
    );

    // CTRL
    ctrl ctrl0(
        .clk(clk),
        .rst(rst),

        .stallreq_from_id(stallreq_from_id),
        .stallreq_from_ex(stallreq_from_ex),
        .stall(stall),

        .cp0_epc_i(cp0_epc_o),
        .exception_occured_i(mem_exception_occured_o),
        .exc_code_i(mem_exc_code_o),
        .epc_o(ctrl_epc_o),
        .flush(ctrl_flush_o)
    );

endmodule
