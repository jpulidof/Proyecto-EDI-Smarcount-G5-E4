// i2c_master_read2bytes.v
// Módulo I2C Master para lectura de 2 bytes desde un esclavo (como TCS34725)

module i2c_master_read2bytes (
    input wire clk,            // Reloj del sistema
    input wire rst,            // Reset
    input wire start,          // Iniciar transacción
    input wire [6:0] dev_addr, // Dirección del esclavo (7 bits)
    input wire [7:0] reg_addr, // Registro a leer
    output reg [15:0] data_out,// Datos de 2 bytes leídos
    output reg busy,           // Señal de ocupado
    output reg done,           // Operación finalizada
    inout wire sda,            // Línea de datos I2C
    output reg scl             // Línea de reloj I2C
);

    // Internos
    reg [3:0] state;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;
    reg sda_out, sda_oe;
    assign sda = sda_oe ? sda_out : 1'bz;

    reg [7:0] byte1, byte2;
    reg [7:0] clk_div;
    wire tick = (clk_div == 0);

    // Estados
    localparam IDLE     = 0,
               START    = 1,
               SLA_W    = 2,
               REG      = 3,
               REP_START= 4,
               SLA_R    = 5,
               READ1    = 6,
               ACK1     = 7,
               READ2    = 8,
               NACK     = 9,
               STOP     = 10,
               DONE     = 11;

    // Temporizador simple para generar ticks de reloj lento
    always @(posedge clk or posedge rst) begin
        if (rst) clk_div <= 8'd200;
        else clk_div <= tick ? 8'd200 : clk_div - 1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            scl <= 1;
            sda_out <= 1;
            sda_oe <= 1;
            busy <= 0;
            done <= 0;
            data_out <= 0;
        end else if (tick) begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        busy <= 1;
                        state <= START;
                    end
                end
                START: begin
                    sda_out <= 0;
                    scl <= 1;
                    state <= SLA_W;
                    shift_reg <= {dev_addr, 1'b0};
                    bit_cnt <= 7;
                end
                SLA_W: begin
                    scl <= 0;
                    sda_out <= shift_reg[bit_cnt];
                    scl <= 1;
                    if (bit_cnt == 0) state <= REG;
                    else bit_cnt <= bit_cnt - 1;
                end
                REG: begin
                    scl <= 0;
                    shift_reg <= reg_addr;
                    bit_cnt <= 7;
                    state <= REP_START;
                end
                REP_START: begin
                    scl <= 1;
                    sda_out <= 1;
                    sda_out <= 0;
                    state <= SLA_R;
                    shift_reg <= {dev_addr, 1'b1};
                    bit_cnt <= 7;
                end
                SLA_R: begin
                    scl <= 0;
                    sda_out <= shift_reg[bit_cnt];
                    scl <= 1;
                    if (bit_cnt == 0) state <= READ1;
                    else bit_cnt <= bit_cnt - 1;
                end
                READ1: begin
                    scl <= 0;
                    sda_oe <= 0;
                    scl <= 1;
                    byte1[bit_cnt] <= sda;
                    if (bit_cnt == 0) state <= ACK1;
                    else bit_cnt <= bit_cnt - 1;
                end
                ACK1: begin
                    scl <= 0;
                    sda_oe <= 1;
                    sda_out <= 0; // ACK
                    scl <= 1;
                    bit_cnt <= 7;
                    state <= READ2;
                end
                READ2: begin
                    scl <= 0;
                    sda_oe <= 0;
                    scl <= 1;
                    byte2[bit_cnt] <= sda;
                    if (bit_cnt == 0) state <= NACK;
                    else bit_cnt <= bit_cnt - 1;
                end
                NACK: begin
                    scl <= 0;
                    sda_oe <= 1;
                    sda_out <= 1;
                    scl <= 1;
                    state <= STOP;
                end
                STOP: begin
                    scl <= 1;
                    sda_out <= 0;
                    sda_out <= 1;
                    sda_oe <= 1;
                    state <= DONE;
                end
                DONE: begin
                    busy <= 0;
                    done <= 1;
                    data_out <= {byte2, byte1};
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
