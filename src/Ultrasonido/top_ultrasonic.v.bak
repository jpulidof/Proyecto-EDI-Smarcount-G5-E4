module top_ultrasonic #(
    parameter CLOCK_FREQ = 50_000_000,       // Frecuencia del sistema (50 MHz)
    parameter PULSE_INTERVAL_MS = 60,        // Intervalo entre pulsos
    parameter DIST_THRESHOLD_CM = 10         // Distancia mínima para detección
)(
    input  wire clk,                         // Reloj principal
    input  wire rst_n,                       // Reset activo bajo (DIP switch)
    input  wire echo_i,                      // Entrada desde el sensor (ECHO)
    output wire trigger_o,                   // Salida al sensor (TRIG)
    output wire object_detected_o_fpga       // LED (activo bajo)
);

    // Reset activo alto
    wire rst = ~rst_n;

    // Señal de pulso para habilitar medición
    wire ready_pulse;

    // Señal interna de detección
    wire object_detected_internal;

    // Generador de pulsos cada 60 ms
    generador_pulsos #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .PULSE_INTERVAL_MS(PULSE_INTERVAL_MS)
    ) u_pulsos (
        .clk(clk),
        .rst(rst),
        .pulse_out(ready_pulse)
    );

    // Controlador de sensor ultrasónico
    controlador_ultrasonido #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .DIST_THRESHOLD_CM(DIST_THRESHOLD_CM)
    ) u_controlador_ultrasonido (
        .clk(clk),
        .rst(rst),
        .ready_i(ready_pulse),
        .echo_i(echo_i),
        .trigger_o(trigger_o),
        .object_detected_o(object_detected_internal)
    );

    // Salida al LED (activo bajo)
    assign object_detected_o_fpga = ~object_detected_internal;

endmodule
