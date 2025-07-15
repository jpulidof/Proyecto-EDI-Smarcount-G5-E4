module sum1b_comp (

    input  A, 
    input  B,
    input  Ci,
    output Cout,
    output S
  );
  
    reg [1:0] st;

  
    always @ ( * ) begin
      st  =   A+B+Ci;
    end

    assign S = st[0];
    assign Cout = st[1];
    
  endmodule
