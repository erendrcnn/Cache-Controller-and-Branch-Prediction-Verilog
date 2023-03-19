`timescale 1ns/1ps

// METIN EREN DURUCAN - 201101038 - HW2

module onbellek (
    // Clock and reset signals
    input               clk_i,
    input               rst_i,

    // Anabellek request signals
    output  [31:0]      anabellek_istek_adres_o,        // Address of the request
    output  [255:0]     anabellek_istek_veri_o,         // Data to be written with the request
    output              anabellek_istek_gecerli_o,      // Request valid
    output              anabellek_istek_yaz_gecerli_o,  // Request write request
    input               anabellek_istek_hazir_i,        // Anabellek ready to accept request

    // Anabellek response signals
    input   [255:0]     anabellek_yanit_veri_i,         // Read data
    input               anabellek_yanit_gecerli_i,      // Read data valid
    output              anabellek_yanit_hazir_o,        // Module ready to accept read data

    // Module request signals
    input   [31:0]      istek_adres_i,                  // Address of the request
    input   [31:0]      istek_veri_i,                   // Data to be written with the request
    input               istek_gecerli_i,                // Request valid
    input               istek_yaz_gecerli_i,            // Request write request
    output              istek_hazir_o,                  // Module ready to accept request

    // Module response signals
    output  [31:0]      yanit_veri_o,                   // Read data from module       
    output              yanit_gecerli_o,                // Read data from module valid
    input               yanit_hazir_i                   // External module ready to accept read data
);

// --------[TERMINAL OUTPUT]----------
// [SIM] Test basarili.
// $finish called at time : 2882657 ns
// -----------------------------------

// REGISTERS

// -------------[HAFIZA_R Bit Chart]---------------
//  			
//  [276] 	  : DIRTY BIT	(1   BIT)
//  [275:256] : ADRESS		(20  BIT)
//  [255:0]	  : DATA 		(256 BIT) [2'7 LINE]
// ------------------------------------------------

reg  [276:0] 	 hafiza_r  [127:0];
reg  [276:0] 	 hafiza_ns [127:0];

reg  [31:0] 	 iska_sayisi_r = 0;
reg  [31:0] 	 iska_sayisi_ns = 0;

reg  [31:0] 	 cikarma_sayisi_r = 0;
reg  [31:0] 	 cikarma_sayisi_ns = 0;

reg  [255:0] 	 onbellek_guncelleme_obegi_r = 0;
reg  [255:0] 	 onbellek_guncelleme_obegi_ns = 0;
reg  [31:0] 	 onbellek_guncelleme_adresi_r = 0;
reg  [31:0]		 onbellek_guncelleme_adresi_ns = 0;
reg 			 onbellek_guncelle_r = 0;
reg 			 onbellek_guncelle_ns = 0;
reg 			 onbellekte_bitti_r = 0;
reg 			 onbellekte_bitti_ns = 0;

reg  [31:0]      anabellek_istek_adres_r;
reg  [31:0]      anabellek_istek_adres_ns;
reg  [255:0]     anabellek_istek_veri_r;
reg  [255:0]     anabellek_istek_veri_ns;
reg              anabellek_istek_gecerli_r;
reg              anabellek_istek_gecerli_ns;
reg              anabellek_istek_yaz_gecerli_r;
reg              anabellek_istek_yaz_gecerli_ns;
reg              anabellek_yanit_hazir_r;
reg              anabellek_yanit_hazir_ns;

reg              anabellek_istek_hazir_r;
reg              anabellek_istek_hazir_ns;
reg  [31:0]      anabellek_yanit_veri_r;
reg  [31:0]      anabellek_yanit_veri_ns;
reg              anabellek_yanit_gecerli_r;
reg              anabellek_yanit_gecerli_ns;

reg  [2:0] 		 durum_r;
reg  [2:0] 		 durum_ns;

reg  [255:0] 	 arabellek_obek_r;
reg  [255:0] 	 arabellek_obek_ns;
reg  [31:0] 	 arabellek_adres_r;
reg  [31:0] 	 arabellek_adres_ns;
reg  [31:0] 	 arabellek_veri_r;
reg  [31:0] 	 arabellek_veri_ns;
reg        		 arabellek_yaz_istek_r;
reg        		 arabellek_yaz_istek_ns;

// ns : kombinasyonel mantik sonraki durum
// r  : sirali mantik su anki durum

// STATE MACHINE

localparam DURUM_BOSTA      = 0;
localparam DURUM_OKU_ISTEK  = 1;
localparam DURUM_YAZ_ISTEK  = 2;
localparam DURUM_BEKLE      = 3;
localparam DURUM_YAZ        = 4;
localparam DURUM_OKU        = 5;
localparam DURUM_YANIT      = 6;
localparam DURUM_BELLEK   	= 7;

integer i;
reg [4:0] bayt_adresi;

// Write the data to the relevant bytes in the given data block
function [255:0] obege_yaz (
    input [255:0] veri_obegi,	// 32 BAYT
    input [31:0]  adres,		//  4 BAYT
    input [31:0]  veri 			//  4 BAYT
);
begin
    bayt_adresi = adres[4:0] & 5'b11100; 	// ALIGN 32 BIT
    obege_yaz = veri_obegi;
    // Little Endian
    for (i = 0; i < 4; i = i + 1) begin
        obege_yaz[(bayt_adresi + i) * 8 +: 8] = veri[i * 8 +: 8];
    end
end
endfunction

// Read the relevant bytes from the given data block
function [31:0] obekten_oku (
    input [255:0] veri_obegi,
    input [31:0] adres
);
begin
    bayt_adresi = adres[4:0] & 5'b11100; 	// ALIGN 32 BIT
    obekten_oku = 0;
    // Little Endian
    for (i = 0; i < 4; i = i + 1) begin
        obekten_oku[i * 8 +: 8] = veri_obegi[(bayt_adresi + i) * 8 +: 8];
    end
end
endfunction

always @* begin
	// UPDATE NEXT STATE
    for (i = 0; i < 128; i = i + 1) begin
        hafiza_ns[i] = hafiza_r[i];
    end
	
    anabellek_istek_adres_ns = anabellek_istek_adres_r;
    anabellek_istek_veri_ns = anabellek_istek_veri_r;
    anabellek_istek_gecerli_ns = anabellek_istek_gecerli_r;
    anabellek_istek_yaz_gecerli_ns = anabellek_istek_yaz_gecerli_r;
    anabellek_yanit_hazir_ns = 0;
    anabellek_istek_hazir_ns = 0;
    anabellek_yanit_gecerli_ns = 0;
    anabellek_yanit_veri_ns = anabellek_yanit_veri_r;
	
    durum_ns = durum_r;
	
    arabellek_obek_ns = arabellek_obek_r;
    arabellek_adres_ns = arabellek_adres_r;
    arabellek_veri_ns = arabellek_veri_r;
    arabellek_yaz_istek_ns = arabellek_yaz_istek_r;
    
    onbellek_guncelleme_obegi_ns = onbellek_guncelleme_obegi_r;
    onbellek_guncelleme_adresi_ns = onbellek_guncelleme_adresi_r;
    onbellek_guncelle_ns = onbellek_guncelle_r;
	onbellekte_bitti_ns = onbellekte_bitti_r;
    
    iska_sayisi_ns = iska_sayisi_r;
    cikarma_sayisi_ns = cikarma_sayisi_r;
    
    case(durum_r)
	
    // No requests
    DURUM_BOSTA: begin
        if(onbellek_guncelle_r) begin 		// Firstly, update ONBELLEK
            arabellek_adres_ns = onbellek_guncelleme_adresi_r;
            arabellek_obek_ns = onbellek_guncelleme_obegi_r;
            onbellek_guncelle_ns = 1'b0;
            onbellekte_bitti_ns = 1'b0;
            durum_ns = DURUM_YAZ_ISTEK;
        end
        else begin 							// NO update in ONBELLEK continue
            anabellek_istek_hazir_ns = 1;
            if (istek_hazir_o && istek_gecerli_i) begin
                anabellek_istek_hazir_ns = 0;
                arabellek_adres_ns = istek_adres_i;
                arabellek_veri_ns = istek_veri_i;
                arabellek_yaz_istek_ns = istek_yaz_gecerli_i;
                //durum_ns = DURUM_OKU_ISTEK;
                durum_ns = DURUM_BELLEK;
            end
        end
    end
	
    // The main memory is sending a read request, wait until the main memory accepts our request (ready and valid).
    DURUM_OKU_ISTEK: begin
        anabellek_istek_gecerli_ns = 1;
        anabellek_istek_yaz_gecerli_ns = 0;
        anabellek_istek_adres_ns = arabellek_adres_r;
        anabellek_istek_veri_ns = arabellek_obek_r;
        if (anabellek_istek_hazir_i && anabellek_istek_gecerli_o) begin
            anabellek_istek_gecerli_ns = 0;
            durum_ns = DURUM_BEKLE;
        end
    end
	
    // The main memory is sending a write request, wait until the main memory accepts our request (ready and valid).
    DURUM_YAZ_ISTEK: begin
        if(onbellekte_bitti_r) begin
			durum_ns = DURUM_BOSTA;
            onbellekte_bitti_ns = 0;
			hafiza_ns[arabellek_adres_r[11:5]][276] = 1'b1;
            hafiza_ns[arabellek_adres_r[11:5]][255:0] = arabellek_obek_r;
        end
		
        else begin
            anabellek_istek_gecerli_ns = 1;
            anabellek_istek_yaz_gecerli_ns = 1;
			anabellek_istek_veri_ns = arabellek_obek_r;
            anabellek_istek_adres_ns = arabellek_adres_r;
			
            if (anabellek_istek_gecerli_o && anabellek_istek_hazir_i) begin
                durum_ns = DURUM_BOSTA;
				anabellek_istek_gecerli_ns = 0;
                anabellek_istek_yaz_gecerli_ns = 0;
            end
        end
    end
	
    // Sent a request to read the main memory and waiting for it to respond...
    DURUM_BEKLE: begin
        anabellek_yanit_hazir_ns = 1;
		
        if (anabellek_yanit_hazir_o && anabellek_yanit_gecerli_i) begin
            anabellek_yanit_hazir_ns = 0;
            arabellek_obek_ns = anabellek_yanit_veri_i;
			
            // Check if the previous data is dirty, if it is DIRTY we will go to ANABELLEK and WRITE
            if(hafiza_r[arabellek_adres_r[11:5]][275:256] != arabellek_adres_r[31:12] && hafiza_r[arabellek_adres_r[11:5]][276] == 1'b1) begin
                // OLD LABEL 				: 20 BIT
				// LINE + BYTE SELECTION 	: 12 BIT
                // The new data will have a label in arabellek_adres_r
                onbellek_guncelleme_adresi_ns = {hafiza_r[arabellek_adres_r[11:5]][275:256], arabellek_adres_r[11:0]};
				onbellek_guncelleme_obegi_ns = hafiza_r[arabellek_adres_r[11:5]][255:0];
                onbellek_guncelle_ns = 1'b1;
				
				cikarma_sayisi_ns = cikarma_sayisi_r + 1;
            end
			
			else begin
				cikarma_sayisi_ns = cikarma_sayisi_r + 1;
			end

            // The status is pending, but if we can't find it in the cache, we enter it, so the cache should be updated.
			
			onbellekte_bitti_ns = 1'b1;
            hafiza_ns[arabellek_adres_r[11:5]] = {1'b0, arabellek_adres_r[31:12] ,anabellek_yanit_veri_i};
			
            durum_ns = arabellek_yaz_istek_r ? DURUM_YAZ : DURUM_OKU;
        end
    end
	
    // Overwrite the data chunk from the main memory, then write the chunk back to the main memory.
    DURUM_YAZ: begin
        arabellek_obek_ns = obege_yaz(arabellek_obek_r, arabellek_adres_r, arabellek_veri_r);
        durum_ns = DURUM_YAZ_ISTEK;
    end
	
    // Read and respond to the requested 32 bits from the data block from the main memory.
    DURUM_OKU: begin
        anabellek_yanit_veri_ns = obekten_oku(arabellek_obek_r, arabellek_adres_r);
        durum_ns = DURUM_YANIT;
    end
	
    // Wait for the module making the request to be ready.
    DURUM_YANIT: begin
        anabellek_yanit_gecerli_ns = 1;
		
        if (yanit_hazir_i && yanit_gecerli_o) begin
            anabellek_yanit_gecerli_ns = 0;
            durum_ns = DURUM_BOSTA;
        end
    end
	
	// Data control status in the ONBELLEK
    DURUM_BELLEK: begin
        // If there is same data at the relevant address in the ONBELLEK
        if((hafiza_r[arabellek_adres_r[11:5]][275:256] == arabellek_adres_r[31:12])) begin
             arabellek_obek_ns = hafiza_r[arabellek_adres_r[11:5]][255:0];
             onbellekte_bitti_ns = 1'b1;
             durum_ns = arabellek_yaz_istek_r ? DURUM_YAZ : DURUM_OKU;
        end
		
        // If there is NO same data at the relevant address in the ONBELLEK
        else begin
            iska_sayisi_ns = iska_sayisi_r + 1'b1;
            durum_ns = DURUM_OKU_ISTEK;
        end
    end
    endcase
end

always @(posedge clk_i) begin
    if (rst_i) begin
		// ASSIGN EMPTY DATA
        for (i = 0; i < 128; i = i + 1) begin
            hafiza_r[i] <= ~276'bx;
        end
		
        durum_r <= DURUM_BOSTA;
		
        anabellek_istek_adres_r <= 0;
        anabellek_istek_veri_r <= 0;
        anabellek_istek_gecerli_r <= 0;
        anabellek_istek_yaz_gecerli_r <= 0;
        anabellek_yanit_hazir_r <= 0;
        anabellek_istek_hazir_r <= 0;
        anabellek_yanit_veri_r <= 0;
        anabellek_yanit_gecerli_r <= 0;
		
        arabellek_obek_r <= 0;
		
        onbellek_guncelleme_obegi_r <= 0;
        onbellek_guncelleme_adresi_r <= 0;
        onbellek_guncelle_r <= 0;
		onbellekte_bitti_r <= 0;
		
        iska_sayisi_r <= 0;
        cikarma_sayisi_r <= 0;
    end
	
    else begin
        durum_r <= durum_ns;
		
		// UPDATE NEXT STATE
        for (i = 0; i < 128; i = i + 1) begin
            hafiza_r[i] <= hafiza_ns[i];
        end
		
        anabellek_istek_adres_r <= anabellek_istek_adres_ns;
        anabellek_istek_veri_r <= anabellek_istek_veri_ns;
        anabellek_istek_gecerli_r <= anabellek_istek_gecerli_ns;
        anabellek_istek_yaz_gecerli_r <= anabellek_istek_yaz_gecerli_ns;
        anabellek_yanit_hazir_r <= anabellek_yanit_hazir_ns;
        anabellek_istek_hazir_r <= anabellek_istek_hazir_ns;
        anabellek_yanit_veri_r <= anabellek_yanit_veri_ns;
        anabellek_yanit_gecerli_r <= anabellek_yanit_gecerli_ns;
		
        arabellek_obek_r <= arabellek_obek_ns;
        arabellek_adres_r <= arabellek_adres_ns;
        arabellek_veri_r <= arabellek_veri_ns;
        arabellek_yaz_istek_r <= arabellek_yaz_istek_ns;
        
        onbellek_guncelleme_obegi_r <= onbellek_guncelleme_obegi_ns;
        onbellek_guncelleme_adresi_r <= onbellek_guncelleme_adresi_ns;
        onbellek_guncelle_r <= onbellek_guncelle_ns;
		onbellekte_bitti_r <= onbellekte_bitti_ns;
		
        iska_sayisi_r <= iska_sayisi_ns;
        cikarma_sayisi_r <= cikarma_sayisi_ns;
    end
end

assign anabellek_istek_adres_o = anabellek_istek_adres_r;
assign anabellek_istek_veri_o = anabellek_istek_veri_r;
assign anabellek_istek_gecerli_o = anabellek_istek_gecerli_r;
assign anabellek_istek_yaz_gecerli_o = anabellek_istek_yaz_gecerli_r;
assign anabellek_yanit_hazir_o = anabellek_yanit_hazir_r;
assign istek_hazir_o = anabellek_istek_hazir_r;
assign yanit_veri_o = anabellek_yanit_veri_r;
assign yanit_gecerli_o = anabellek_yanit_gecerli_r;

endmodule