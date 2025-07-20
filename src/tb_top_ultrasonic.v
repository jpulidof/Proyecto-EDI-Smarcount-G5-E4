`include "src/top_ultrasonic.v"
`timescale 1ns/1ps

module tb_top_ultrasonic;

    // Señales
    reg clk;
    reg rst;
    reg echo_i;
    wire trigger_o;
    wire object_detected_o;

    // Instancia del módulo top
    top_ultrasonic DUT (
        .clk(clk),
        .rst(rst),
        .echo_i(echo_i),
        .trigger_o(trigger_o),
        .object_detected_o(object_detected_o)
    );

    // Reloj de 50 MHz
    always #10 clk = ~clk;  // Periodo = 20ns => 50MHz

    initial begin
        $display("Inicio de simulación");
        $dumpfile("tb_top_ultrasonic.vcd");
        $dumpvars(0, tb_top_ultrasonic);

        // Inicialización
        clk = 0;
        rst = 1;
        echo_i = 0;

        // Esperar unos ciclos con reset activo
        #100;
        rst = 0;

        // Esperar a que se genere un pulso de trigger (60ms)
        #(60_000_000);  // 60 ms = 60,000,000 ns

        // Simular un eco breve (objeto cercano, menor a 10cm)
        #100;
        echo_i = 1;
        #(10_000);  // Pulso de 10 µs (equivale a un objeto a ~1.7 cm)
        echo_i = 0;

        // Esperar a ver si se detecta
        #100_000;

        // Simular un eco largo (objeto lejano, mayor a umbral)
        #(60_000_000);
        echo_i = 1;
        #(40_000);  // Pulso de 40 µs (equivale a un objeto lejano)
        echo_i = 0;

        // Esperar para ver la no detección
        #100_000;

        $finish;
    end

endmodule
