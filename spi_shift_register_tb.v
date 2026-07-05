/********************************************************************************************
Filename    :	   spi_shift_register_tb.v   

Description :      spi_shift_register_tb

Author Name :      Sriker

Version     :      1.3
*********************************************************************************************/
module spi_shift_register_tb();

  reg PCLK, PRESET_n;
  
  wire ss_i;
  
  reg send_data_i, lsbfe_i, cpol_i, cpha_i; 
  
  wire mosi_send_sclk_pos_i; //Flag to indicate when to send mosi data when cpol = 0, cphase = 0 or cpol = 1, cphase = 1
  
  wire mosi_send_sclk_neg_i; //Flag to indicate when to send mosi data when cpol = 0, cphase = 1 or cpol = 1, cphase = 0
  
  wire miso_receive_sclk_pos_i; //Flag to indicate when to receive miso data when cpol = 0, cphase = 0 or cpol = 1, cphase = 1
  
  wire miso_receive_sclk_neg_i; //Flag to indicate when to receive miso data when cpol = 0, cphase = 1 or cpol = 1, cphase = 0
  
  reg [ 7 : 0 ]data_mosi_i; //data mosi is 8 bits of data recieved from APB slave interface
  
  reg miso_i; //miso data will be received bit by bit from slave collect it in a temperory register to transmit all 8 bits together parallely to APB slave
  
  wire receive_data_i; //whenver this signal is high it means all 8 bits are tranferred and I am ready to accept new data

  wire mosi_o; //mosi data received from APB slave interface needs to be transmitted bit by bit using sclk
  
  wire [ 7 : 0 ]data_miso_o;
  			   
  parameter CYCLE = 10;
  
  //clock generation
  always
  begin
    #( CYCLE/2 );
    PCLK = 1'b0;
    #( CYCLE/2 );
    PCLK = 1'b1;
  end
  
  //baud register inputs, outputs
  reg [ 1 : 0 ]spi_mode_i;
  reg spiswai_i;
  reg [ 2 : 0 ]sppr_i, spr_i;
  wire sclk_o;
  wire [ 11 : 0 ]BaudRateDivisor_o;
  
  //baud register instantiation
  spi_baud_generator brg( PCLK, PRESET_n, spi_mode_i, spiswai_i, sppr_i, spr_i, cpol_i, cpha_i, ss_i, //inputs
  				sclk_o, miso_receive_sclk_pos_i, miso_receive_sclk_neg_i, //outputs
  				mosi_send_sclk_pos_i, mosi_send_sclk_neg_i, BaudRateDivisor_o );  //outputs
  				
  //slave select inputs and outputs				
  reg mstr_i;
  wire tip_o;
  
  //slave select instantiation
  spi_slave_select_generator  slave( PCLK, PRESET_n, mstr_i, spiswai_i, spi_mode_i, send_data_i, BaudRateDivisor_o, //inputs
                                    ss_i, tip_o, receive_data_i ); //outputs
  
  				
  //shift register instantiation				
  spi_shift_register DUT( PCLK, PRESET_n, ss_i, send_data_i, lsbfe_i, cpol_i, cpha_i,  //inputs
  				mosi_send_sclk_pos_i, mosi_send_sclk_neg_i,  //inputs
  				miso_receive_sclk_pos_i, miso_receive_sclk_neg_i,  //inputs
  				data_mosi_i, miso_i, receive_data_i,  //inputs
  				mosi_o, data_miso_o );  //outputs
  				
  //task initialize
  task initialize();
  begin
    { send_data_i, data_mosi_i } = 0;
    lsbfe_i= 0;
    cpol_i = 0;
    cpha_i = 0;
    
    { spi_mode_i, spiswai_i } = 0;
     sppr_i = 0; 
     spr_i = 1;
     
     mstr_i = 1;
     
    //{ ss_i } = 1;
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
/*  task spi_reset();
  begin
    @( negedge PCLK );
    ss_i = 1'b1;
    @( negedge PCLK );
    ss_i = 1'b0;
  end
  endtask */
  
  
  //task send data signal
  task send_data_signal();
  begin
    @( negedge PCLK );
    send_data_i = 1'b1;
    @( negedge PCLK );
    send_data_i = 1'b0;
  end
  endtask
  
  //task receive data signal
  /* task receive_data_signal();
  begin
    @( negedge PCLK );
    receive_data_i = 1'b1;
    @( negedge PCLK );
    receive_data_i = 1'b0;
  end
  endtask */
  
  
  //task send stimulus
  task send_stimulus( input [ 7 : 0 ]data );
  begin
    @( negedge PCLK );
    data_mosi_i = data;
  end
  endtask
  
  integer i;
  
  //task receive stimulus
  task receive_stimulus( input [ 7 : 0 ]data );
  begin
    miso_i = 1'b0;
    
    wait( ~ss_i )
    for( i = 7; i >= 0; i = i - 1 )
    begin
      @( posedge sclk_o )
      begin
        miso_i = data[ i ];
      end
    end    
  
  end
  endtask
  
  //task receive stimulus
/*  task receive_stimulus( input [ 7 : 0 ]data );
  begin
    miso_i = 1'b0;
    
    wait( ~ss_i )
    for( i = 0; i < 8; i = i + 1 )
    begin
      @( posedge sclk_o )
      begin
        miso_i = data[ i ];
      end
    end    
  
  end
  endtask */
  
  
  //calling the tasks
  initial
  begin
    initialize();
    dut_reset();
    //spi_reset();
    send_stimulus( 8'h33 );
    send_data_signal();
   
    receive_stimulus( 8'h55 );
    //receive_data_signal();
  end
  
  initial
    $monitor( $time, "ns, mosi_o = %b, data_miso_o = %h, BaudRateDivisor_o = %d", mosi_o, data_miso_o, BaudRateDivisor_o );
    
  initial #1000 $finish;  
  
  
  
endmodule