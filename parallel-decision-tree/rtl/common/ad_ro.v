`timescale 1ns/1ps

// Shared, read-only child-address memory with three combinational read ports.
// The internal-node set (0,1,2,3,5,6,7,12) is recovered from the final TB
// discussion. All other addresses are terminal leaves.
module ad_ro #(
    parameter ND_NUM_ENC = 5
)(
    input  wire [ND_NUM_ENC-1:0] node0,
    input  wire [ND_NUM_ENC-1:0] node1,
    input  wire [ND_NUM_ENC-1:0] node2,
    output wire [ND_NUM_ENC-1:0] node0_left,
    output wire [ND_NUM_ENC-1:0] node0_right,
    output wire [ND_NUM_ENC-1:0] node1_left,
    output wire [ND_NUM_ENC-1:0] node1_right,
    output wire [ND_NUM_ENC-1:0] node2_left,
    output wire [ND_NUM_ENC-1:0] node2_right
);

    localparam [ND_NUM_ENC-1:0] INVALID_NODE = {ND_NUM_ENC{1'b1}};

    function [ND_NUM_ENC-1:0] left_child;
        input [ND_NUM_ENC-1:0] node;
        begin
            case (node)
                0:  left_child = 1;
                1:  left_child = 3;
                2:  left_child = 5;
                3:  left_child = 7;
                5:  left_child = 9;
                6:  left_child = 11;
                7:  left_child = 13;
                12: left_child = 15;
                default: left_child = INVALID_NODE;
            endcase
        end
    endfunction

    function [ND_NUM_ENC-1:0] right_child;
        input [ND_NUM_ENC-1:0] node;
        begin
            case (node)
                0:  right_child = 2;
                1:  right_child = 4;
                2:  right_child = 6;
                3:  right_child = 8;
                5:  right_child = 10;
                6:  right_child = 12;
                7:  right_child = 14;
                12: right_child = 16;
                default: right_child = INVALID_NODE;
            endcase
        end
    endfunction

    assign node0_left  = left_child(node0);
    assign node0_right = right_child(node0);
    assign node1_left  = left_child(node1);
    assign node1_right = right_child(node1);
    assign node2_left  = left_child(node2);
    assign node2_right = right_child(node2);

endmodule
