`include "defines.v"
module branch(
    input wire clk,
    input wire rst,
    input wire[`RegBus] pc_i,

    input wire update_ce,//更新寄存器信号
    input wire update_taken,//上一条指令是否跳转
    input wire[`RegBus] update_pc,//上一条指令的pc

    input wire update_ras,//预测正确的话对ras进行出栈操作

    output reg[`RegBus] prediction_pc,//预测得到的间接跳转值

    output reg taken//是否跳转

);

reg[3:0] BHR[15:0];
reg[1:0] PHT[15:0];
wire[3:0] PHTAddr;
reg[`RegBus] RAS[15:0];//ras栈存储过程跳转返回地址对间接跳转进行猜测
reg[3:0] RASptr;//ras栈指针


assign PHTAddr = BHR[pc_i[27:24]] ^ pc_i[3:0];

    always @ (*) begin
        if (rst == `RstEnable) begin
            taken <= 1'b0;
            BHR[0] <= 4'h0;
            BHR[1] <= 4'h0;
            BHR[2] <= 4'h0;
            BHR[3] <= 4'h0;
            BHR[4] <= 4'h0;
            BHR[5] <= 4'h0;
            BHR[6] <= 4'h0;
            BHR[7] <= 4'h0;
            BHR[8] <= 4'h0;
            BHR[9] <= 4'h0;
            BHR[10] <= 4'h0;
            BHR[11] <= 4'h0;
            BHR[12] <= 4'h0;
            BHR[13] <= 4'h0;
            BHR[14] <= 4'h0;
            BHR[15] <= 4'h0;
            PHT[0] <= 2'b10;
            PHT[1] <= 2'b10;
            PHT[2] <= 2'b10;
            PHT[3] <= 2'b10;
            PHT[4] <= 2'b10;
            PHT[5] <= 2'b10;
            PHT[6] <= 2'b10;
            PHT[7] <= 2'b10;
            PHT[8] <= 2'b10;
            PHT[9] <= 2'b10;
            PHT[10] <= 2'b10;
            PHT[11] <= 2'b10;
            PHT[12] <= 2'b10;
            PHT[13] <= 2'b10;
            PHT[14] <= 2'b10;
            PHT[15] <= 2'b10;
        end else begin
            case (PHT[PHTAddr])
                `StronglyTaken: begin
                    taken <= `TAKEN;
                end
                `WeaklyTaken: begin
                    taken <= `TAKEN;
                end
                `WeaklyNoTaken: begin
                    taken <= `NOTAKEN;
                end
                `StronglyNoTaken: begin
                    taken <= `NOTAKEN;
                end
                default: begin
                end
            endcase
        end
    end
reg[3:0] up_PHTAddr;
    //更新分支预测器
    always @ (posedge clk) begin
        if(update_ce == 1'b1) begin
            up_PHTAddr <= BHR[update_pc[27:24]] ^ update_pc[3:0];
            BHR[update_pc[27:24]] <= {PHTAddr[2:0],update_taken};
            if (update_taken == 1'b1) begin
                PHT[up_PHTAddr] <= (PHT[up_PHTAddr] == `StronglyTaken) ? `StronglyTaken : PHT[up_PHTAddr] + 1;
            end else begin
                PHT[up_PHTAddr] <= (PHT[up_PHTAddr] == `StronglyNoTaken) ? `StronglyNoTaken : PHT[up_PHTAddr] - 1;
            end
        end else if (update_ras == 1'b1) begin  //间接跳转预测器修正
            RASptr = RASptr - 1;
        end else begin
        end
    end
    //间接跳转分支预测
    always @ (*) begin
        if(rst == `RstEnable) begin
            RASptr <= `ZeroWord;
            RAS[0] <= `ZeroWord;
            RAS[1] <= `ZeroWord;
            RAS[2] <= `ZeroWord;
            RAS[3] <= `ZeroWord;
            RAS[4] <= `ZeroWord;
            RAS[5] <= `ZeroWord;
            RAS[6] <= `ZeroWord;
            RAS[7] <= `ZeroWord;
            RAS[8] <= `ZeroWord;
            RAS[9] <= `ZeroWord;
            RAS[10] <= `ZeroWord;
            RAS[11] <= `ZeroWord;
            RAS[12] <= `ZeroWord;
            RAS[13] <= `ZeroWord;
            RAS[14] <= `ZeroWord;
            RAS[15] <= `ZeroWord;
        end else begin
            //若遇到AL类的分支指令，保持返回地址
            if(({pc_i[31:26],pc_i[20:16]} == 11'b00000110001) ||
            {pc_i[31:26],pc_i[20:16]} == 11'b00000110000 ||
            {pc_i[31:26]} == 6'b000011 ||
            {pc_i[31:26],pc_i[5:0]} == 12'b000000001001) begin
                RAS[RASptr] <= pc_i;
                RASptr <= RASptr + 1;
            end else begin
                prediction_pc <= RAS[RASptr - 1];
            end
        end
    end

endmodule