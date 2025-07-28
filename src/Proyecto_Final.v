module Proyecto_Final #(
    parameter CLOCK_FREQ = 50_000_000,       // Frecuencia del sistema (50 MHz)
    parameter PULSE_INTERVAL_MS = 60,        // Intervalo entre pulsos
    parameter DIST_THRESHOLD_CM = 10
)(
    input wire clk,
    input wire rst_n,
    //LCD
    output wire [7:0] LCD_DATA,
    output wire LCD_RS,
    output wire LCD_RW,
    output wire LCD_E,
    //infrarrojo
	input infrarrojo,
    //motor
    input wire [7:0] pwm_duty,
    input wire boton_pausa,
    output wire AIN1,
    output wire AIN2,
    output wire PWMA,
    output wire STBY
);

    wire rst = ~rst_n;
    wire [7:0] count;


    antirrebote antirrebote_inst(
        .clk(clk),
        .btn(infrarrojo),
        .clean(infrarrojo_limpio)
    );

    wire infrarrojo_limpio;


    contador contador_inst (
        .cuenta(infrarrojo_limpio),
        .rst_n(rst_n),
        .salida(count)
    );

    LCD1602_controller lcd (
        .clk(clk),
        .reset(rst),
        .in(count),
        .ready_i(1'b1),
        .rs(LCD_RS),
        .rw(LCD_RW),
        .enable(LCD_E),
        .data(LCD_DATA)
    );

    controlador_motor motor_ctrl (
        .clk(clk),
        .rst(rst_n),
        .sel(2'b00),
        .pwm_duty(pwm_duty),
        .boton_pausa(boton_pausa),
        .AIN1(AIN1),
        .AIN2(AIN2),
        .PWMA(PWMA),
        .STBY(STBY)
    );
	 
endmodule
