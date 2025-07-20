// top_color_sorter.v
// Módulo top que integra el sensor TCS34725 con salida en display 7 segmentos

module top_color_sorter (
    input clk, rst,
    inout sda,
    output scl,
    output [6:0] seg,
    output [3:0] an
);
    wire [15:0] red, green, blue, i2c_data;
    wire [6:0] dev_addr;
    wire [7:0] reg_addr;
    wire start_i2c, done_i2c, busy_i2c, ready;
    wire [1:0] color_code;

    i2c_master_read2bytes i2c_inst (
        .clk(clk), .rst(rst),
        .start(start_i2c),
        .dev_addr(dev_addr),
        .reg_addr(reg_addr),
        .data_out(i2c_data),
        .busy(busy_i2c),
        .done(done_i2c),
        .sda(sda),
        .scl(scl)
    );

    tcs34725_controller controller (
        .clk(clk), .rst(rst),
        .start_i2c(start_i2c),
        .done_i2c(done_i2c),
        .busy_i2c(busy_i2c),
        .dev_addr(dev_addr),
        .reg_addr(reg_addr),
        .data_in(i2c_data),
        .red(red), .green(green), .blue(blue),
        .ready(ready)
    );

    color_processor cp (
        .red(red), .green(green), .blue(blue),
        .color_code(color_code)
    );

    output_driver od (
        .color_code(color_code),
        .seg(seg), .an(an)
    );
endmodule
