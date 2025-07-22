`timescale 1ns / 1ps

module Proyecto_Final(
    input clk,
    input rst_n,               // Reset activo bajo
    input echo_i,              // ECHO desde sensor
    output trigger_o,          // TRIG hacia sensor
    output [7:0] LCD_DATA,
    output LCD_RS,
    output LCD_RW,
    output LCD_E
);

    wire rst = ~rst_n;

    // Señales internas
    wire ready_pulse;
    wire object_detected;
    wire [31:0] echo_count;

    reg [9:0] contador_objetos;
    reg object_detected_prev;
    wire detected_rise = (object_detected == 1'b1 && object_detected_prev == 1'b0);

    // Generador de pulsos
    generador_pulsos #(
        .CLOCK_FREQ(50_000_000),
        .PULSE_INTERVAL_MS(60)
    ) u_pulso (
        .clk(clk),
        .rst(rst),
        .pulse_out(ready_pulse)
    );

    // Sensor ultrasónico
    controlador_ultrasonido #(
        .CLOCK_FREQ(50_000_000),
        .DIST_THRESHOLD_CM(10)
    ) u_ultrasonido (
        .clk(clk),
        .rst(rst),
        .ready_i(ready_pulse),
        .echo_i(echo_i),
        .trigger_o(trigger_o),
        .object_detected_o(object_detected),
        .echo_counter(echo_count)
    );

    // Contador de objetos
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            contador_objetos <= 0;
            object_detected_prev <= 0;
        end else begin
            object_detected_prev <= object_detected;
            if (detected_rise) begin
                if (contador_objetos < 999)
                    contador_objetos <= contador_objetos + 1;
                else
                    contador_objetos <= 0;
            end
        end
    end

    // LCD Controller
    LCD_controller #(
        .NUM_COMMANDS(5),
        .NUM_DATA_ALL(32),
        .NUM_DATA_PERLINE(16),
        .DATA_BITS(8),
        .COUNT_MAX(800_000)
    ) u_lcd (
        .clk(clk),
        .rst(rst),
        .contador_externo(contador_objetos),
        .data(LCD_DATA),
        .rs(LCD_RS),
        .rw(LCD_RW),
        .en(LCD_E)
    );

endmodule
