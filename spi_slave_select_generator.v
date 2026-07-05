/********************************************************************************************
Filename    :	   spi_slave_select_generator.v   

Description :      spi_slave_select_generator

Author Name :      Sriker

Version     :      1.2
*********************************************************************************************/
module spi_slave_select_generator(

  input PCLK, PRESET_n,

  input mstr_i,

  input spiswai_i,
  
  input [ 1 : 0 ]spi_mode_i,

  input send_data_i,

  input [ 11 : 0 ]BaudRateDivisor_i,
  
  output reg ss_o,

  output tip_o,

  output reg receive_data_o
);

  reg [ 15 : 0 ]count_s;

  wire [ 15 : 0 ]target_s;

  reg rcv;

  parameter SPI_RUN = 2'b00,
  	    SPI_WAIT = 2'b01,
  	    SPI_STOP = 2'b10;  	    
  	    
  assign target_s = BaudRateDivisor_i * 16'd8;

  assign tip_o = ~ss_o;
  
  //Generate SS
  always @( posedge PCLK or negedge PRESET_n )
  begin
  
    if( !PRESET_n )
    begin
      ss_o <= 1'b1;  
      count_s <= 16'hffff;
      rcv <= 1'b0;
    end
    
    else 
    begin
    
      if( ( mstr_i )  && ( ( spi_mode_i == SPI_RUN )  || ( ( spi_mode_i == SPI_WAIT ) && ( !spiswai_i ) ) ) )
      begin
      
        if ( send_data_i ) begin
            ss_o <= 1'b0;
            count_s <= 16'd0;
            rcv <= 1'b0;
        end
        
        else if ( count_s < target_s - 1 ) begin
            ss_o <= 1'b0;
            count_s <= count_s + 16'd1;
            rcv <= 1'b0;
        end
        
        else if ( count_s == target_s - 1  ) begin
            ss_o <= 1'b1;
            count_s <= 16'hffff;
            rcv <= 1'b1;
        end
        
        else begin
            ss_o <= 1'b1;
            count_s <= 16'hffff;
            rcv <= 1'b0;
        end
        
      end
      
      else begin
            ss_o <= 1'b1;
            count_s <= 16'hffff;
            rcv <= 1'b0;
      end
      
    end  
    
  end

  //Generate receive data output
  always @( posedge PCLK or negedge PRESET_n )
  begin
  
    if( !PRESET_n )
    begin
      receive_data_o <= 1'b0;
    end

    else begin
        receive_data_o <= rcv;
    end

  end
  

endmodule