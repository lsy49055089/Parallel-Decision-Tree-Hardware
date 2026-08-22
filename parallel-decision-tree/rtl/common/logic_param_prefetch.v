`timescale 1ns/1ps

// Selects the already-prefetched UN2/UN3 result using UN1's direction.
// direction=0 selects UN2 (left); direction=1 selects UN3 (right).
module logic_param_prefetch #(
    parameter CLASS_ENC  = 2,
    parameter ND_NUM_ENC = 5
)(
    input  wire                       UN1_direction,
    input  wire [CLASS_ENC-1:0]       UN2_class,
    input  wire [CLASS_ENC-1:0]       UN3_class,
    input  wire [ND_NUM_ENC-1:0]      UN2_next_node,
    input  wire [ND_NUM_ENC-1:0]      UN3_next_node,
    input  wire [ND_NUM_ENC-1:0]      UN2_adL,
    input  wire [ND_NUM_ENC-1:0]      UN2_adR,
    input  wire [ND_NUM_ENC-1:0]      UN3_adL,
    input  wire [ND_NUM_ENC-1:0]      UN3_adR,
    output reg  [CLASS_ENC-1:0]       class_out,
    output reg  [ND_NUM_ENC-1:0]      next_node
);

    localparam [CLASS_ENC-1:0]  INVALID_CLASS = {CLASS_ENC{1'b1}};
    localparam [ND_NUM_ENC-1:0] INVALID_NODE  = {ND_NUM_ENC{1'b1}};

    // Final recovered revision: a valid C-Memory result resolves a leaf.
    // The AD ports remain in the interface for compatibility/debugging.
    wire is_resolved_UN2 = (UN2_class != INVALID_CLASS);
    wire is_resolved_UN3 = (UN3_class != INVALID_CLASS);

    always @(*) begin
        class_out = INVALID_CLASS;
        next_node = INVALID_NODE;

        case ({is_resolved_UN2, is_resolved_UN3})
            2'b00: begin
                next_node = UN1_direction ? UN3_next_node : UN2_next_node;
            end

            2'b01: begin
                if (UN1_direction)
                    class_out = UN3_class;
                else
                    next_node = UN2_next_node;
            end

            2'b10: begin
                if (UN1_direction)
                    next_node = UN3_next_node;
                else
                    class_out = UN2_class;
            end

            2'b11: begin
                class_out = UN1_direction ? UN3_class : UN2_class;
            end

            default: begin
                class_out = INVALID_CLASS;
                next_node = INVALID_NODE;
            end
        endcase
    end

endmodule
