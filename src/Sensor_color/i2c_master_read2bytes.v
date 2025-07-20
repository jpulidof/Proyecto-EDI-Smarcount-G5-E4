// i2c_master_read2bytes.v
// Módulo I2C Master para lectura de 2 bytes desde un esclavo (como TCS34725)

module i2c_master_read2bytes (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [6:0] dev_addr,
    input wire [7:0] reg_addr,
    output reg [15:0] data_out,
    output reg busy,
    output reg done,
    inout wire sda,
    output reg scl
);

    // Parámetros de estado FSM
    localparam IDLE      = 0,
               START1    = 1,
               WRITE_DEV = 2,
               WRITE_REG = 3,
               REP_START = 4,
               READ_DEV  = 5,
               READ_BYTE1 = 6,
               READ_BYTE2 = 7,
               STOP      = 8,
               DONE      = 9;

    reg [3:0] state, next_state;

    // Control de clock I2C (~100kHz)
    parameter CLK_DIV = 250;  // ajusta según tu frecuencia de clk
    reg [7:0] clk_div_cnt;
    reg tick;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div_cnt <= 0;
            tick <= 0;
        end else if (clk_div_cnt == CLK_DIV-1) begin
            clk_div_cnt <= 0;
            tick <= 1;
        end else begin
            clk_div_cnt <= clk_div_cnt + 1;
            tick <= 0;
        end
    end

    // FSM principal
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else if (tick) state <= next_state;
    end

    // Señales de control
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;
    reg sda_out, sda_oe;
    reg read_phase;
    reg ack_bit;

    wire sda_in = sda;

    // Transición de estados
    always @(*) begin
        next_state = state;
        busy = (state != IDLE && state != DONE);
        done = (state == DONE);

        case (state)
            IDLE:      if (start)         next_state = START1;
            START1:                       next_state = WRITE_DEV;
            WRITE_DEV: if (bit_cnt == 8)  next_state = WRITE_REG;
            WRITE_REG: if (bit_cnt == 8)  next_state = REP_START;
            REP_START:                    next_state = READ_DEV;
            READ_DEV:  if (bit_cnt == 8)  next_state = READ_BYTE1;
            READ_BYTE1:if (bit_cnt == 8)  next_state = READ_BYTE2;
            READ_BYTE2:if (bit_cnt == 8)  next_state = STOP;
            STOP:                         next_state = DONE;
            DONE:                         next_state = IDLE;
        endcase
    end

    // Contador de bits
    always @(posedge clk or posedge rst) begin
        if (rst) bit_cnt <= 0;
        else if (tick) begin
            case (state)
                WRITE_DEV, WRITE_REG, READ_DEV, READ_BYTE1, READ_BYTE2:
                    if (bit_cnt < 8) bit_cnt <= bit_cnt + 1;
                    else bit_cnt <= 0;
                default: bit_cnt <= 0;
            endcase
        end
    end

    // Registro de datos
    always @(posedge clk or posedge rst) begin
        if (rst) shift_reg <= 0;
        else if (tick) begin
            case (state)
                START1:     shift_reg <= {dev_addr, 1'b0}; // write
                WRITE_DEV:  if (bit_cnt == 0) shift_reg <= reg_addr;
                WRITE_REG:  if (bit_cnt == 0) shift_reg <= {dev_addr, 1'b1}; // read
                READ_DEV:   if (bit_cnt == 0) shift_reg <= 8'h00; // dummy
                default:    if ((state == WRITE_DEV || state == WRITE_REG || state == READ_DEV) && bit_cnt != 0)
                                shift_reg <= {shift_reg[6:0], 1'b0};
            endcase
        end
    end

    // Lectura de datos recibidos
    always @(posedge clk or posedge rst) begin
        if (rst) data_out <= 16'd0;
        else if (tick) begin
            if (state == READ_BYTE1 && bit_cnt < 8)
                data_out[15 - bit_cnt] <= sda_in;
            else if (state == READ_BYTE2 && bit_cnt < 8)
                data_out[7 - bit_cnt] <= sda_in;
        end
    end

    // Generación de SDA y SCL
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sda_out <= 1;
            sda_oe  <= 0;
            scl     <= 1;
        end else if (tick) begin
            case (state)
                START1, REP_START: begin
                    sda_out <= 0;
                    sda_oe  <= 1;
                    scl     <= 1;
                end
                WRITE_DEV, WRITE_REG, READ_DEV: begin
                    scl     <= ~scl;
                    if (~scl) begin
                        sda_out <= shift_reg[7];
                        sda_oe  <= 1;
                    end
                end
                READ_BYTE1, READ_BYTE2: begin
                    scl     <= ~scl;
                    sda_oe  <= 0;
                end
                STOP: begin
                    sda_out <= 0;
                    sda_oe  <= 1;
                    scl     <= 1;
                end
                DONE: begin
                    sda_out <= 1;
                    sda_oe  <= 0;
                    scl     <= 1;
                end
                default: begin
                    scl     <= 1;
                    sda_out <= 1;
                    sda_oe  <= 0;
                end
            endcase
        end
    end

    assign sda = sda_oe ? sda_out : 1'bz;

endmodule
