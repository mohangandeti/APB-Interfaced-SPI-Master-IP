/********************************************************************************************
Filename    :	   spi_slave_select_generator_tb.v   

Description :      spi_slave_select_generator_tb

Author Name :      Sriker

Version     :      1.2
*********************************************************************************************/
module spi_slave_select_generator_tb();

  reg PCLK, PRESET_n;

  reg mstr_i;

  reg spiswai_i;
  
  reg [ 1 : 0 ]spi_mode_i;

  reg send_data_i;

  reg [ 11 : 0 ]BaudRateDivisor_i;
  
  wire ss_o;

  wire tip_o;

  wire receive_data_o;
   
  spi_slave_select_generator DUT( PCLK, PRESET_n, mstr_i, spiswai_i, spi_mode_i, send_data_i, BaudRateDivisor_i, 
                                    ss_o, tip_o, receive_data_o  );
  
  parameter CYCLE = 10;
  
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
    { mstr_i, spiswai_i, spi_mode_i, send_data_i } = 0;
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
 
  //task send data signal
  task send_data_signal();
  begin
    @( negedge PCLK );
    send_data_i = 1'b1;
    @( negedge PCLK );
    send_data_i = 1'b0;
  end
  endtask


  task stimulus();
  begin
    @( negedge PCLK );
    mstr_i = 1;
    spiswai_i = 0;
    spi_mode_i = 0;
    //BaudRateDivisor_i = 2;
  end
  endtask
  

  initial 
  begin
    initialize();
    dut_reset();
    stimulus();
    send_data_signal();
    BaudRateDivisor_i = 2;
    #200;
    send_data_signal();
    BaudRateDivisor_i = 4;
    #400;
    send_data_signal();
    BaudRateDivisor_i = 8;
    #800;
  end

  initial #2000 $finish;

  initial
    $monitor( $time, "ns ss = %b, tip = %b, receive_data_o = %b, BaudRateDivisor_i = %d", ss_o, tip_o, receive_data_o, BaudRateDivisor_i );


  /* initial
    begin
      $dumpfile("dump.vcd");
	  $dumpvars(0, spi_slave_select_generator_tb);
    end */
        


endmodule
