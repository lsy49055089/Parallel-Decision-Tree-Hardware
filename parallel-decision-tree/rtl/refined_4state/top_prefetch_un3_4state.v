`timescale 1ns/1ps

// Refined four-state implementation matching the paper's encoded state flow:
//   001 LOAD -> 010 COMPARE -> 011 DECISION -> 100 DONE
// An `active` bit distinguishes an idle LOAD state from an accepted request;
// it is not an additional FSM state.
module top_prefetch_un3_4state #(
    parameter ATTR_NUM         = 4,
    parameter ATTR_NUM_ENC     = 2,
    parameter WORD_LEN         = 8,
    parameter ND_NUM_ENC       = 5,
    parameter CLASS_ENC        = 2,
    parameter MAX_ND           = 32,
    parameter ADDER_TREE_DEPTH = 2,
    parameter STATE_ENC        = 3,
    parameter IN_NUM_ENC       = 6,
    parameter IN_NUM           = 37,
    parameter FRAC_BITS        = 4
)(
    input  wire                          clock,
    input  wire                          reset,
    input  wire                          multi_mode,
    input  wire                          start,
    input  wire [IN_NUM_ENC-1:0]         vector_id,
    input  wire [IN_NUM_ENC-1:0]         first_vec_id,
    input  wire [IN_NUM_ENC-1:0]         last_vec_id,
    output reg                           done,
    output reg                           batch_done,
    output reg  [IN_NUM_ENC-1:0]         cur_vec_id,
    output reg  [CLASS_ENC-1:0]          result_class,
    output reg                           error,
    output wire [STATE_ENC-1:0]          state_dbg,
    output wire [ND_NUM_ENC-1:0]         current_node_dbg,
    output wire                          active_dbg
);

    localparam [CLASS_ENC-1:0]  INVALID_CLASS = {CLASS_ENC{1'b1}};
    localparam [ND_NUM_ENC-1:0] INVALID_NODE  = {ND_NUM_ENC{1'b1}};

    localparam [STATE_ENC-1:0] S_LOAD     = 3'b001;
    localparam [STATE_ENC-1:0] S_COMPARE  = 3'b010;
    localparam [STATE_ENC-1:0] S_DECISION = 3'b011;
    localparam [STATE_ENC-1:0] S_DONE     = 3'b100;

    reg [STATE_ENC-1:0] state;
    reg active;
    reg [ND_NUM_ENC-1:0] current_node;
    reg [IN_NUM_ENC-1:0] last_vec_q;
    reg batch_mode_q;

    wire [(ATTR_NUM*WORD_LEN)-1:0] attr_bus;
    wire [ND_NUM_ENC-1:0] ad0_left, ad0_right;
    wire [ND_NUM_ENC-1:0] ad1_left, ad1_right;
    wire [ND_NUM_ENC-1:0] ad2_left, ad2_right;

    wire node1_direction, node2_direction, node3_direction;
    wire [CLASS_ENC-1:0] node1_class, node2_class, node3_class;
    wire [ND_NUM_ENC-1:0] node1_next, node2_next, node3_next;
    wire signed [(2*WORD_LEN)+ATTR_NUM_ENC:0] node1_score;
    wire signed [(2*WORD_LEN)+ATTR_NUM_ENC:0] node2_score;
    wire signed [(2*WORD_LEN)+ATTR_NUM_ENC:0] node3_score;

    reg node1_direction_q;
    reg [CLASS_ENC-1:0] node2_class_q, node3_class_q;
    reg [ND_NUM_ENC-1:0] node2_next_q, node3_next_q;

    wire [CLASS_ENC-1:0] logic_class;
    wire [ND_NUM_ENC-1:0] logic_next_node;

    assign state_dbg        = state;
    assign current_node_dbg = current_node;
    assign active_dbg       = active;

    I_Memory_ext #(
        .ATTR_NUM(ATTR_NUM), .WORD_LEN(WORD_LEN),
        .IN_NUM_ENC(IN_NUM_ENC), .IN_NUM(IN_NUM)
    ) U_I_MEMORY (
        .vec_id(cur_vec_id), .attr_bus(attr_bus)
    );

    ad_ro #(.ND_NUM_ENC(ND_NUM_ENC)) U_AD_MEMORY (
        .node0(current_node), .node1(ad0_left), .node2(ad0_right),
        .node0_left(ad0_left), .node0_right(ad0_right),
        .node1_left(ad1_left), .node1_right(ad1_right),
        .node2_left(ad2_left), .node2_right(ad2_right)
    );

    decision_tree #(
        .ATTR_NUM(ATTR_NUM), .ATTR_NUM_ENC(ATTR_NUM_ENC),
        .WORD_LEN(WORD_LEN), .ND_NUM_ENC(ND_NUM_ENC),
        .CLASS_ENC(CLASS_ENC), .MAX_ND(MAX_ND),
        .ADDER_TREE_DEPTH(ADDER_TREE_DEPTH), .FRAC_BITS(FRAC_BITS)
    ) UN1 (
        .attr_bus(attr_bus), .node_num(current_node),
        .ad_left(ad0_left), .ad_right(ad0_right),
        .direction(node1_direction), .class_out(node1_class),
        .next_node(node1_next), .score_dbg(node1_score)
    );

    decision_tree #(
        .ATTR_NUM(ATTR_NUM), .ATTR_NUM_ENC(ATTR_NUM_ENC),
        .WORD_LEN(WORD_LEN), .ND_NUM_ENC(ND_NUM_ENC),
        .CLASS_ENC(CLASS_ENC), .MAX_ND(MAX_ND),
        .ADDER_TREE_DEPTH(ADDER_TREE_DEPTH), .FRAC_BITS(FRAC_BITS)
    ) UN2 (
        .attr_bus(attr_bus), .node_num(ad0_left),
        .ad_left(ad1_left), .ad_right(ad1_right),
        .direction(node2_direction), .class_out(node2_class),
        .next_node(node2_next), .score_dbg(node2_score)
    );

    decision_tree #(
        .ATTR_NUM(ATTR_NUM), .ATTR_NUM_ENC(ATTR_NUM_ENC),
        .WORD_LEN(WORD_LEN), .ND_NUM_ENC(ND_NUM_ENC),
        .CLASS_ENC(CLASS_ENC), .MAX_ND(MAX_ND),
        .ADDER_TREE_DEPTH(ADDER_TREE_DEPTH), .FRAC_BITS(FRAC_BITS)
    ) UN3 (
        .attr_bus(attr_bus), .node_num(ad0_right),
        .ad_left(ad2_left), .ad_right(ad2_right),
        .direction(node3_direction), .class_out(node3_class),
        .next_node(node3_next), .score_dbg(node3_score)
    );

    logic_param_prefetch #(
        .CLASS_ENC(CLASS_ENC), .ND_NUM_ENC(ND_NUM_ENC)
    ) U_LOGIC (
        .UN1_direction(node1_direction_q),
        .UN2_class(node2_class_q), .UN3_class(node3_class_q),
        .UN2_next_node(node2_next_q), .UN3_next_node(node3_next_q),
        .UN2_adL(ad1_left), .UN2_adR(ad1_right),
        .UN3_adL(ad2_left), .UN3_adR(ad2_right),
        .class_out(logic_class), .next_node(logic_next_node)
    );

    always @(posedge clock) begin
        if (reset) begin
            state             <= S_LOAD;
            active            <= 1'b0;
            current_node      <= {ND_NUM_ENC{1'b0}};
            last_vec_q        <= {IN_NUM_ENC{1'b0}};
            batch_mode_q      <= 1'b0;
            done              <= 1'b0;
            batch_done        <= 1'b0;
            cur_vec_id        <= {IN_NUM_ENC{1'b0}};
            result_class      <= INVALID_CLASS;
            error             <= 1'b0;
            node1_direction_q <= 1'b0;
            node2_class_q     <= INVALID_CLASS;
            node3_class_q     <= INVALID_CLASS;
            node2_next_q      <= INVALID_NODE;
            node3_next_q      <= INVALID_NODE;
        end else begin
            done       <= 1'b0;
            batch_done <= 1'b0;

            case (state)
                S_LOAD: begin
                    if (!active) begin
                        if (start) begin
                            active        <= 1'b1;
                            batch_mode_q  <= multi_mode;
                            cur_vec_id    <= multi_mode ? first_vec_id : vector_id;
                            last_vec_q    <= multi_mode ? last_vec_id  : vector_id;
                            current_node  <= {ND_NUM_ENC{1'b0}};
                            result_class  <= INVALID_CLASS;
                            error         <= 1'b0;
                            state         <= S_COMPARE;
                        end
                    end else begin
                        current_node <= {ND_NUM_ENC{1'b0}};
                        result_class <= INVALID_CLASS;
                        error        <= 1'b0;
                        state        <= S_COMPARE;
                    end
                end

                S_COMPARE: begin
                    node1_direction_q <= node1_direction;
                    node2_class_q     <= node2_class;
                    node3_class_q     <= node3_class;
                    node2_next_q      <= node2_next;
                    node3_next_q      <= node3_next;
                    state             <= S_DECISION;
                end

                S_DECISION: begin
                    if (logic_class != INVALID_CLASS) begin
                        result_class <= logic_class;
                        done         <= 1'b1;
                        state        <= S_DONE;
                    end else if (logic_next_node != INVALID_NODE) begin
                        current_node <= logic_next_node;
                        state        <= S_COMPARE;
                    end else begin
                        result_class <= INVALID_CLASS;
                        error        <= 1'b1;
                        done         <= 1'b1;
                        state        <= S_DONE;
                    end
                end

                S_DONE: begin
                    if (batch_mode_q && (cur_vec_id < last_vec_q)) begin
                        cur_vec_id <= cur_vec_id + 1'b1;
                        state      <= S_LOAD;
                    end else begin
                        batch_done <= batch_mode_q;
                        active     <= 1'b0;
                        state      <= S_LOAD;
                    end
                end

                default: begin
                    state  <= S_LOAD;
                    active <= 1'b0;
                    error  <= 1'b1;
                end
            endcase
        end
    end

endmodule
