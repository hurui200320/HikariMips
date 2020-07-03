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
    output wire[3:0] ram_sel_o
    );

    // PC -> IF/ID
    wire[`InstAddrBus] pc;
    wire[`InstAddrBus] id_pc_i;
    wire[`InstBus] id_inst_i;    
    
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
    wire[`DoubleRegBus] ex_mul_result_o;
    wire[1:0] ex_cnt_o;

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
    // EX/MEM -> EX
    wire[`DoubleRegBus] ex_mul_result_i;
    wire[1:0] ex_cnt_i;

    // MEM -> MEM/WB
    wire mem_we_o;
    wire[`RegAddrBus] mem_waddr_o;
    wire[`RegBus] mem_wdata_o;
    wire mem_we_hilo_o; 
    wire[`RegBus] mem_hi_o;
    wire[`RegBus] mem_lo_o;
    
    // MEM/WB -> WB   
    wire wb_we_i;
    wire[`RegAddrBus] wb_waddr_i;
    wire[`RegBus] wb_wdata_i;
    wire wb_we_hilo_i;
    wire[`RegBus] wb_hi_i;
    wire[`RegBus] wb_lo_i;
    
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

    // CTRL <-> 各模块
    wire[5:0] stall;
    wire stallreq_from_id;    
    wire stallreq_from_ex;

    // EX <-> DIV
    wire[`DoubleRegBus] div_result;
    wire div_ready;
    wire[`RegBus] div_opdata1;
    wire[`RegBus] div_opdata2;
    wire div_start;
    wire div_annul;
    wire signed_div;
  
    // PC -> ROM
    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .is_branch_i(id_is_branch_o),
        .branch_target_address_i(branch_target_address_o),
        .pc(pc),
        .ce(rom_ce_o)
    );
    assign rom_addr_o = pc;

    //  ROM -> IF/ID -> ID
    if_id if_id0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .if_pc(pc),
        .if_inst(rom_data_i),
        .id_pc(id_pc_i),
        .id_inst(id_inst_i)          
    );
    
    // IF/ID -> ID -> ID/EX, PC
    id id0(
        .clk(clk),
        .rst(rst),

        .pc_i(id_pc_i),
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
        .ex_inst(ex_inst_i)
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

        // 送到执行阶段EX模块的信息
        .aluop_i(ex_aluop_i),
        .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),
        .reg2_i(ex_reg2_i),
        .waddr_i(ex_waddr_i),
        .we_i(ex_we_i),
        .inst_i(ex_inst_i),
      
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

        // 除法模块
        .div_result_i(div_result),
        .div_ready_i(div_ready),
        .div_opdata1_o(div_opdata1),
        .div_opdata2_o(div_opdata2),
        .div_start_o(div_start),
        .signed_div_o(signed_div),

        // 累加累减状态机
        .mul_result_i(ex_mul_result_i),
        .cnt_i(ex_cnt_i),
        .mul_result_o(ex_mul_result_o),
        .cnt_o(ex_cnt_o),

        .stallreq(stallreq_from_ex)
    );

    div div0(
        .clk(clk),
        .rst(rst),
        
        .signed_div_i(signed_div),
        
        .opdata1_i(div_opdata1),
        .opdata2_i(div_opdata2),
        .start_i(div_start),
        .annul_i(1'b0), // 目前还没有异常机制，不需要取消除法
        .result_o(div_result),
        .ready_o(div_ready)
    );

    // EX/MEM模块
    ex_mem ex_mem0(
        .clk(clk),
        .rst(rst),
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
        .mul_result_i(ex_mul_result_o),
        .cnt_i(ex_cnt_o),
    
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
        .mul_result_o(ex_mul_result_i),
        .cnt_o(ex_cnt_i)
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
      
        //送到MEM/WB模块的信息
        .waddr_o(mem_waddr_o),
        .we_o(mem_we_o),
        .wdata_o(mem_wdata_o),
        .hi_o(mem_hi_o),
        .lo_o(mem_lo_o),
        .we_hilo_o(mem_we_hilo_o),

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
        .stall(stall),

        //来自访存阶段MEM模块的信息    
        .mem_waddr(mem_waddr_o),
        .mem_we(mem_we_o),
        .mem_wdata(mem_wdata_o),
        .mem_hi(mem_hi_o),
        .mem_lo(mem_lo_o),
        .mem_we_hilo(mem_we_hilo_o),
    
        //送到回写阶段的信息
        .wb_waddr(wb_waddr_i),
        .wb_we(wb_we_i),
        .wb_wdata(wb_wdata_i),
        .wb_hi(wb_hi_i),
        .wb_lo(wb_lo_i),
        .wb_we_hilo(wb_we_hilo_i)
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

    // CTRL
    ctrl ctrl0(
        .clk(clk),
        .rst(rst),

        .stallreq_from_id(stallreq_from_id),
        .stallreq_from_ex(stallreq_from_ex),
        .stall(stall)
    );

endmodule
