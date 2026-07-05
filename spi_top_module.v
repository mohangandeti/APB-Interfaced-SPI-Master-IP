/********************************************************************************************
Filename    :	   spi_top_module.v   

Description :      spi_top_module

Author Name :      Sriker

Version     :      1.5
*********************************************************************************************/
module spi_top_module(
  input PCLK, PRESET_n,
  
  input [ 2 : 0 ]PADDR_i,  //3 bit address to select one of control registers
  
  input PWRITE_i,  //done
  
  input PSEL_i,  //To transition to setup phase
  
  input PENABLE_i,  //To transition to enable phase
  
  input [ 7 : 0 ]PWDATA_i,
  
  input miso_i,
  
  output [ 7 : 0 ]PRDATA_O,
  
  output PREADY_o, PSLAVERR_o,
  
  output spi_interrupt_request_o,
  
  output ss_o, sclk_o,
  
  output mosi_o

);

	//ports for baud generator
	wire [ 1 : 0 ]spi_mode_o;
	
	wire [ 2 : 0 ]sppr_o, spr_o;
	
	wire spiswai_o, cpol_o, cphase_o;
	
	wire miso_receive_sclk_pos, miso_receive_sclk_neg, mosi_send_sclk_pos, mosi_send_sclk_neg;
	
	wire [ 11 : 0 ]BaudRateDivisor_o;
	
	
	//ports for slave select
	wire mstr_o, send_data_o, tip_o, receive_data_o;
	
	
	//port for shift register
	wire lsbfe_o;
	
	wire [ 7 : 0 ]data_mosi_o, data_miso_o;
	
	
	spi_APB_slave_interface APB_Slave( PCLK, PRESET_n, PADDR_i, PWRITE_i, PSEL_i, PENABLE_i, PWDATA_i,  //inputs 
                                	   ss_o, data_miso_o, receive_data_o, tip_o,   //inputs
                                	   PRDATA_O, mstr_o, cpol_o, cphase_o, lsbfe_o, spiswai_o, sppr_o, spr_o,  //outputs
                                	   spi_interrupt_request_o, PREADY_o, PSLAVERR_o, send_data_o, data_mosi_o, spi_mode_o  //outputs
        );

	
	spi_slave_select_generator slave_select( PCLK, PRESET_n, mstr_o, spiswai_o, spi_mode_o, send_data_o, BaudRateDivisor_o,  //inputs
                                    		 ss_o, tip_o, receive_data_o  //outputs  
        );
        

	spi_baud_generator brg( PCLK, PRESET_n, spi_mode_o, spiswai_o, sppr_o, spr_o, cpol_o, cphase_o, ss_o,  //inputs 
  				sclk_o, miso_receive_sclk_pos, miso_receive_sclk_neg, mosi_send_sclk_pos, mosi_send_sclk_neg, BaudRateDivisor_o  //outputs
	);

        
  	spi_shift_register shift_register( PCLK, PRESET_n, ss_o, send_data_o, lsbfe_o, cpol_o, cphase_o,  //inputs
					   mosi_send_sclk_pos, mosi_send_sclk_neg,  //inputs
  					   miso_receive_sclk_pos, miso_receive_sclk_neg,  //inputs
  					   data_mosi_o, miso_i, receive_data_o,  //inputs
  					   mosi_o, data_miso_o //outputs
  	);


endmodule	
