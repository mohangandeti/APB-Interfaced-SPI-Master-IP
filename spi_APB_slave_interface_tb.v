/********************************************************************************************
Filename    :	   spi_APB_slave_interface_tb.v   

Description :    spi_APB_slave_interface_tb

Author Name :      Sriker

Version     :      1.4
*********************************************************************************************/
module spi_APB_slave_interface_tb();

  reg PCLK, PRESET_n;
  
  reg [ 2 : 0 ]PADDR_i;  //3 bit address to select one of control registers
  
  reg PWRITE_i;
  
  reg PSEL_i;  //To transition to setup phase
  
  reg PENABLE_i;  //To transition to enable phase
  
  reg [ 7 : 0 ]PWDATA_i;
  
  reg ss_i;
  
  reg [ 7 : 0 ]miso_data_i;
  
  reg receive_data_i;
  
  reg tip_i;
  
  wire [ 7 : 0 ]PRDATA_O;
  
  wire mstr_o, cpol_o, cphase_o, lsbfe_o;  //CR1 Outputs
  
  wire spiswai_o;  //CR2 Outputs
  
  wire [ 2 : 0 ]sppr_o, spr_o;  //Output of Baud register
  
  wire spi_interrupt_request_o;
  
  wire PREADY_o, PSLAVERR_o;
  
  wire send_data_o;
  
  wire [ 7 : 0 ]mosi_data_o;
  
  wire [ 1 : 0 ]spi_mode_o;

  
  parameter CYCLE = 10;
  
  //clock generation
  always
  begin
    #( CYCLE/2 );
    PCLK = 1'b0;
    #( CYCLE/2 );
    PCLK = 1'b1;
  end


  spi_APB_slave_interface DUT( PCLK, PRESET_n, PADDR_i, PWRITE_i, PSEL_i, PENABLE_i, PWDATA_i,  //inputs 
                                ss_i, miso_data_i, receive_data_i, tip_i,   //inputs
                                PRDATA_O, mstr_o, cpol_o, cphase_o, lsbfe_o, spiswai_o, sppr_o, spr_o,  //outputs
                                spi_interrupt_request_o, PREADY_o, PSLAVERR_o, send_data_o, mosi_data_o, spi_mode_o  //outputs
                            );

  //task initialize
  task initialize();
  begin

    { PADDR_i, PWRITE_i, PSEL_i, PENABLE_i, PWDATA_i, ss_i, miso_data_i, receive_data_i, tip_i } = 0;

  end
  endtask
  
  
  //task DUT reset
  task dut_reset();
  begin
    //@( negedge PCLK );
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
    PADDR_i = 3'b000;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
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
    PADDR_i = 3'b001;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
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
    PADDR_i = 3'b010;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
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
    PADDR_i = 3'b101;
    PWRITE_i = 1'b1;
    PSEL_i = 1'b1;
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
    PADDR_i = paddr;
    PWRITE_i = 1'b0;  //pwrite signal should be low
    PSEL_i = 1'b1;
    PENABLE_i = 1'b1;  //ENABLE phase

    @( negedge PCLK );
    PENABLE_i = 1'b0;  //IDLE phase
    PSEL_i = 1'b0;

  end
  endtask

  //ss_i, miso_data_i, receive_data_i, tip_i,
  task other_inputs();
  begin

    @( negedge PCLK );
    ss_i = 1;
    tip_i = ~ss_i;
    receive_data_i = 0;
    miso_data_i = 0;
    
    repeat( 32 ) begin
    @( negedge PCLK );
    ss_i = 1'b0;
    tip_i = ~ss_i;
    end

    @( negedge PCLK );
    ss_i = 1;
    tip_i = ~ss_i;
    receive_data_i = 1;
    miso_data_i = 8'hAB;

  end
  endtask


  initial begin

    initialize();
    dut_reset();
    
    write_registers( 8'b0100_0000, 8'b0000_0000, 8'b0000_0001 );  //baud divisor is 4

    write_data_register( 8'hCD );

    read_register( 3'b000 );

    read_register( 3'b001 );

    read_register( 3'b010 );

    read_register( 3'b011 );

    read_register( 3'b101 );

    other_inputs();
    
  end

/*
PRDATA_O, mstr_o, cpol_o, cphase_o, lsbfe_o, spiswai_o, sppr_o, spr_o,  //outputs
spi_interrupt_request_o, PREADY_o, PSLAVERR_o, send_data_o, mosi_data_o, spi_mode_o
*/
  initial
    $monitor( $time, " ns, spi_mode_o = %b, send_data_o = %b, mosi_data_o = %b, PRDATA_O = %b ", spi_mode_o, send_data_o, mosi_data_o, PRDATA_O );


    initial #2000 $finish;

/*
 initial
    begin
      $dumpfile("dump.vcd");
	  $dumpvars(0, spi_APB_slave_interface_tb);
    end   */






endmodule