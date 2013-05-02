module LogGraph (
    I,
    O
);
    input  [7:0] I;
    output [7:0] O;

    genvar i;
    generate 
      for(i=0; i<8; i=i+1) begin:lights
        assign O[i] = |{I[7:7-i]};
      end
    endgenerate

endmodule
