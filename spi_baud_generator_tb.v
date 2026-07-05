/********************************************************************************************
Filename    :	   spi_baud_generator_tb.v   

Description :      spi_baud_generator_tb

Author Name :      Sriker

Version     :      1.1
*********************************************************************************************/
module spi_baud_generator_tb();

  reg PCLK, PRESET_n;
  
  reg [ 1 : 0 ]spi_mode_i;
  
  reg spiswai_i;
  
  reg [ 2 : 0 ]sppr_i, spr_i;
  
  reg cpol_i, cpha_i, ss_i;
  
  wire sclk_o;
  
  wire miso_receive_sclk_pos; //Flag to indicate when to receive miso data when cpol = 0, cphase = 0 or cpol = 1, cphase = 1
  
  wire miso_receive_sclk_neg; //Flag to indicate when to receive miso data when cpol = 0, cphase = 1 or cpol = 1, cphase = 0
  
  wire mosi_send_sclk_pos; //Flag to indicate when to send mosi data when cpol = 0, cphase = 0 or cpol = 1, cphase = 1
  
  wire mosi_send_sclk_neg; //Flag to indicate when to send mosi data when cpol = 0, cphase = 1 or cpol = 1, cphase = 0
  
  wire [ 11 : 0 ]BaudRateDivisor_o;
  
   
  spi_baud_generator DUT( PCLK, PRESET_n, spi_mode_i, spiswai_i, sppr_i, spr_i, cpol_i, cpha_i, ss_i, 
  				sclk_o, miso_receive_sclk_pos, miso_receive_sclk_neg, mosi_send_sclk_pos, mosi_send_sclk_neg, BaudRateDivisor_o );
  
  parameter CYCLE = 10;
  
 // integer i, j;
  
  //Clock generation
  always
  begin
    #( CYCLE/2 );
    PCLK = 0;
    #( CYCLE/2 );
    PCLK = 1;
  end
  
  //task initialize
  task initialize();
  begin
    { spi_mode_i, spiswai_i } = 0;
    cpol_i = 1;
    cpha_i = 1;
     sppr_i = 1; 
     spr_i = 1;
    { PRESET_n, ss_i } = 1;
  end
  endtask
  
  //task DUT reset
  task dut_reset();
  begin
    @( negedge PCLK );
    PRESET_n = 1'b0;
    @( negedge PCLK );
    PRESET_n = 1'b1;
  end
  endtask
 
  //task spi reset
  task spi_reset();
  begin
    @( negedge PCLK );
    ss_i = 1'b1;
    @( negedge PCLK );
    ss_i = 1'b0;
  end
  endtask

  //task cpol, cphase
  task clock_edge( input cpol_value, input cphase_value );
  begin
     @( negedge PCLK );
    cpol_i = cpol_value;
    cpha_i = cphase_value;
  end
  endtask
  
  //task spi mode selection
  task spi_mode_selection( input [ 1 : 0 ]SpiMode, input SpiSwai );
  begin
     @( negedge PCLK );
    spi_mode_i = SpiMode;
    spiswai_i = SpiSwai;
  end
  endtask
  
  //task baud_divisor
  task baud_divisor( input [ 2 : 0 ]sppr_value, input [ 2 : 0 ]spr_value );
  begin
     @( negedge PCLK );
    sppr_i = sppr_value;
    spr_i = spr_value;
  end
  endtask

  initial 
  begin
    initialize();
    dut_reset();
    spi_reset();
    spi_mode_selection( 0, 0 );

    //clock_edge( 1, 1 );

    //baud_divisor( 0, 0 );
    #200;
    
    /* clock_edge( 0, 1 );
    baud_divisor( 7, 7 );
    #200;
    
    clock_edge( 1, 0 );
    baud_divisor( 7, 7 );
    #200;
    
    clock_edge( 1, 1 );
    baud_divisor( 7, 7 );
    #200; */
    
   /* for( i = 0; i < 8; i = i + 1 )
    begin
      for( j = 0; j < 8; j = j + 1 )
      begin
        baud_divisor( i, j );
        #1000;
      end
    end */


  end

  initial #1000 $finish;

  initial
    $monitor( $time, "ns values of clock_divider = %d", BaudRateDivisor_o );

  initial
    begin
      $dumpfile("dump.vcd");
	  $dumpvars(0, spi_baud_generator_tb);
    end
    
    


endmodule
