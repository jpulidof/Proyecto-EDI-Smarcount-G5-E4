module contador(
    input wire clk,
    input wire rst,
    input wire inc,
    output reg [7:0] count
);

	reg micro;
	
	reg [14:0] counter;
	
	reg inc_prev;
	
	initial begin
		inc_prev = 0;
	end
		
		
	always@(posedge clk) begin
        if (counter == 30000 -1) begin
            micro = ~micro;
            counter<=0;
        end else begin 
            counter = counter + 1;
        end
    end
	 
    always @(posedge micro) begin
        if (rst) begin
            count <= 8'd0;
				inc_prev <= 0;
        end else if (~inc && count < 8'd255 &&  !inc_prev) begin
            count <= count + 1;
        end else begin
				inc_prev <= ~inc;
		  end
    end

endmodule
