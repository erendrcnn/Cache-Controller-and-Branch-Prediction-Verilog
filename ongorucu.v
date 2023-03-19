`timescale 1ns / 1ps

// METIN EREN DURUCAN - 201101038 - HW2

module ongorucu (
    // Clock and Reset signals
    input               clk_i,
    input               rst_i,

    // Update signals showing the real result after the branching is resolved
    input               guncelle_gecerli_i,     // Update active
    input               guncelle_atladi_i,      // Related branch skipped
    input   [31:0]      guncelle_ps_i,          // Program counter of the corresponding branch

    // Currently watched program counter and instruction
    input   [31:0]      ps_i,
    input   [31:0]      buyruk_i,

    // Signals indicating the result of the jump
    output  [31:0]      atlanan_ps_o,           // Program counter to be skipped
    output              atlanan_gecerli_o       // Jump is valid
);

// CHARTS
reg  [1:0] ciftDTablolar [15:0][7:0];
reg  [1:0] ciftDTablolar_next [15:0][7:0];
// GSHARE
reg  [2:0] gshare [15:0];
reg  [2:0] gshare_next [15:0];

reg [31:0]  atlanan_ps_cmb = 0;
reg         atlanan_gecerli_cmb = 0;

reg  [3:0] gg_yazmaci = 0; 
reg  [3:0] gg_yazmaci_next = 0;

wire [3:0] sayac = gg_yazmaci ^ ps_i[3:0];
wire [3:0] sayac_guncel = gg_yazmaci ^ guncelle_ps_i[3:0];
// Check Branching
wire dallanma = (buyruk_i[6:0] == 7'b1100011) ? 1 : 0;

// STATES
localparam GT = 0;
localparam ZT = 1;
localparam ZA = 2;
localparam GA = 3;

integer row, column;

initial begin
    for (row = 0; row < 16; row = row + 1) begin
        for (column = 0; column < 8; column = column + 1) begin
            ciftDTablolar[row][column] = 2'b00;
            ciftDTablolar_next[row][column] = 2'b00;
        end
		
		gshare[row] = 3'b000;
        gshare_next[row] = 3'b000;
    end 
end

// Duragan atlamaz tahmini
always @* begin
    gg_yazmaci_next = gg_yazmaci;
	atlanan_gecerli_cmb = 0;                // DONT JUMP
    atlanan_ps_cmb = 0;                     // IGNORE

    for (row = 0; row < 16; row = row + 1) begin
        for (column = 0; column < 8; column = column + 1) begin
            ciftDTablolar_next[row][column] =  ciftDTablolar[row][column];
        end
    end 
    
    if(dallanma) begin
        case(ciftDTablolar[sayac][gshare[sayac]])
            GT : begin
				atlanan_gecerli_cmb = 0;    // DONT JUMP
                atlanan_ps_cmb = 0;         // IGNORE
            end
            ZT : begin
				atlanan_gecerli_cmb = 0;    // DONT JUMP
                atlanan_ps_cmb = 0;         // IGNORE
            end
            ZA : begin
				atlanan_gecerli_cmb = 1'b1;
                atlanan_ps_cmb = ps_i + {buyruk_i[31], buyruk_i[7], buyruk_i[30:25], buyruk_i[11:8]};
            end
            GA : begin
				atlanan_gecerli_cmb = 1'b1;
                atlanan_ps_cmb = ps_i + {buyruk_i[31], buyruk_i[7], buyruk_i[30:25], buyruk_i[11:8]};
            end
        endcase
    end
    
    if(guncelle_gecerli_i) begin
        case(ciftDTablolar[sayac_guncel][gshare[sayac_guncel]])
            GT : begin
                if(guncelle_atladi_i) 				// GT => ZT
                    ciftDTablolar_next[sayac_guncel][gshare[sayac_guncel]] = 2'b01;
            end
            
            ZT : begin
                if(guncelle_atladi_i) 				// ZT => GA
                    ciftDTablolar_next[sayac_guncel][gshare[sayac_guncel]] = 2'b11;
                else 								// ZT => GT
                    ciftDTablolar_next[sayac_guncel][gshare[sayac_guncel]] = 2'b00;
            end
            
            ZA : begin
                if(guncelle_atladi_i) 				// ZA => GA
                    ciftDTablolar_next[sayac_guncel][gshare[sayac_guncel]] = 2'b11;
                else 								// ZA => GT
                    ciftDTablolar_next[sayac_guncel][gshare[sayac_guncel]] = 2'b00;
            end
            
            GA: begin
                if(!guncelle_atladi_i) 				// GA => ZA
                    ciftDTablolar_next[sayac_guncel][gshare[sayac_guncel]] = 2'b10;
            end
        endcase
        
        if(guncelle_atladi_i) begin
            gshare_next[sayac_guncel] = {gshare[sayac_guncel][1:0], 1'b1};
            gg_yazmaci_next = {gg_yazmaci[2:0], 1'b1};
        end
        
        else begin
            gshare_next[sayac_guncel] = {gshare[sayac_guncel][1:0], 1'b0};
            gg_yazmaci_next = {gg_yazmaci[2:0], 1'b0};
        end
    end

end

always@(posedge clk_i) begin
   if (rst_i) begin
        gg_yazmaci <= 0;
        gg_yazmaci_next <= 0;
        
        atlanan_ps_cmb <= 0;
        atlanan_gecerli_cmb <= 0;
        
        for (row = 0; row < 16; row = row + 1) begin
           for (column = 0; column < 8; column = column + 1) begin
               ciftDTablolar[row][column] = 2'b00;
               ciftDTablolar_next[row][column] = 2'b00;
           end
		   
		   gshare[row] = 3'b000;
           gshare_next[row] = 3'b000;
        end 
   end
   
   else begin
        gg_yazmaci <= gg_yazmaci_next;
       
        for (row = 0; row < 16; row = row + 1) begin
           for (column = 0; column < 8; column = column + 1) begin
               ciftDTablolar[row][column] <= ciftDTablolar_next[row][column];
           end
		   
		   gshare[row] <= gshare_next[row];
        end 
   end
end

assign atlanan_gecerli_o = atlanan_gecerli_cmb;
assign atlanan_ps_o = atlanan_ps_cmb;

endmodule