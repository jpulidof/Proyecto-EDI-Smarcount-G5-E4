 module LCD1602_controller #(parameter NUM_COMMANDS = 4, 
                                      NUM_DATA_ALL = 32,  
                                      NUM_DATA_PERLINE = 16,
                                      DATA_BITS = 8,
                                      COUNT_MAX = 800000)(
    input clk,
    input [6:0] in,            
    input reset,          
    input ready_i,
    output reg rs,        
    output reg rw,
    output enable,    
    output reg [DATA_BITS-1:0] data
);

// Definir los estados de la FSM
localparam IDLE = 3'b000;
localparam CONFIG_CMD1 = 3'b001;
localparam WR_STATIC_TEXT_1L = 3'b010;
localparam CONFIG_CMD2 = 3'b011;
localparam WR_STATIC_TEXT_2L = 3'b100;
localparam DYNAMIC_TEXT = 3'b101;

reg [2:0] fsm_state;
reg [2:0] next_state;
reg clk_16ms;

// Comandos de configuración
localparam CLEAR_DISPLAY = 8'h01;
localparam SHIFT_CURSOR_RIGHT = 8'h06;
localparam DISPON_CURSOROFF = 8'h0C;
localparam DISPON_CURSORBLINK = 8'h0E;
localparam LINES2_MATRIX5x8_MODE8bit = 8'h38;
localparam START_2LINE = 8'hC0;

// Definir un contador para el divisor de frecuencia
reg [$clog2(COUNT_MAX)-1:0] clk_counter;
// Definir un contador para controlar el envío de comandos
reg [$clog2(NUM_COMMANDS):0] command_counter;
// Definir un contador para controlar el envío de datos
reg [$clog2(NUM_DATA_PERLINE):0] data_counter;

// Banco de registros
reg [DATA_BITS-1:0] static_data_mem [0: NUM_DATA_ALL-1];
reg [DATA_BITS-1:0] config_mem [0:NUM_COMMANDS-1]; 

reg [1:0] flag_case;
reg [1:0] udc;

initial begin
    fsm_state <= IDLE;
    command_counter <= 'b0;
    data_counter <= 'b0;
    rs <= 1'b0;
    rw <= 1'b0;
    data <= 8'b0;
    flag_case <= 8'b00;
    clk_16ms <= 1'b0;
    clk_counter <= 'b0;
	 udc <= 2'b00;
    $readmemh("/home/jose/Documents/Proyecto-EDI-Smarcount-G5-E4/src/LCD/data.txt", static_data_mem);    
	config_mem[0] <= LINES2_MATRIX5x8_MODE8bit;
	config_mem[1] <= SHIFT_CURSOR_RIGHT;
	config_mem[2] <= DISPON_CURSOROFF;
	config_mem[3] <= CLEAR_DISPLAY;
end

always @(posedge clk) begin
    if (clk_counter == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 'b0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end

reg [7:0] in_data;


always @(posedge clk_16ms)begin
    if(reset)begin
        fsm_state <= IDLE;
    end else begin
        fsm_state <= next_state;
    end
end

always @(*) begin
    case(fsm_state)
        IDLE: begin
            next_state <= (ready_i)? CONFIG_CMD1 : IDLE;
        end
        CONFIG_CMD1: begin 
            next_state <= (command_counter == NUM_COMMANDS)? WR_STATIC_TEXT_1L : CONFIG_CMD1;
        end
        WR_STATIC_TEXT_1L:begin
			next_state <= (data_counter == NUM_DATA_PERLINE)? CONFIG_CMD2 : WR_STATIC_TEXT_1L;
        end
        CONFIG_CMD2: begin 
            next_state <= WR_STATIC_TEXT_2L;
        end
		WR_STATIC_TEXT_2L: begin
			next_state <= (data_counter == NUM_DATA_PERLINE)? DYNAMIC_TEXT : WR_STATIC_TEXT_2L;
		end
        default: next_state = DYNAMIC_TEXT;
    endcase
end

always @(posedge clk_16ms) begin
    if (reset) begin
        command_counter <= 'b0;
        data_counter <= 'b0;
		  data <= 'b0;
          flag_case <= 2'b00;
			 udc <= 2'b00;
        $readmemh("/home/jose/Documents/Proyecto-EDI-Smarcount-G5-E4/src/LCD/data.txt", static_data_mem);
    end else begin
        case (next_state)
            IDLE: begin
                command_counter <= 'b0;
                data_counter <= 'b0;
                rs <= 1'b0;
                data  <= 'b0;
                flag_case <= 2'b00;
            end
            CONFIG_CMD1: begin
			    rs <= 1'b0; 	
                command_counter <= command_counter + 1;
				data <= config_mem[command_counter];
            end
            WR_STATIC_TEXT_1L: begin
                data_counter <= data_counter + 1;
                rs <= 1'b1; 
				data <= static_data_mem[data_counter];
            end
            CONFIG_CMD2: begin
                data_counter <= 'b0;
				rs <= 1'b0; 
				data <= START_2LINE;
            end
			WR_STATIC_TEXT_2L: begin
                data_counter <= data_counter + 1;
                rs <= 1'b1; 
				data <= static_data_mem[NUM_DATA_PERLINE + data_counter];
            end
            DYNAMIC_TEXT: begin
                case(flag_case)
                    2'b00:begin
                        rs <= 1'b0;
                        data <= 8'h80 + 8'h07;
                        flag_case <= 2'b01;
								in_data <= in;
                    end
                    2'b01:begin
                        rs <= 1'b1;
								data <= (in_data - in_data%100)/100 + 8'h30;
								flag_case <= 2'b10;
							end
							2'b10: begin
								data <= (in_data%100 - in_data%10)/10 + 8'h30; 
								flag_case <= 2'b11;
							end
							2'b11: begin
								data <= in_data%10 + 8'h30; 
								flag_case <= 2'b00;									
                    end
                endcase
            end
        endcase
    end
end

assign enable = clk_16ms;

endmodule