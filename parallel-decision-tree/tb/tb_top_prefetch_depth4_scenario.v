`timescale 1ns/1ps

module tb_top_prefetch_depth4_scenario;

    reg clock;
    reg reset;
    reg multi_mode;
    reg start;
    reg [5:0] vector_id;
    reg [5:0] first_vec_id;
    reg [5:0] last_vec_id;

    wire done;
    wire batch_done;
    wire [5:0] cur_vec_id;
    wire [1:0] result_class;
    wire error;
    wire [2:0] state_dbg;
    wire [4:0] current_node_dbg;
    wire UN1_direction_dbg;
    wire [1:0] logic_class_dbg;
    wire [4:0] logic_next_node_dbg;

    integer observed;
    integer failures;

    top_prefetch_un3 DUT (
        .clock(clock),
        .reset(reset),
        .multi_mode(multi_mode),
        .start(start),
        .vector_id(vector_id),
        .first_vec_id(first_vec_id),
        .last_vec_id(last_vec_id),
        .done(done),
        .batch_done(batch_done),
        .cur_vec_id(cur_vec_id),
        .result_class(result_class),
        .error(error),
        .state_dbg(state_dbg),
        .current_node_dbg(current_node_dbg),
        .UN1_direction_dbg(UN1_direction_dbg),
        .logic_class_dbg(logic_class_dbg),
        .logic_next_node_dbg(logic_next_node_dbg)
    );

    function [1:0] expected_class;
        input [5:0] id;
        begin
            case (id % 9)
                0: expected_class = 2'd0; // leaf 4
                1: expected_class = 2'd1; // leaf 8
                2: expected_class = 2'd1; // leaf 13
                3: expected_class = 2'd2; // leaf 14
                4: expected_class = 2'd2; // leaf 9
                5: expected_class = 2'd1; // leaf 10
                6: expected_class = 2'd0; // leaf 11
                7: expected_class = 2'd2; // leaf 15
                8: expected_class = 2'd0; // leaf 16
                default: expected_class = 2'bxx;
            endcase
        end
    endfunction

    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    always @(posedge clock) begin
        if (!reset && done) begin
            observed = observed + 1;

            if (state_dbg !== 3'b100) begin
                failures = failures + 1;
                $display("FAIL state: vec=%0d done asserted in state=%b", cur_vec_id, state_dbg);
            end

            if (error) begin
                failures = failures + 1;
                $display("FAIL traversal: vec=%0d node=%0d", cur_vec_id, current_node_dbg);
            end

            if (result_class !== expected_class(cur_vec_id)) begin
                failures = failures + 1;
                $display("FAIL class: vec=%0d expected=%0d actual=%0d",
                         cur_vec_id, expected_class(cur_vec_id), result_class);
            end
        end
    end

    initial begin
        $dumpfile("build/tb_top_prefetch_depth4_scenario.vcd");
        $dumpvars(0, tb_top_prefetch_depth4_scenario);

        reset        = 1'b1;
        multi_mode   = 1'b1;
        start        = 1'b0;
        vector_id    = 6'd0;
        first_vec_id = 6'd0;
        last_vec_id  = 6'd36;
        observed     = 0;
        failures     = 0;

        repeat (3) @(posedge clock);
        @(negedge clock);
        reset = 1'b0;
        @(negedge clock);
        start = 1'b1;
        @(negedge clock);
        start = 1'b0;

        wait (batch_done === 1'b1);
        #1;

        if (observed != 37) begin
            failures = failures + 1;
            $display("FAIL count: expected=37 actual=%0d", observed);
        end

        if (failures == 0)
            $display("PASS tb_top_prefetch_depth4_scenario: 37/37 vectors correct");
        else
            $fatal(1, "FAIL tb_top_prefetch_depth4_scenario: failures=%0d", failures);

        $finish;
    end

    initial begin
        repeat (2000) @(posedge clock);
        $fatal(1, "TIMEOUT tb_top_prefetch_depth4_scenario");
    end

endmodule
