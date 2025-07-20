// output_driver.v
// Módulo de salida SOLO con display 7 segmentos (Cyclone IV)

module output_driver (
    input [1:0] color_code,
    output reg [6:0] seg,
    output [3:0] an
);
    assign an = 4'b1110;
    always @(*) begin
        case (color_code)
            2'b00: seg=7'b1000110;
            2'b01: seg=7'b0001000;
            2'b10: seg=7'b0010010;
            default: seg=7'b1111110;
        endcase
    end
endmodule
