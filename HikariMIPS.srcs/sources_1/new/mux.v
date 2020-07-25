module mux(
    input wire rst,
    //输入信号
    input wire[`RegBus] pc_i,
    input wire[`RegBus] inst_i,
    input wire[`AluOpBus] aluop_i,
    input wire[`AluSelBus] alusel_i,
    input wire[`RegAddrBus] waddr_i,
    input wire we_i,
    input wire[`RegBus] imm_i,
    input wire[`RegBus] link_addr_i,
    input wire[`RegBus] exceptions_i,
    input wire taken_i,
    input wire[`RegBus] branch_target_address_i,

    input wire re1_i,
    input wire[`RegAddrBus] raddr1_i,
    input wire[`RegBus] rdata1_i,
    input wire re2_i,
    input wire[`RegAddrBus] raddr2_i,
    input wire[`RegBus] rdata2_i,

    //ex阶段的aluop，用于判断load相关
    input wire[`AluOpBus] ex_aluop_i,

    // ID/EX反馈指示当前指令是否在延迟槽内
    input wire is_in_delayslot_i,
    // branch likely指令是否无效化延迟槽
    input wire is_nullified_i,

    //regfile数据前推
    input wire ex_we_i,
    input wire[`RegBus] ex_wdata_i,
    input wire[`RegAddrBus] ex_waddr_i,
    input wire mem_we_i,
    input wire[`RegBus] mem_wdata_i,
    input wire[`RegAddrBus] mem_waddr_i,
    input wire wb_we_i,
    input wire[`RegBus] wb_wdata_i,
    input wire[`RegAddrBus] wb_waddr_i,

    // hi/LO寄存器
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i, 
    //hilo数据前推
    input wire[`RegBus] ex_hi_i,
    input wire[`RegBus] ex_lo_i,
    input wire ex_we_hilo_i,
    input wire[`RegBus] mem_hi_i,
    input wire[`RegBus] mem_lo_i,
    input wire mem_we_hilo_i,

    //cp0寄存器
    input wire[7:0] cp0_raddr_i,
    input wire[`RegBus] cp0_rdata_i,
    //cp0数据前推
    input wire mem_cp0_we_i,
    input wire[7:0] mem_cp0_waddr_i,
    input wire[`RegBus] mem_cp0_wdata_i,
    input wire ex_cp0_we_i,
    input wire[7:0] ex_cp0_waddr_i,
    input wire[`RegBus] ex_cp0_wdata_i,

    //数据输出
    output reg[`RegBus] pc_o,//
    output reg[`RegBus] inst_o,//
    output reg[`AluOpBus] aluop_o,//
    output reg[`AluSelBus] alusel_o,//
    output reg[`RegAddrBus] waddr_o,//
    output reg we_o,//
    output reg[`RegBus] link_addr_o,//
    output reg[`RegBus] exceptions_o,//
    output reg[`RegBus] reg1_data_o,//
    output reg[`RegBus] reg2_data_o,//
    // 告诉EX当前指令是否在延迟槽内
    output reg is_in_delayslot_o,//
    // 标识下一条指令是否在延迟槽内
    output reg next_inst_in_delayslot_o,//
    // 标识下一条指令被branch likely无效化
    output reg next_inst_is_nullified_o,//
    //hilo寄存器
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,
    //cp0寄存器输出
    output reg[`RegBus] cp0_rdata_o,

    //分支预测器修正
    output reg branch_ce,
    output reg branch_taken,
    //对pc进行修改
    output reg flush_pc,
    output reg[`RegBus] correct_pc,//当分支预测错误时向pc传输正确的值

    output wire stallreq
);

    // 暂停流水线的请求
    // 两个寄存器的LOAD相关状态
    reg stallreq_for_reg1_loadrelated;
    reg stallreq_for_reg2_loadrelated;
     // 上一条指令是否为加载类指令
    wire pre_inst_is_load = ( (ex_aluop_i == `MEM_OP_LB) || 
                                (ex_aluop_i == `MEM_OP_LBU)||
                                (ex_aluop_i == `MEM_OP_LH) ||
                                (ex_aluop_i == `MEM_OP_LHU)||
                                (ex_aluop_i == `MEM_OP_LW) ||
                                (ex_aluop_i == `MEM_OP_LWR)||
                                (ex_aluop_i == `MEM_OP_LWL)||
                                (ex_aluop_i == `MEM_OP_LL) ||
                                (ex_aluop_i == `MEM_OP_SC)) ? 1'b1 : 1'b0;
    // 产生stallreq，任意一种暂停请求生效，都向CTRL发起暂停请求
    assign stallreq = stallreq_for_reg1_loadrelated | stallreq_for_reg2_loadrelated;

    //reg1数据选择
    always @ (*) begin
        // 一上来就要重置相关情况，因为只要暂停一拍
        stallreq_for_reg1_loadrelated <= `NoStop;
        if(rst == `RstEnable) begin
            reg1_data_o <= `ZeroWord;
        // 这里如果上一条是加载指令且加载的目标寄存器就是端口1读取的
        // 那么就申请暂停流水线以解决LOAD相关
        end else if(pre_inst_is_load && ex_waddr_i == raddr1_i && re1_i == `ReadEnable ) begin
            stallreq_for_reg1_loadrelated <= `Stop;
        end else if(re1_i == `ReadEnable && ex_we_i == `WriteEnable && ex_waddr_i == raddr1_i) begin
            // 端口1请求的数据正好是执行阶段（比访存阶段新）产生的将写入的数据
            reg1_data_o <= ex_wdata_i;
        end else if(re1_i == `ReadEnable && mem_we_i == `WriteEnable && mem_waddr_i == raddr1_i) begin
            // 端口1请求的数据正好是访存阶段（比寄存器堆新）产生的将写入数据
            reg1_data_o <= mem_wdata_i;
        end else if(re1_i == `ReadEnable && wb_we_i == `WriteEnable && wb_waddr_i == raddr1_i) begin
            reg1_data_o <= wb_wdata_i;
        end else if(re1_i == `ReadEnable) begin
            // 读端口1
            reg1_data_o <= rdata1_i;
        end else if(re1_i == `ReadDisable) begin
            // 如果端口1不需要读，就用给立即数
            // 目前来说端口1无论如何都是要读的（rs）
            // 这样写只是为了与端口2比较规整
            reg1_data_o <= imm_i;
        end else begin
            // 一般不会出现这种情况，但是完备的if..else if..else语句综合后更高效
            reg1_data_o <= `ZeroWord;
        end
    end

    //reg2数据选择
    always @ (*) begin
        // 一上来就要重置相关情况，因为只要暂停一拍
        stallreq_for_reg2_loadrelated <= `NoStop;
        if(rst == `RstEnable) begin
            reg2_data_o <= `ZeroWord;
        // 这里如果上一条是加载指令且加载的目标寄存器就是端口2读取的
        // 那么就申请暂停流水线以解决LOAD相关
        end else if(pre_inst_is_load && ex_waddr_i == raddr2_i && re2_i == `ReadEnable ) begin
            stallreq_for_reg2_loadrelated <= `Stop;
        end else if(re2_i == `ReadEnable && ex_we_i == `WriteEnable && ex_waddr_i == raddr2_i) begin
            // 端口2请求的数据正好是执行阶段（比访存阶段新）产生的将写入的数据
            reg2_data_o <= ex_wdata_i;
        end else if(re2_i == `ReadEnable && mem_we_i == `WriteEnable && mem_waddr_i == raddr2_i) begin
            // 端口2请求的数据正好是访存阶段（比寄存器堆新）产生的将写入数据
            reg2_data_o <= mem_wdata_i;
        end else if(re2_i == `ReadEnable && wb_we_i == `WriteEnable && wb_waddr_i == raddr2_i) begin
            reg2_data_o <= wb_wdata_i;
        end else if(re2_i == `ReadEnable) begin
            // 读端口2
            reg2_data_o <= rdata2_i;
        end else if(re2_i == `ReadDisable) begin
            // 如果端口2不需要读，就用给立即数
            reg2_data_o <= imm_i;
        end else begin
            // 一般不会出现这种情况，但是完备的if..else if..else语句综合后更高效
            reg2_data_o <= `ZeroWord;
        end
    end

    //hilo数据选择
    always @ (*) begin
        if(rst == `RstEnable) begin
            {hi_o,lo_o} <= {`ZeroWord,`ZeroWord};
        end else if(ex_we_hilo_i == `WriteEnable) begin
            {hi_o,lo_o} <= {ex_hi_i,ex_lo_i};
        end else if(mem_we_hilo_i == `WriteEnable) begin
            {hi_o,lo_o} <= {mem_hi_i,mem_lo_i};
        end else begin
            {hi_o,lo_o} <= {hi_i,lo_i};            
        end
    end

    //cp0数据选择
    always @ (*) begin
        if(rst == `RstEnable) begin
            cp0_rdata_o <= `ZeroWord;
        end else if(ex_cp0_we_i == `WriteEnable && ex_cp0_waddr_i == cp0_raddr_i) begin
            cp0_rdata_o <= ex_cp0_wdata_i;
        end else if(mem_cp0_we_i == `WriteEnable && mem_cp0_waddr_i == cp0_raddr_i) begin
            cp0_rdata_o <= mem_cp0_wdata_i;
        end else begin
            cp0_rdata_o <= cp0_rdata_i;
        end
    end

    //跳转指令处理
    always @ (*) begin
        if(rst == `RstEnable) begin
            branch_ce <= 1'b0;
            branch_taken <= `NOTAKEN;
            flush_pc <= 1'b0;
            correct_pc <= `ZeroWord;
            next_inst_in_delayslot_o <= 1'b0;
            next_inst_is_nullified_o <= 1'b0;
        end else begin
            next_inst_in_delayslot_o <= 1'b1;
            next_inst_is_nullified_o <= 1'b0;
            case (aluop_i)
                `ALU_OP_JR: begin
                    if(branch_target_address_i != reg1_data_o) begin
                        flush_pc <= 1'b1;
                        correct_pc <= reg1_data_o;
                    end else begin
                    end
                end
                `ALU_OP_JALR: begin
                    if(branch_target_address_i != reg1_data_o) begin
                        flush_pc <= 1'b1;
                        correct_pc <= reg1_data_o;
                    end else begin
                    end
                end
                `ALU_OP_BLTZ: begin
                    correct_pc <= imm_i;
                    branch_ce <= 1'b1;
                    branch_taken <= (reg1_data_o[31]) ? `TAKEN : `NOTAKEN;
                    flush_pc <= (branch_taken == taken_i) ? 1'b0 : 1'b1;//若预测与实际不符则清空pc
                end
                `ALU_OP_BLTZL: begin
                    
                end
                `ALU_OP_BGEZ: begin
                    correct_pc <= imm_i;
                    branch_ce <= 1'b1;
                    branch_taken <= (!reg1_data_o[31]) ? `TAKEN : `NOTAKEN;
                    flush_pc <= (branch_taken == taken_i) ? 1'b0 : 1'b1;//若预测与实际不符则清空pc
                end
                `ALU_OP_BGEZL: begin
                    
                end
                `ALU_OP_BLTZAL: begin
                    correct_pc <= imm_i;
                    branch_ce <= 1'b1;
                    branch_taken <= (reg1_data_o[31]) ? `TAKEN : `NOTAKEN;
                    flush_pc <= (branch_taken == taken_i) ? 1'b0 : 1'b1;//若预测与实际不符则清空pc
                end
                `ALU_OP_BLTZALL: begin
                    
                end
                `ALU_OP_BGEZAL: begin
                    correct_pc <= imm_i;
                    branch_ce <= 1'b1;
                    branch_taken <= (!reg1_data_o[31]) ? `TAKEN : `NOTAKEN;
                    flush_pc <= (branch_taken == taken_i) ? 1'b0 : 1'b1;//若预测与实际不符则清空pc
                end
                `ALU_OP_BGEZALL: begin
                    
                end
                `ALU_OP_BEQ: begin
                    correct_pc <= imm_i;
                    branch_ce <= 1'b1;
                    //branch_taken <= 1'b1;
                    //flush_pc <= 1'b0;
                    branch_taken <= (reg1_data_o == reg2_data_o) ? `TAKEN : `NOTAKEN;
                    flush_pc <= (branch_taken == taken_i) ? 1'b0 : 1'b1;//若预测与实际不符则清空pc
                end
                `ALU_OP_BEQL: begin
                    
                end
                `ALU_OP_BNE: begin
                    correct_pc <= imm_i;
                    branch_ce <= 1'b1;
                    branch_taken <= (reg1_data_o != reg2_data_o) ? `TAKEN : `NOTAKEN;
                    flush_pc <= (branch_taken == taken_i) ? 1'b0 : 1'b1;//若预测与实际不符则清空pc
                end
                `ALU_OP_BNEL: begin
                    
                end
                `ALU_OP_BGTZ: begin
                    correct_pc <= imm_i;
                    branch_ce <= 1'b1;
                    branch_taken <= (!reg1_data_o[31] && reg1_data_o != `ZeroWord) ? `TAKEN : `NOTAKEN;
                    flush_pc <= (branch_taken == taken_i) ? 1'b0 : 1'b1;//若预测与实际不符则清空pc
                end
                `ALU_OP_BGTZL: begin
                    
                end
                `ALU_OP_BLEZ: begin
                    correct_pc <= imm_i;
                    branch_ce <= 1'b1;
                    branch_taken <= (reg1_data_o[31] || reg1_data_o == `ZeroWord) ? `TAKEN : `NOTAKEN;
                    flush_pc <= (branch_taken == taken_i) ? 1'b0 : 1'b1;//若预测与实际不符则清空pc
                end
                `ALU_OP_BLEZL: begin
                    
                end
                default: begin
                    branch_ce <= 1'b0;
                    branch_taken <= 1'b0;
                    flush_pc <= 1'b0;
                end
            endcase
        end
    end

    //其他数据
    always @ (*) begin
        if(rst == `RstEnable || is_nullified_i) begin
            pc_o <= `ZeroWord;
            inst_o <= `ZeroWord;
            aluop_o <= `ALU_OP_NOP;
            alusel_o <= `ALU_SEL_NOP;
            waddr_o <= `NOPRegAddr;
            we_o <= `WriteDisable;
            link_addr_o <= `ZeroWord;
            exceptions_o <= `ZeroWord;
            // 处理延迟槽信号
            is_in_delayslot_o <= `False_v;
        end else begin
            pc_o <= pc_i;
            inst_o <= inst_i;
            aluop_o <= aluop_i;
            alusel_o <= alusel_i;
            waddr_o <= waddr_i;
            link_addr_o <= link_addr_i;
            exceptions_o <= exceptions_i;
            is_in_delayslot_o <= is_in_delayslot_i;
            if ((aluop_i == `ALU_OP_MOVN) && (reg2_data_o != `ZeroWord)) begin
                we_o <= `WriteEnable;
            end else if((aluop_i == `ALU_OP_MOVZ) && (reg2_data_o == `ZeroWord)) begin
                we_o <= `WriteEnable;
            end else begin
                we_o <= we_i;
            end
        end
    end

    
endmodule