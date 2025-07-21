// top_color_sorter.v
// Módulo top que integra el sensor TCS34725 con salida en display 7 segmentos

module top_color_sorter (
    input wire clk,
    input wire rst,
    // I2C
    inout wire sda,
    output wire scl,
    // Display
    output wire [6:0] seg
);

    // Señales internas
    wire [7:0] i2c_data_out;
    wire [7:0] i2c_reg_addr;
    wire i2c_start;
    wire i2c_ready;
    wire [15:0] red, green, blue;
    wire [1:0] color_code;

    // Instancia del I2C Master
    i2c_master i2c_inst (
        .clk(clk),
        .rst(rst),
        .start(i2c_start),
        .reg_addr(i2c_reg_addr),
        .data_out(i2c_data_out),
        .ready(i2c_ready),
        .sda(sda),
        .scl(scl)
    );

    // Instancia del controlador TCS34725
    tcs34725_controller controller (
        .clk(clk),
        .rst(rst),
        .i2c_ready(i2c_ready),
        .i2c_data(i2c_data_out),
        .i2c_start(i2c_start),
        .i2c_reg_addr(i2c_reg_addr),
        .r(red),
        .g(green),
        .b(blue)
    );

    // Instancia del procesador de color
    color_processor processor (
        .red(red),
        .green(green),
        .blue(blue),
        .color_code(color_code),
        .ascii_color() // No usamos la salida ASCII aquí
    );

    // Instancia del driver de salida (solo display)
    output_driver display_driver (
        .color_code(color_code),
        .seg(seg)
    );

endmodule
