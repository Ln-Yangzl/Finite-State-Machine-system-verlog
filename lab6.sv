`include "lab6.svh"
module lab6 (
    input logic clk, resetn ,en,
    output logic[5:0][3:0] raw_segs,

    input logic sensor,
    output logic[1:0] red, yellow, green
);

    logic [5:0] second, minute, houre;
    digit_clk dc(.clk, .resetn, .en, .second, .minute , .houre);
    h2d h2d1(.hex(second), .h(raw_segs[1]), .l(raw_segs[0]));
    h2d h2d2(.hex(minute), .h(raw_segs[3]), .l(raw_segs[2]));
    h2d h2d3(.hex(houre), .h(raw_segs[5]), .l(raw_segs[4]));

    traffic_light tl(.clk, .resetn, .sensor, .red, .yellow, .green);
    
endmodule

module mod_cnt #(
    parameter logic [30:0] N = 31'd100_000_000,
    parameter int W = 8 // default value
)(
    input logic clk, resetn,
    input logic en,
    output logic [W-1:0] counter,
    output logic carry // `carry` as `en` of another instance
);
    logic [W-1:0]counter_nxt;
    always_ff @(posedge clk) begin
        if (~resetn) begin
            counter <= '0;
        end else if (en) begin
            counter <= counter_nxt;
        end
    end
    always_comb begin        
        if (counter == N - 1) begin
            counter_nxt = '0;
        end else begin
            counter_nxt = counter + 1;
        end
    end
    assign carry = en && (counter == N - 1);
endmodule

module digit_clk(
    input logic clk, resetn,
    input logic en,
    output logic [5:0]second,
    output logic [5:0]minute,
    output logic [5:0]houre
);
    logic [5:0]s_nxt, m_nxt, h_nxt;
    logic min_en, hor_en;

    logic clk_32hz;
    mod_cnt #(.N(5)) clk_32(.clk, .resetn, .en(1'b1), .carry(clk_32hz));     //this is for sim

    mod_cnt #(.N(60),.W(6)) s_count(.clk, .resetn, .en(clk_32hz), .counter(s_nxt), .carry(min_en));
    mod_cnt #(.N(60),.W(6)) m_count(.clk, .resetn, .en(min_en), .counter(m_nxt), .carry(hor_en));
    mod_cnt #(.N(24),.W(6)) h_count(.clk, .resetn, .en(hor_en), .counter(h_nxt));

    always_ff @(posedge clk) begin
        if (en) begin
            second <= s_nxt;
            minute <= m_nxt;
            houre <= h_nxt;
        end
    end

endmodule

module h2d(
    input logic [5:0]hex,
    output logic [3:0]h, l
);
    logic [4:0]temp;
    always_comb begin
        if(hex < 6'ha) begin
            h = '0;
            l = hex[3:0];
        end else if (hex >= 6'ha && hex < 6'h14) begin
            h = 4'h1;
            temp = hex - 10;
            l = temp[3:0];
        end else if (hex >= 6'h14 && hex < 6'h1e) begin
            h = 4'h2;
            temp = hex - 20;
            l = temp[3:0];
        end else if (hex >= 6'h1e && hex < 6'h28) begin
            h = 4'h3;
            temp = hex - 30;
            l = temp[3:0];
        end else if (hex >= 6'h28 && hex < 6'h32) begin
            h = 4'h4;
            temp = hex - 40;
            l = temp[3:0];
        end else if (hex >= 6'h32) begin
            h = 4'h5;
            temp = hex - 50;
            l = temp[3:0];
        end else begin
            h = '0;
            l = '0;
        end
    end
endmodule

module traffic_light(
    input logic clk, resetn,
    input logic sensor,
    output logic[1:0] red, yellow, green
);
    state_t state, state_nxt;
    always_ff @(posedge clk) begin
        if(~resetn) begin
            state <= state_t'('0);  
        end else if (~sensor) begin
            state <= GREEN_RED;
        end else begin
            state <= state_nxt;
        end
    end

    logic one_s, three_s;
    //this is for sim
    mod_cnt #(.N(5), .W(32)) one(.clk, .resetn(clear), .en(1'b1), .carry(one_s));
    mod_cnt #(.N(15), .W(32)) three(.clk, .resetn(clear), .en(1'b1), .carry(three_s));

    always_comb begin
            unique case (state)
                GREEN_RED: begin
                    red = 2'b01;
                    green = 2'b10;
                    yellow = 2'b00;
                    if(three_s) begin
                        state_nxt = YELLOW_RED;
                    end else begin
                        state_nxt = state;
                    end
                end
                YELLOW_RED: begin
                    red = 2'b01;
                    green = 2'b00;
                    yellow = 2'b10;
                    if(one_s) begin
                        state_nxt = RED_GREEN;
                    end else begin
                        state_nxt = state;
                    end
                end
                RED_GREEN: begin
                    red = 2'b10;
                    green = 2'b01;
                    yellow = 2'b00;
                    if(three_s) begin
                        state_nxt = RED_YELLOW;
                    end else begin
                        state_nxt = state;
                    end
                end
                RED_YELLOW: begin
                    red = 2'b10;
                    green = 2'b00;
                    yellow = 2'b01;
                    if(one_s) begin
                        state_nxt = GREEN_RED;
                    end else begin
                        state_nxt = state;
                    end
                end
                default: begin
                end
            endcase
    end

endmodule