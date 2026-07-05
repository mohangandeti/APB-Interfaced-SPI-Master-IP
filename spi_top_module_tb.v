/********************************************************************************************
Filename    :	   spi_top_module_tb.v   

Description :    spi_top_module_tb

Author Name :      Sriker

Version     :      1.5
*********************************************************************************************/
module spi_top_module_tb();

  reg PCLK, PRESET_n;
  
  reg [ 2 : 0 ]PADDR_i;  //3 bit address to select one of control registers
  
  reg PWRITE_i;
  
  reg PSEL_i;  //To transition to setup phase
  
  reg PENABLE_i;  //To transition to enable phase
  
  reg [ 7 : 0 ]PWDATA_i;
  
  reg miso_i;
  
  wire [ 7 : 0 ]PRDATA_O;
  
  wire PREADY_o, PSLAVERR_o;
  
  wire spi_interrupt_request_o;
  
  wire ss_o, sclk_o;
  
  wire mosi_o;

  
  parameter CYCLE = 10;

  
  //task for sending miso data bit by bit
  integer i;
  
  spi_top_module DUT( PCLK, PRESET_n, PADDR_i, PWRITE_i, PSEL_i, PENABLE_i, PWDATA_i, miso_i,  //inputs
                      PRDATA_O, PREADY_o, PSLAVERR_o, spi_interrupt_request_o, ss_o, sclk_o, mosi_o  //outputs
                    );
  
  //clock generation
  always
  begin
    PCLK = 1'b0;							
    #( CYCLE/2 );
    PCLK = 1'b1;
    #( CYCLE/2 );
  end
                    
  //task initialize
  task initialize();
  begin

    { PADDR_i, PWRITE_i, PSEL_i, PENABLE_i, PWDATA_i, miso_i } = 0;

  end
  endtask
  
  
  //task DUT reset
  task dut_reset();
  begin
    PRESET_n = 1'b0;
    @( negedge PCLK );
    PRESET_n = 1'b1;
  end
  endtask
  

  //task to write cr1, cr2, br
  task write_registers( input [7 : 0]cr1, input [7 : 0]cr2, input [7 : 0]br );
  begin
    //Writing to CR1
    @( negedge PCLK );
    PADDR_i = 3'b000;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge PCLK );
    PENABLE_i = 1'b1;  //ENABLE phase
    PWDATA_i = cr1;

    @( negedge PCLK );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;

    //Writing to CR2
    @( negedge PCLK );
    PADDR_i = 3'b001;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge PCLK );
    PENABLE_i = 1'b1;  //ENABLE phase
    PWDATA_i = cr2;

    @( negedge PCLK );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;


    //writing to baud register
    @( negedge PCLK );
    PADDR_i = 3'b010;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge PCLK );
    PENABLE_i = 1'b1;  //ENABLE phase
    PWDATA_i = br;

    @( negedge PCLK );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;

  end
  endtask

  
  //task to write into data register
  task write_data_register( input [7 : 0]dr );
  begin
    //Writing to data register
    @( negedge PCLK );
    PADDR_i = 3'b101;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge PCLK );
    PENABLE_i = 1'b1;  //ENABLE phase
    PWDATA_i = dr;

    @( negedge PCLK );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;

  end
  endtask

  
  //task for reading registers
  task read_register( input [2 : 0]paddr );
  begin
    //Writing to data register
    @( negedge PCLK );
    PADDR_i = paddr;
    PWRITE_i = 1'b0;  //pwrite signal should be low
    PSEL_i = 1'b1;
    PENABLE_i = 1'b0;  //SETUP phase

    @( negedge PCLK );
    PENABLE_i = 1'b1;  //ENABLE phase

    @( negedge PCLK );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;

  end
  endtask
  
  
  
  //task receive stimulus lsbfe = 0, MSB first, cpol == cphase
  task receive_lsbfe0_pos( input [ 7 : 0 ]data );
  begin
    miso_i = 1'b0;
    
    wait( ~ss_o );
    for( i = 7; i >= 0; i = i - 1 )
    begin
      @( posedge sclk_o );  //cpol == cphase
        miso_i = data[ i ];
    end
  
  end
  endtask
  
  
  //task receive stimulus lsbfe = 0, MSB first, cpol != cphase
  task receive_lsbfe0_neg( input [ 7 : 0 ]data );
  begin
    miso_i = 1'b0;
    
    wait( ~ss_o );
    for( i = 7; i >= 0; i = i - 1 )
    begin
      @( negedge sclk_o );  //cpol != cphase
        miso_i = data[ i ];
    end
  
  end
  endtask
  
  
  //task receive stimulus lsbfe = 1, LSB first, cpol == cphase
  task receive_lsbfe1_pos( input [ 7 : 0 ]data );
  begin
    miso_i = 1'b0;
    
    wait( ~ss_o )
    for( i = 0; i < 8; i = i + 1 )  //LSB First so start from i = 0
    begin
      @( posedge sclk_o )  //cpol == cphase
      begin
        miso_i = data[ i ];
      end
    end    
  
  end
  endtask
  
  
  //task receive stimulus lsbfe = 1, LSB first, cpol != cphase
  task receive_lsbfe1_neg( input [ 7 : 0 ]data );
  begin
    miso_i = 1'b0;
    
    wait( ~ss_o )
    for( i = 0; i < 8; i = i + 1 )  //LSB First so start from i = 0
    begin
      @( negedge sclk_o )  //cpol != cphase
      begin
        miso_i = data[ i ];
      end
    end    
  
  end
  endtask
  
  
    initial 
    begin

    	initialize();
    	dut_reset();
    
    	write_registers( 8'b1101_0000, 8'b0000_0000, 8'b0000_0001 );  //baud divisor is 4

	write_data_register( 8'hAB );

	//receive_lsbfe0_neg( 8'hCD );

	receive_lsbfe0_pos( 8'hCD );

	//receive_lsbfe1_pos( 8'hCD );

    	read_register( 3'b000 );

    	read_register( 3'b001 );

    	read_register( 3'b010 );

    	read_register( 3'b011 );

    	read_register( 3'b101 );
    
    end


  initial
    $monitor( $time, " ns, PRDATA_O = %b, mosi_o = %b, BaudRateDivisor_o = %d ", PRDATA_O, mosi_o, DUT.BaudRateDivisor_o );


    initial #2000 $finish;

  
endmodule