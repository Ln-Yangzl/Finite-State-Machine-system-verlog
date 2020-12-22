module sim (
    
);

    logic clk, resetn;
    always #1 clk = ~clk;

    initial begin
        clk = '0;
        resetn = '0;
        #6 resetn = '1;
    end

    logic en;
    logic [3:0] second_h, second_l, minute_h, minute_l, houre_h, houre_l;

    logic sensor;
    logic [1:0] red, yellow, green;

    lab6 lab6_mod(.clk, .resetn, .en, .raw_segs({houre_h, houre_l, minute_h, minute_l, second_h, second_l}), .sensor, .red, .yellow, .green);
    
    initial begin
        en = '1;
        sensor = '1;
        #132 sensor = '0;
        #28 sensor = '1;
        #100 en = '0;
        #120 en = '1;
    end

endmodule
