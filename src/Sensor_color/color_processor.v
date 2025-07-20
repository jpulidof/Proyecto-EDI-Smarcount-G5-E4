// color_processor.v
// Procesamiento básico de color RGB

module color_processor (
    input [15:0] red, green, blue,
    output reg [1:0] color_code
);
    always @(*) begin
        if (red>green && red>blue) color_code=2'b00;
        else if (green>red && green>blue) color_code=2'b01;
        else if (blue>red && blue>green) color_code=2'b10;
        else color_code=2'b11;
    end
endmodule
