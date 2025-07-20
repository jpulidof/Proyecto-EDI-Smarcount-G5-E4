// tcs34725_controller.v
// FSM de control para el sensor TCS34725 usando el módulo i2c_master_read2bytes

module tcs34725_controller (
    input clk, rst,
    output reg start_i2c,
    input done_i2c, busy_i2c,
    output reg [6:0] dev_addr,
    output reg [7:0] reg_addr,
    input [15:0] data_in,
    output reg [15:0] red, green, blue,
    output reg ready
);
    reg [3:0] state;
    localparam IDLE=0, START_R=1, WAIT_R=2, START_G=3,
               WAIT_G=4, START_B=5, WAIT_B=6, DONE=7;
    localparam [6:0] SADDR=7'h29;
    localparam [7:0] RA=8'h16, GA=8'h18, BA=8'h1A;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE; start_i2c<=0;
            dev_addr<=0; reg_addr<=0; red<=0; green<=0; blue<=0; ready<=0;
        end else begin
            case (state)
                IDLE: if (!busy_i2c) begin
                    start_i2c<=1; dev_addr<=SADDR; reg_addr<=RA; ready<=0;
                    state<=START_R;
                end
                START_R: begin start_i2c<=0;
                    if (done_i2c) begin red<=data_in;
                        start_i2c<=1; reg_addr<=GA; state<=START_G;
                    end
                end
                START_G: begin start_i2c<=0;
                    if (done_i2c) begin green<=data_in;
                        start_i2c<=1; reg_addr<=BA; state<=START_B;
                    end
                end
                START_B: begin start_i2c<=0;
                    if (done_i2c) begin blue<=data_in;
                        ready<=1; state<=DONE;
                    end
                end
                DONE: begin ready<=0; state<=IDLE; end
            endcase
        end
    end
endmodule
