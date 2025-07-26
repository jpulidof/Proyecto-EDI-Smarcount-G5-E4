module Ultrasonido #(parameter COUNT_MAX = 25)(
    input clk,     // Señal de reloj
    input Enable,  // Habilitación del módulo
    input Echo,
    output Led,
    output Trigger, // Salida del pulso de trigge
    output reg [7:0] contador_eventos
	 
);

    reg [5:0] counter; // Contador de 15 bits
    reg [14:0] Tiempo;
    wire wait_echo_reg;
    reg flag_evento;
    reg trigger_done;
    reg [1:0] state;
    reg [3:0] counter_10;
    reg led_reg;
    reg Echo_prev;
    reg micro;
    reg Led_prev;

    parameter IDLE = 0;
    parameter TRIGGER = 1;
    parameter WAIT = 2;
    parameter WAITECHO = 3;

    parameter UMBRAL_BAJO = 950;
    parameter UMBRAL_ALTO = 1050;


    initial begin
        counter <= 6'b000000;    
        Tiempo <= 0;  
        state <= IDLE;  
        trigger_done <= 0;
        micro <= 0;
        counter_10 <=0;
	    led_reg <= 0;
        contador_eventos <= 0;
        Led_prev <= 0;
    end

    // Divisor de frecuecia
    always@(posedge clk) begin
        if (counter == COUNT_MAX -1) begin
            micro <= ~micro;
            counter<=0;
        end else begin 
            counter <= counter + 6'b000001;
        end
    end
 
    always@(posedge clk)begin
        case(state)
            IDLE: begin 
                state=(Enable)?TRIGGER:IDLE;
            end
            TRIGGER: begin
                state=(trigger_done)? WAIT:TRIGGER;
            end
            WAIT: begin
                state=(Echo)?WAITECHO:WAIT;
            end
            WAITECHO: begin
                state=(Echo)?WAITECHO:IDLE;
            end
        endcase
    end


    assign Trigger = (state==TRIGGER);
    assign wait_echo_reg = (state==WAITECHO);

    always @(posedge micro) begin
        if (Trigger) begin
            counter_10 <= counter_10 + 1;
            if (counter_10 < 10) begin // Si el contador es menor que 10, se activa el trigger
    			trigger_done <= 0;
            end else begin
                trigger_done <= 1; // Reinicia el contador 
                counter_10 <= 0;
            end
        end else begin
            trigger_done <= 0;
        end
    end 


    always @(posedge micro) begin
        if (wait_echo_reg && Echo)begin 
            Tiempo <= Tiempo + 1;
        end else if(!Echo)begin
            Tiempo <= 0;
        end 
    end

    always @(posedge micro) begin
        if (Tiempo < UMBRAL_BAJO)
            led_reg <= 0;  
        else if (Tiempo > UMBRAL_ALTO)
            led_reg <= 1;  
    end
    

    always @(posedge micro) begin
        Echo_prev <= Echo;

        if (Echo_prev == 1 && Echo == 0) begin  
            if (Tiempo >= UMBRAL_BAJO && Tiempo<UMBRAL_ALTO &&  !flag_evento) begin
                contador_eventos <= contador_eventos + 1;
                flag_evento <= 1;
            end
        end

        if (Echo == 0 && Tiempo == 0) begin
            flag_evento <= 0;
        end
    end
	 

    assign Led = led_reg;
endmodule