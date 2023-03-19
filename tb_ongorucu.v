`timescale 1ns / 1ps

// METIN EREN DURUCAN - 201101038 - HW2

// ---[TCL CONSOLE OUTPUT]---
// Dogru tahmin:         453
// Yanlis tahmin:        547
// --------------------------

module tb_ongorucu();

reg [31:0] ps;
reg [31:0] buyruk;

reg clk;
reg rst;

reg guncelle_gecerli;
reg guncelle_atladi;
reg [31:0] guncelle_ps;

wire [31:0]atlanan_ps;
wire atlama_gecerli;

ongorucu uut(
    .clk_i(clk),
    .rst_i(rst),
    .ps_i(ps),
    .buyruk_i(buyruk),
    .guncelle_gecerli_i(guncelle_gecerli),
    .guncelle_atladi_i(guncelle_atladi),
    .guncelle_ps_i(guncelle_ps),
    .atlanan_ps_o(atlanan_ps),
    .atlanan_gecerli_o(atlama_gecerli)
);
always begin
    clk = ~clk;
    #5;
end
reg [31:0] yanlis_tahmin = 0;
reg [31:0] dogru_tahmin = 0;
reg cevrim_sayisi = 0;

always @(posedge clk) begin
    if(cevrim_sayisi) begin
        guncelle_ps <= ps;
        ps <= ps + 1;
    end
    if(atlama_gecerli && cevrim_sayisi) begin
        dogru_tahmin <= dogru_tahmin + 1;
    end
    else begin
        yanlis_tahmin = yanlis_tahmin + 1;
    end
    cevrim_sayisi <= ~cevrim_sayisi;
end

initial begin
    clk = 1'b0;
    ps = 32'd0;
    buyruk = 32'b0_000000_00000_00000_000_0001_0_1100011;
    guncelle_gecerli = 1;
    guncelle_atladi = 1;
    
    #10000;
    $display("Dogru tahmin: %d",dogru_tahmin);      // 920
    $display("Yanlis tahmin: %d",yanlis_tahmin);    //  80
    $finish;
end
endmodule