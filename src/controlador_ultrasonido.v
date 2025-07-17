module controlador_ultrasonido #(
    parameter TIME_TRIG = 500,
    parameter CLOCK_FREQ = 50_000_000,
    parameter SOUND_SPEED = 34300  // en cm/s
)(
    input clk,
    input rst,
    input ready_i,
    input echo_i,
    output wire trigger_o,
    output reg [31:0] echo_counter
);

localparam IDLE       = 2'b00;
localparam TRIGGER    = 2'b01;
localparam WAIT_ECHO  = 2'b10;
localparam COUNT_ECHO = 2'b11;

reg [1:0] fsm_state;
reg [1:0] next_state;

reg [$clog2(TIME_TRIG)-1:0] count_10us;

wire trigger_done;
assign trigger_o = (next_state == TRIGGER);
assign trigger_done = (count_10us == TIME_TRIG);

initial begin
    fsm_state <= IDLE;
    next_state <= IDLE;
    count_10us <= 0;
    echo_counter <= 0;
end

always @(negedge clk) begin
    if (rst)
        fsm_state <= IDLE;
    else
        fsm_state <= next_state;
end

always @(*) begin
    case (fsm_state)
        IDLE:        next_state = (ready_i) ? TRIGGER : IDLE;
        TRIGGER:     next_state = (trigger_done) ? WAIT_ECHO : TRIGGER;
        WAIT_ECHO:   next_state = (echo_i) ? COUNT_ECHO : WAIT_ECHO;
        COUNT_ECHO:  next_state = (echo_i) ? COUNT_ECHO : IDLE;
        default:     next_state = IDLE;
    endcase
end

always @(negedge clk) begin
    if (rst) begin
        count_10us <= 0;
        echo_counter <= 0;
    end else begin
        case (fsm_state)
            IDLE: begin
                count_10us <= 0;
                echo_counter <= 0;
            end
            TRIGGER: begin
                count_10us <= count_10us + 1;
            end
            WAIT_ECHO: begin
                echo_counter <= 0;
            end
            COUNT_ECHO: begin
                echo_counter <= echo_counter + 1;
            end
        endcase
    end
end

endmodule

