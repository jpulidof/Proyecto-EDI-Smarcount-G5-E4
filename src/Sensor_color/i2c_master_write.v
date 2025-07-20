// i2c_master_write.v
// Escritura I²C de 1 byte en un registro

module i2c_master_write (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [6:0] dev_addr,
    input wire [7:0] reg_addr,
    input wire [7:0] data_in,
    output reg busy,
    output reg done,
    inout wire sda,
    output reg scl
);

    // Parámetros FSM
    localparam IDLE=0, START=1, DEV_ADDR=2, REG_ADDR=3, DATA=4, STOP=5, DONE=6;
    reg [2:0] state, next_state;
    reg [7:0] clk_div_cnt;
    reg tick;
    parameter CLK_DIV=250;

    // Divisor para ~100 kHz
    always @(posedge clk or posedge rst) begin
        if (rst) clk_div_cnt <= 0;
        else if (clk_div_cnt == CLK_DIV-1) clk_div_cnt <= 0;
        else clk_div_cnt <= clk_div_cnt +1;
        tick <= (clk_div_cnt == CLK_DIV-1);
    end

    // FSM estado
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else if (tick) state <= next_state;
    end

    // Control FSM
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;
    reg sda_out, sda_oe;

    always @(*) begin
        next_state = state;
        busy = (state != IDLE);
        done = (state == DONE);
        if (state==IDLE && start) next_state = START;
        else if (state==START) next_state = DEV_ADDR;
        else if ((state==DEV_ADDR || state==REG_ADDR || state==DATA) && bit_cnt==8) begin
            if (state==DEV_ADDR) next_state = REG_ADDR;
            else if (state==REG_ADDR) next_state = DATA;
            else next_state = STOP;
        end else if (state==STOP) next_state = DONE;
        else if (state==DONE) next_state = IDLE;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) bit_cnt <= 0;
        else if (tick) begin
            if (state==START)
                bit_cnt <= 0;
            else if (state==DEV_ADDR && bit_cnt<8)
                bit_cnt <= bit_cnt+1;
            else if (state==REG_ADDR && bit_cnt<8)
                bit_cnt <= bit_cnt+1;
            else if (state==DATA && bit_cnt<8)
                bit_cnt <= bit_cnt+1;
            else if (state==STOP)
                bit_cnt <= 0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) shift_reg <= 0;
        else if (tick) begin
            if (state==START)
                shift_reg <= {dev_addr,1'b0};
            else if (state==DEV_ADDR && bit_cnt==0)
                shift_reg <= reg_addr;
            else if (state==REG_ADDR && bit_cnt==0)
                shift_reg <= data_in;
            else if ((state==DEV_ADDR||state==REG_ADDR||state==DATA)&& bit_cnt>0)
                shift_reg <= {shift_reg[6:0],1'b0};
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin scl<=1; sda_out<=1; sda_oe<=0; end
        else if (tick) begin
            case (state)
                START: begin sda_out<=0; sda_oe<=1; scl<=1; end
                DEV_ADDR, REG_ADDR, DATA: begin
                    scl <= ~scl;
                    if (scl) sda_out<=shift_reg[7];
                    sda_oe <= 1;
                end
                STOP: begin sda_out<=0; sda_oe<=1; scl<=1; end
                DONE: begin sda_out<=1; sda_oe<=0; scl<=1; end
                default: begin scl<=1; sda_out<=1; sda_oe<=0; end
            endcase
        end
    end

    assign sda = sda_oe ? sda_out : 1'bz;

endmodule
