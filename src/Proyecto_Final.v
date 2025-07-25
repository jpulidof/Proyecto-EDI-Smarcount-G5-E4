module Proyecto_Final(
    input clk,
    input rst_n,
    input echo,                 // Entrada del HC-SR04
    output trig,                // Salida del HC-SR04
    output [7:0] LCD_DATA,
    output LCD_RS,
    output LCD_RW,
    output LCD_E
);

    wire rst = ~rst_n;
    wire [15:0] distancia_cm;
    wire [6:0] contador_display;
    reg [6:0] contador;
    reg objeto_detectado;

    // ---------- ULTRASONIDO ----------
    ultrasonic_controller #(
        .CLOCK_FREQ(50_000_000),
        .SOUND_SPEED(34300),
        .TIME_TRIG(500)               // 10 us a 50 MHz
    ) u_ultrasonido (
        .clk(clk),
        .rst(rst),
        .echo(echo),
        .trig(trig),
        .distancia_cm(distancia_cm)
    );

    // ---------- LÓGICA DE CONTADOR ----------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            contador <= 0;
            objeto_detectado <= 0;
        end else begin
            if (distancia_cm < 10 && !objeto_detectado) begin
                contador <= contador + 1;
                objeto_detectado <= 1;
            end
            if (distancia_cm >= 10) begin
                objeto_detectado <= 0;
            end
        end
    end

    assign contador_display = contador;

    // ---------- LCD ----------
    LCD1602_controller #(
        .NUM_COMMANDS(4),
        .NUM_DATA_ALL(32),
        .NUM_DATA_PERLINE(16),
        .DATA_BITS(8),
        .COUNT_MAX(800000)
    ) u_lcd (
        .clk(clk),
        .in(contador_display),
        .reset(rst),
        .ready_i(1'b1),             // Siempre listo para escribir
        .rs(LCD_RS),
        .rw(LCD_RW),
        .enable(LCD_E),
        .data(LCD_DATA)
    );

endmodule
