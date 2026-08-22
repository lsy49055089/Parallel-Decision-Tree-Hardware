`timescale 1ns/1ps

module tb_refined_4state_equivalence;

    reg clock;
    reg reset;
    reg start;

    wire done6, batch_done6, error6;
    wire done4, batch_done4, error4;
    wire [5:0] cur6, cur4;
    wire [1:0] class6, class4;
    wire [2:0] state6, state4;
    wire [4:0] node6, node4;

    reg [1:0] result6 [0:36];
    reg [1:0] result4 [0:36];
    integer seen6;
    integer seen4;
    integer failures;
    integer i;
    integer elapsed_cycles;
    integer finish_cycle6;
    integer finish_cycle4;
    reg finished6;
    reg finished4;

    top_prefetch_un3 DUT_6STATE (
        .clock(clock), .reset(reset), .multi_mode(1'b1), .start(start),
        .vector_id(6'd0), .first_vec_id(6'd0), .last_vec_id(6'd36),
        .done(done6), .batch_done(batch_done6), .cur_vec_id(cur6),
        .result_class(class6), .error(error6), .state_dbg(state6),
        .current_node_dbg(node6), .UN1_direction_dbg(),
        .logic_class_dbg(), .logic_next_node_dbg()
    );

    top_prefetch_un3_4state DUT_4STATE (
        .clock(clock), .reset(reset), .multi_mode(1'b1), .start(start),
        .vector_id(6'd0), .first_vec_id(6'd0), .last_vec_id(6'd36),
        .done(done4), .batch_done(batch_done4), .cur_vec_id(cur4),
        .result_class(class4), .error(error4), .state_dbg(state4),
        .current_node_dbg(node4), .active_dbg()
    );

    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    always @(posedge clock) begin
        if (reset) begin
            elapsed_cycles <= 0;
        end else begin
            elapsed_cycles <= elapsed_cycles + 1;

            if (done6) begin
                result6[cur6] = class6;
                seen6 = seen6 + 1;
                if ((state6 !== 3'b100) || error6) begin
                    failures = failures + 1;
                    $display("FAIL 6-state control: vec=%0d state=%b error=%b", cur6, state6, error6);
                end
            end

            if (done4) begin
                result4[cur4] = class4;
                seen4 = seen4 + 1;
                if ((state4 !== 3'b100) || error4) begin
                    failures = failures + 1;
                    $display("FAIL 4-state control: vec=%0d state=%b error=%b", cur4, state4, error4);
                end
            end

            if (batch_done6 && !finished6) begin
                finished6 = 1'b1;
                finish_cycle6 = elapsed_cycles;
            end

            if (batch_done4 && !finished4) begin
                finished4 = 1'b1;
                finish_cycle4 = elapsed_cycles;
            end
        end
    end

    initial begin
        $dumpfile("build/tb_refined_4state_equivalence.vcd");
        $dumpvars(0, tb_refined_4state_equivalence);

        reset         = 1'b1;
        start         = 1'b0;
        seen6         = 0;
        seen4         = 0;
        failures      = 0;
        elapsed_cycles = 0;
        finish_cycle6 = -1;
        finish_cycle4 = -1;
        finished6     = 1'b0;
        finished4     = 1'b0;

        repeat (3) @(posedge clock);
        @(negedge clock);
        reset = 1'b0;
        @(negedge clock);
        start = 1'b1;
        @(negedge clock);
        start = 1'b0;

        wait (finished6 && finished4);
        #1;

        if ((seen6 != 37) || (seen4 != 37)) begin
            failures = failures + 1;
            $display("FAIL result counts: six=%0d four=%0d", seen6, seen4);
        end

        for (i = 0; i < 37; i = i + 1) begin
            if (result6[i] !== result4[i]) begin
                failures = failures + 1;
                $display("FAIL mismatch: vec=%0d six=%0d four=%0d", i, result6[i], result4[i]);
            end
        end

        if (finish_cycle4 >= finish_cycle6) begin
            failures = failures + 1;
            $display("FAIL cycle reduction: six=%0d four=%0d", finish_cycle6, finish_cycle4);
        end

        if (failures == 0) begin
            $display("PASS tb_refined_4state_equivalence: outputs identical for 37 vectors");
            $display("CYCLES six_state=%0d refined_4state=%0d", finish_cycle6, finish_cycle4);
        end else begin
            $fatal(1, "FAIL tb_refined_4state_equivalence: failures=%0d", failures);
        end

        $finish;
    end

    initial begin
        repeat (2000) @(posedge clock);
        $fatal(1, "TIMEOUT tb_refined_4state_equivalence");
    end

endmodule
