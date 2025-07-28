module top_ultrasonic #(
    parameter CLOCK_FREQ = 50_000_000,       // Frecuencia del sistema (50 MHz)
    parameter PULSE_INTERVAL_MS = 60,        // Intervalo entre pulsos
    parameter DIST_THRESHOLD_CM = 10
)(
    input wire clk,
    input wire rst_n,
    input wire echo_i,
    output wire trigger_o,
    output wire [7:0] LCD_DATA,
    output wire LCD_RS,
    output wire LCD_RW,
    output wire LCD_E,
	 input infrarrojo,
    output wire led,
	 output wire prueba,

    // Señales adicionales necesarias para el controlador_motor
    input wire [1:0] sel,
    input wire [7:0] pwm_duty,
    input wire boton_pausa,
    output wire AIN1,
    output wire AIN2,
    output wire PWMA,
    output wire STBY
);

    wire rst = ~rst_n;

    wire [7:0] count;

//    Ultrasonido #(25) sensor_ultrasonido (
//        .clk(clk),
//        .Enable(1'b1),
//        .Echo(echo_i),
//       .Led(led),
//       .Trigger(trigger_o),
//		 .contador_eventos(count)
//    );
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

    // Instancia del controlador de motor
    controlador_motor motor_ctrl (
        .clk(clk),
        .rst(rst_n),
        .sel(sel),
        .pwm_duty(pwm_duty),
        .boton_pausa(boton_pausa),
        .AIN1(AIN1),
        .AIN2(AIN2),
        .PWMA(PWMA),
        .STBY(STBY)
    );

	 assign prueba =infrarrojo_limpio;
endmodule
