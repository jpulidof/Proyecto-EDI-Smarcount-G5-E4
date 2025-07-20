`include "ultrasonic_controller.v"
`include "generador_pulsos.v"

module top_ultrasonic(
    input clk,
    input rst,
    input echo_i,
    output wire trigger_o,
    output wire object_detected_o
);

// Señales internas
wire ready_i;
wire [31:0] echo_counter;
reg object_detected_reg;

// === CONFIGURA AQUÍ LA DISTANCIA DE DETECCIÓN ===
// Por ejemplo: 10 cm
// echo_counter = (2 * distancia * freq_clk) / v_sonido
// = (2 * 10 * 50_000_000) / 34300 ≈ 29_155 ciclos
parameter DIST_THRESHOLD = 29155;

// Instancia del generador de pulsos
generador_pulsos #(
    .CLOCK_FREQ(50_000_000),
    .PULSE_INTERVAL_MS(60)
) pulse_gen (
    .clk(clk),
    .rst(rst),
    .pulse_out(ready_i)
);

// Instancia del controlador ultrasónico
controlador_ultrasonido ultrasonic0 (
    .clk(clk),
    .rst(rst),
    .ready_i(ready_i),
    .echo_i(echo_i),
    .trigger_o(trigger_o),
    .echo_counter(echo_counter)
);

// Lógica de detección de objeto
always @(posedge clk) begin
    if (rst)
        object_detected_reg <= 1'b0;
    else
        object_detected_reg <= (echo_counter > 0 && echo_counter < DIST_THRESHOLD);
end

assign object_detected_o = object_detected_reg;

endmodule


