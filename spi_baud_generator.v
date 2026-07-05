/********************************************************************************************
Filename    :	   spi_baud_generator.v   

Description :      spi_baud_generator

Author Name :      Sriker

Version     :      1.1
*********************************************************************************************/
module spi_baud_generator(

  input PCLK, PRESET_n,
  
  input [ 1 : 0 ]spi_mode_i,
  
  input spiswai_i,
  
  input [ 2 : 0 ]sppr_i, spr_i,
  
  input cpol_i, cpha_i, ss_i,
  
  output reg sclk_o,
  
  output reg miso_receive_sclk_pos, //Flag to indicate when to receive miso data when cpol = 0, cphase = 0 or cpol = 1, cphase = 1
  
  output reg miso_receive_sclk_neg, //Flag to indicate when to receive miso data when cpol = 0, cphase = 1 or cpol = 1, cphase = 0
  
  output reg mosi_send_sclk_pos, //Flag to indicate when to send mosi data when cpol = 0, cphase = 0 or cpol = 1, cphase = 1
  
  output reg mosi_send_sclk_neg, //Flag to indicate when to send mosi data when cpol = 0, cphase = 1 or cpol = 1, cphase = 0
  
  output [ 11 : 0 ]BaudRateDivisor_o 
  
);

  parameter SPI_RUN = 2'b00,
  	    SPI_WAIT = 2'b01,
  	    SPI_STOP = 2'b10;
  	    
  wire pre_sclk_s;
  
  reg [ 11 : 0 ]count_s;  	    
  	    
  assign BaudRateDivisor_o = ( sppr_i + 12'd1 ) * ( 12'd2 << spr_i );
  
  assign pre_sclk_s = cpol_i ? 1'b1 : 1'b0;
  
  //Generate SPI clock
  always @( posedge PCLK or negedge PRESET_n )
  begin
  
    if( !PRESET_n )
    begin
      sclk_o <= pre_sclk_s;
      count_s <= 12'd0;
    end
    
    else if( ( !ss_i )  && ( ( spi_mode_i == SPI_RUN )  || ( ( spi_mode_i == SPI_WAIT ) && ( !spiswai_i ) ) ) )
    begin
      
      if( count_s == BaudRateDivisor_o/12'd2 - 12'd1 )
      begin
        count_s <= 12'd0;
        sclk_o <= ~sclk_o;
      end
      
      else
      begin
        count_s <= count_s + 12'd1;
      end
      
    end
    
    else
    begin
      sclk_o <= pre_sclk_s;
      count_s <= 12'd0;
    end
    
  end


  //Generate MOSI sample Flags 	
  always @( posedge PCLK or negedge PRESET_n )
  begin
  
    if( !PRESET_n )
    begin
      mosi_send_sclk_pos <= 1'b0;
      mosi_send_sclk_neg <= 1'b0;
    end

    else if( cpol_i == cpha_i )  //cpol = 0, cphase = 0 or cpol = 1, cphase = 1
    begin
      mosi_send_sclk_neg <= 1'b0;
	
      if( BaudRateDivisor_o == 12'd2 ) begin
          mosi_send_sclk_pos <= sclk_o;
          
      end	  
        
      else if( ( !sclk_o ) && ( count_s == BaudRateDivisor_o/12'd2 - 12'd2 ) && ( !ss_i ) ) //posedge
      begin
          mosi_send_sclk_pos <= 1'b1;		//Posedge Flag
      end
      
      else
      begin
        mosi_send_sclk_pos <= 1'b0;
      end
      
    end
    
    else if( cpol_i != cpha_i  ) //cpol = 0, cphase = 1 or cpol = 1, cphase = 0
    begin
      mosi_send_sclk_pos <= 1'b0;
      
      if( BaudRateDivisor_o == 12'd2 ) begin
          mosi_send_sclk_neg <= ~sclk_o;
      end
    
      else if( ( sclk_o ) && ( count_s == BaudRateDivisor_o/12'd2 - 12'd2 ) ) //Negedge
      begin
          mosi_send_sclk_neg <= 1'b1;		//Negedge flag
      end
      
      else
      begin
        mosi_send_sclk_neg <= 1'b0;
      end
      
    end

    else
    begin
      mosi_send_sclk_pos <= 1'b0;
      mosi_send_sclk_neg <= 1'b0;
    end 
   
  end

  
  //Generate MISO sample Flags 	
  always @( posedge PCLK or negedge PRESET_n )
  begin
  
    if( !PRESET_n )
    begin
      miso_receive_sclk_pos <= 1'b0;
      miso_receive_sclk_neg <= 1'b0;
    end
    
    else if( ( cpol_i == cpha_i ) && ( !ss_i ) )  //cpol = 0, cphase = 0 or cpol = 1, cphase = 1
    begin
      miso_receive_sclk_neg <= 1'b0;
      
      if( !sclk_o )
      begin
        
        if( count_s == BaudRateDivisor_o/12'd2 - 12'd1 )
          miso_receive_sclk_pos <= 1'b1;		//Posedge flag
        
        else   
      	  miso_receive_sclk_pos <= 1'b0;
      	  
      end
      
      else
      begin
        miso_receive_sclk_pos <= 1'b0;
      end
      
    end
    
    else if( ( cpol_i != cpha_i ) && ( !ss_i ) ) //cpol = 0, cphase = 1 or cpol = 1, cphase = 0
    begin
      miso_receive_sclk_pos <= 1'b0;
      
      if( sclk_o )
      begin
        
        if( count_s == BaudRateDivisor_o/12'd2 - 12'd1 )
          miso_receive_sclk_neg <= 1'b1;		//Negedge flag
        
        else   
      	  miso_receive_sclk_neg <= 1'b0;
      	  
      end
      
      else
      begin
        miso_receive_sclk_neg <= 1'b0;
      end
      
    end
      
    else
    begin
      miso_receive_sclk_pos <= 1'b0;
      miso_receive_sclk_neg <= 1'b0;
    end 
   
  end

  

endmodule