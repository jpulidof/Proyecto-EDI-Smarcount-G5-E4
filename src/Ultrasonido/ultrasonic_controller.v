module ultrasonic_controller#(
    parameter CLOCK_FREQ = 50_000_000, // 50 MHz
    parameter SOUND_SPEED = 34300,     // cm/s
    parameter TIME_TRIG = 500          // 10us = 500 ciclos a 50MHz
)(
    input wire clk,
    input wire rst,
    input wire echo,        // Pin de entrada ECHO
    output reg trig,        // Pulso de salida TRIG
    output reg [15:0] distancia_cm
);

    // Estados
    localparam IDLE = 0, TRIG_PULSE = 1, WAIT_ECHO_HIGH = 2, MEASURE_ECHO = 3, DONE = 4;
    reg [2:0] state = IDLE;

    reg [31:0] counter = 0;
    reg [31:0] echo_counter = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            counter <= 0;
            echo_counter <= 0;
            trig <= 0;
            distancia_cm <= 0;
        end else begin
            case (state)
                IDLE: begin
                    trig <= 0;
                    counter <= 0;
                    if (counter >= CLOCK_FREQ / 10) // Disparo cada 100 ms
                        state <= TRIG_PULSE;
                    else
                        counter <= counter + 1;
                end
                TRIG_PULSE: begin
                    trig <= 1;
                    if (counter >= TIME_TRIG) begin
                        trig <= 0;
                        counter <= 0;
                        state <= WAIT_ECHO_HIGH;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                WAIT_ECHO_HIGH: begin
                    if (echo) begin
                        echo_counter <= 0;
                        state <= MEASURE_ECHO;
                    end
                end
                MEASURE_ECHO: begin
                    if (echo) begin
                        echo_counter <= echo_counter + 1;
                    end else begin
                        // Convertir a distancia:
                        // tiempo (en ciclos) * velocidad / (2 * clk freq)
                        distancia_cm <= (echo_counter * SOUND_SPEED) / (2 * CLOCK_FREQ);
                        state <= DONE;
                    end
                end
                DONE: begin
                    // Espera hasta próximo ciclo
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
