module sum1b_estruc (
    input A, 
    input B, 
    input Ci,
    output Cout,
    output S
  );
  
    wire a_ab;
    wire x_ab;
    wire cout_t;
  
    and(a_ab,A,B); 
    xor(S,x_ab,Ci);
    xor(x_ab,A,B);
    and(cout_t,x_ab,Ci);
    or (Cout,cout_t,a_ab);
  
  endmodule