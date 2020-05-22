//////////////////////////////////////////////////////////////////////////////////
// HikariMips
// 使用类SRAM接口，目前仅有指令寄存器的
// 标准SRAM五个信号线：read_addr  read_data  write_addr  write_data  write_valid
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module hikari_mips(
    input wire clk,
    input wire rst,

    // 指令寄存器类SRAM接口
    input wire[`RegBus] rom_data_i,
    output wire[`RegBus] rom_addr_o,
    output wire rom_ce_o
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
    wire id_we_o;
    wire[`RegAddrBus] id_waddr_o;
    
    // ID/EX -> EX
    wire[`AluOpBus] ex_aluop_i;
    wire[`AluSelBus] ex_alusel_i;
    wire[`RegBus] ex_reg1_i;
    wire[`RegBus] ex_reg2_i;
    wire ex_we_i;
    wire[`RegAddrBus] ex_waddr_i;
    
    // EX -> EX/MEM
    wire ex_we_o;
    wire[`RegAddrBus] ex_waddr_o;
    wire[`RegBus] ex_wdata_o;

    // EX/MEM -> MEM
    wire mem_we_i;
    wire[`RegAddrBus] mem_waddr_i;
    wire[`RegBus] mem_wdata_i;

    // MEM -> MEM/WB
    wire mem_we_o;
    wire[`RegAddrBus] mem_waddr_o;
    wire[`RegBus] mem_wdata_o;
    
    // MEM/WB -> WB   
    wire wb_we_i;
    wire[`RegAddrBus] wb_waddr_i;
    wire[`RegBus] wb_wdata_i;
    
    // ID -> Regfile
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegAddrBus] reg2_addr;
  
    // PC -> ROM
    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .ce(rom_ce_o)
    );
    assign rom_addr_o = pc;

    //  ROM -> IF/ID -> ID
    if_id if_id0(
        .clk(clk),
        .rst(rst),
        .if_pc(pc),
        .if_inst(rom_data_i),
        .id_pc(id_pc_i),
        .id_inst(id_inst_i)          
    );
    
    // IF/ID -> ID -> ID/EX
    id id0(
        .clk(clk),
        .rst(rst),

        .pc_i(id_pc_i),
        .inst_i(id_inst_i),

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

        // MEM反馈
        .mem_we_i(mem_we_o),
        .mem_wdata_i(mem_wdata_o),
        .mem_waddr_i(mem_waddr_o),

        //送到ID/EX模块的信息
        .aluop_o(id_aluop_o),
        .alusel_o(id_alusel_o),
        .reg1_data_o(id_reg1_o),
        .reg2_data_o(id_reg2_o),
        .waddr_o(id_waddr_o),
        .we_o(id_we_o)
    );

  //通用寄存器Regfile例化
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

    //ID/EX模块
    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        
        //从译码阶段ID模块传递的信息
        .id_aluop(id_aluop_o),
        .id_alusel(id_alusel_o),
        .id_reg1(id_reg1_o),
        .id_reg2(id_reg2_o),
        .id_waddr(id_waddr_o),
        .id_we(id_we_o),
    
        //传递到执行阶段EX模块的信息
        .ex_aluop(ex_aluop_i),
        .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i),
        .ex_reg2(ex_reg2_i),
        .ex_waddr(ex_waddr_i),
        .ex_we(ex_we_i)
    );        
    
    //EX模块
    ex ex0(
        .clk(clk),
        .rst(rst),
    
        //送到执行阶段EX模块的信息
        .aluop_i(ex_aluop_i),
        .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),
        .reg2_i(ex_reg2_i),
        .waddr_i(ex_waddr_i),
        .we_i(ex_we_i),
      
      //EX模块的输出到EX/MEM模块信息
        .waddr_o(ex_waddr_o),
        .we_o(ex_we_o),
        .wdata_o(ex_wdata_o)
        
    );

  //EX/MEM模块
  ex_mem ex_mem0(
        .clk(clk),
        .rst(rst),
      
        //来自执行阶段EX模块的信息    
        .ex_waddr(ex_waddr_o),
        .ex_we(ex_we_o),
        .ex_wdata(ex_wdata_o),
    
        //送到访存阶段MEM模块的信息
        .mem_waddr(mem_waddr_i),
        .mem_we(mem_we_i),
        .mem_wdata(mem_wdata_i)

    );
    
  //MEM模块例化
    mem mem0(
        .clk(clk),
        .rst(rst),
    
        //来自EX/MEM模块的信息    
        .waddr_i(mem_waddr_i),
        .we_i(mem_we_i),
        .wdata_i(mem_wdata_i),
      
        //送到MEM/WB模块的信息
        .waddr_o(mem_waddr_o),
        .we_o(mem_we_o),
        .wdata_o(mem_wdata_o)
    );

  //MEM/WB模块
    mem_wb mem_wb0(
        .clk(clk),
        .rst(rst),

        //来自访存阶段MEM模块的信息    
        .mem_waddr(mem_waddr_o),
        .mem_we(mem_we_o),
        .mem_wdata(mem_wdata_o),
    
        //送到回写阶段的信息
        .wb_waddr(wb_waddr_i),
        .wb_we(wb_we_i),
        .wb_wdata(wb_wdata_i)
    );

endmodule
