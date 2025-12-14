`timescale 1ns/1ps

module connect4_tb;

reg clk;
reg rst_n;

// connect4 介面
reg        op_valid;
reg        op_player_id;
reg  [2:0] op_col_id;
wire       op_ready;

wire       re_valid;
wire       re_err;
wire       re_is_finished;
wire       re_winner;
wire       re_tie;
reg        re_ready;

// 實例化 connect4 模組
connect4 uut (
    .clk(clk),
    .rst_n(rst_n),
    .op_ready(op_ready),
    .op_valid(op_valid),
    .op_player_id(op_player_id),
    .op_col_id(op_col_id),
    .re_ready(re_ready),
    .re_valid(re_valid),
    .re_err(re_err),
    .re_is_finished(re_is_finished),
    .re_winner(re_winner),
    .re_tie(re_tie)
);

// 時脈產生
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// 落子任務
task drop_piece;
    input player;
    input [2:0] col;
    begin
        @(posedge clk);
        wait(op_ready);
        @(posedge clk);
        op_valid = 1;
        op_player_id = player;
        op_col_id = col;
        @(posedge clk);
        op_valid = 0;
        
        // 等待回應
        wait(re_valid);
        @(posedge clk);
        re_ready = 1;
        @(posedge clk);
        re_ready = 0;
        
        $display("Player %0d drops at column %0d | err=%b finished=%b winner=%b tie=%b",
                 player, col, re_err, re_is_finished, re_winner, re_tie);
    end
endtask

// 主測試流程
initial begin
    $dumpfile("connect4_tb.vcd");
    $dumpvars(0, connect4_tb);
    
    // 初始化
    rst_n = 0;
    op_valid = 0;
    op_player_id = 0;
    op_col_id = 0;
    re_ready = 0;
    
    // 釋放重置
    #20;
    rst_n = 1;
    #10;
    
    $display("=== Connect4 Test Start ===");
    $display("");
    
    // 測試場景：玩家0垂直連四獲勝
    $display("--- Test: Player 0 Vertical Win ---");
    drop_piece(0, 3'd0);  // Player 0, col 0
    drop_piece(1, 3'd1);  // Player 1, col 1
    drop_piece(0, 3'd0);  // Player 0, col 0
    drop_piece(1, 3'd1);  // Player 1, col 1
    drop_piece(0, 3'd0);  // Player 0, col 0
    drop_piece(1, 3'd1);  // Player 1, col 1
    drop_piece(0, 3'd0);  // Player 0, col 0 -> WIN!
    
    #50;
    
    // 重置後測試水平獲勝
    $display("");
    $display("--- Test: Player 1 Horizontal Win ---");
    drop_piece(0, 3'd0);  // Player 0
    drop_piece(1, 3'd1);  // Player 1
    drop_piece(0, 3'd0);  // Player 0
    drop_piece(1, 3'd2);  // Player 1
    drop_piece(0, 3'd0);  // Player 0
    drop_piece(1, 3'd3);  // Player 1
    drop_piece(0, 3'd5);  // Player 0
    drop_piece(1, 3'd4);  // Player 1 -> WIN!
    
    #50;
    
    $display("");
    $display("=== Connect4 Test Complete ===");
    $finish;
end

// 超時保護
initial begin
    #100000;
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule
