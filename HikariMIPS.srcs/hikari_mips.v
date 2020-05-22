//////////////////////////////////////////////////////////////////////////////////
// HikariMips
// ʹ����SRAM�ӿڣ�Ŀǰ����ָ��Ĵ�����
// ��׼SRAM����ź��ߣ�read_addr  read_data  write_addr  write_data  write_valid
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module hikari_mips(
    input wire clk,
    input wire rst,

    // ָ��Ĵ�����SRAM�ӿ�
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

        // ��regfile����
        .re1_o(reg1_read),   
        .raddr1_o(reg1_addr),
        .rdata1_i(reg1_data),
        .re2_o(reg2_read),    
        .raddr2_o(reg2_addr), 
        .rdata2_i(reg2_data),

        // EX����
        .ex_we_i(ex_we_o),
        .ex_wdata_i(ex_wdata_o),
        .ex_waddr_i(ex_waddr_o),

        // MEM����
        .mem_we_i(mem_we_o),
        .mem_wdata_i(mem_wdata_o),
        .mem_waddr_i(mem_waddr_o),

        //�͵�ID/EXģ�����Ϣ
        .aluop_o(id_aluop_o),
        .alusel_o(id_alusel_o),
        .reg1_data_o(id_reg1_o),
        .reg2_data_o(id_reg2_o),
        .waddr_o(id_waddr_o),
        .we_o(id_we_o)
    );

  //ͨ�üĴ���Regfile����
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

    //ID/EXģ��
    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        
        //������׶�IDģ�鴫�ݵ���Ϣ
        .id_aluop(id_aluop_o),
        .id_alusel(id_alusel_o),
        .id_reg1(id_reg1_o),
        .id_reg2(id_reg2_o),
        .id_waddr(id_waddr_o),
        .id_we(id_we_o),
    
        //���ݵ�ִ�н׶�EXģ�����Ϣ
        .ex_aluop(ex_aluop_i),
        .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i),
        .ex_reg2(ex_reg2_i),
        .ex_waddr(ex_waddr_i),
        .ex_we(ex_we_i)
    );        
    
    //EXģ��
    ex ex0(
        .clk(clk),
        .rst(rst),
    
        //�͵�ִ�н׶�EXģ�����Ϣ
        .aluop_i(ex_aluop_i),
        .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),
        .reg2_i(ex_reg2_i),
        .waddr_i(ex_waddr_i),
        .we_i(ex_we_i),
      
      //EXģ��������EX/MEMģ����Ϣ
        .waddr_o(ex_waddr_o),
        .we_o(ex_we_o),
        .wdata_o(ex_wdata_o)
        
    );

  //EX/MEMģ��
  ex_mem ex_mem0(
        .clk(clk),
        .rst(rst),
      
        //����ִ�н׶�EXģ�����Ϣ    
        .ex_waddr(ex_waddr_o),
        .ex_we(ex_we_o),
        .ex_wdata(ex_wdata_o),
    
        //�͵��ô�׶�MEMģ�����Ϣ
        .mem_waddr(mem_waddr_i),
        .mem_we(mem_we_i),
        .mem_wdata(mem_wdata_i)

    );
    
  //MEMģ������
    mem mem0(
        .clk(clk),
        .rst(rst),
    
        //����EX/MEMģ�����Ϣ    
        .waddr_i(mem_waddr_i),
        .we_i(mem_we_i),
        .wdata_i(mem_wdata_i),
      
        //�͵�MEM/WBģ�����Ϣ
        .waddr_o(mem_waddr_o),
        .we_o(mem_we_o),
        .wdata_o(mem_wdata_o)
    );

  //MEM/WBģ��
    mem_wb mem_wb0(
        .clk(clk),
        .rst(rst),

        //���Էô�׶�MEMģ�����Ϣ    
        .mem_waddr(mem_waddr_o),
        .mem_we(mem_we_o),
        .mem_wdata(mem_wdata_o),
    
        //�͵���д�׶ε���Ϣ
        .wb_waddr(wb_waddr_i),
        .wb_we(wb_we_i),
        .wb_wdata(wb_wdata_i)
    );

endmodule
