/********************************************************************************************
Filename    :	   spi_shift_register.v   

Description :      spi_shift_register

Author Name :      Sriker

Version     :      1.3
*********************************************************************************************/
module spi_shift_register(
  input PCLK, PRESET_n,
  
  input ss_i, send_data_i, lsbfe_i, cpol_i, cpha_i, 
  
  input mosi_send_sclk_pos_i, //Flag to indicate when to send mosi data when cpol = 0, cphase = 0 or cpol = 1, cphase = 1
  
  input mosi_send_sclk_neg_i, //Flag to indicate when to send mosi data when cpol = 0, cphase = 1 or cpol = 1, cphase = 0
  
  input miso_receive_sclk_pos_i, //Flag to indicate when to receive miso data when cpol = 0, cphase = 0 or cpol = 1, cphase = 1
  
  input miso_receive_sclk_neg_i, //Flag to indicate when to receive miso data when cpol = 0, cphase = 1 or cpol = 1, cphase = 0
  
  input [ 7 : 0 ]data_mosi_i, //data mosi is 8 bits of data recieved from spi data register of APB slave interface
  
  input miso_i, //miso data will be received bit by bit from slave side, so collect it in a temperory register and then transmit all 8 bits of data together 			parallely to spi data register of APB slave interface whenever receive_data signal is high
  
  input receive_data_i, //whenver this signal is high it means all 8 bits are tranferred from slave to master, master to slave perfectly. whenever this bit 				is high 8 bits of data_miso_o are written to spi_data register

  output reg mosi_o, //data_mosi is collected parallely into a temporary register and the data in temporary register is transmitted bit by bit to mosi line
  
  output [ 7 : 0 ]data_miso_o

);

  reg [ 7 : 0 ]temp_mosi_data, temp_miso_data;
  
  reg [ 2 : 0 ]counter_mosi_lsb_first, counter_mosi_msb_first, counter_miso_lsb_first, counter_miso_msb_first;
  
  //assign x = ( counter_mosi_lsb_first == 4'd8 );
  
  
  //Load data_mosi_i to a temporary register.
  /* 
 	1. Main target is to collect data_mosi_i from spi data register and store it in temporary register.
 	2. Then from temporary register we will be transmitting the data bit by bit to mosi_o line. 
   */
  always @( posedge PCLK or negedge PRESET_n )
  begin
  
    if( !PRESET_n )
    begin
      temp_mosi_data <= 8'd0;
    end
    
    else
    begin
      
      if( send_data_i )
      begin
        temp_mosi_data <= data_mosi_i;
      end
      
      else
      begin
        temp_mosi_data <= temp_mosi_data;
      end
    
    end
  
  end
  
  
  //transmit data bit by bit to mosi output line
  always @( posedge PCLK or negedge PRESET_n )
  begin
  
    if( !PRESET_n )
    begin
      mosi_o <= 1'b0;
      counter_mosi_lsb_first <= 3'd0;
      counter_mosi_msb_first <= 3'd7;
    end
    
    else
    begin
      
      if( !ss_i )  //work only if slave select signal is low
      begin
        
        if( cpol_i != cpha_i )  //This indicates the negedge of sclk
        begin
        
          if( lsbfe_i )  //lsbfe_i = 1 this indicates that transmit LSB bit first 
          begin
          
            if( counter_mosi_lsb_first <= 3'd7 && mosi_send_sclk_neg_i )  //mosi send negedge flag
            begin
              mosi_o <= temp_mosi_data[ counter_mosi_lsb_first ];  //Drive mosi line with correct bit of shift register
              
              counter_mosi_lsb_first <= counter_mosi_lsb_first + 3'd1;  //Increment the counter  
            end
            
            else
            begin
              mosi_o <= mosi_o;
              
              //if( counter_mosi_lsb_first == 4'd8 )  when count value reaches 8 then reset the value
                //counter_mosi_lsb_first <= 4'd0;
            end
          
          end
          
          else  //lsbfe_i = 0 this indicates that transmit MSB bit first  
          begin
            
            if( ( counter_mosi_msb_first >= 3'd0 ) && ( mosi_send_sclk_neg_i ) )  //mosi send negedge flag
            begin
              mosi_o <= temp_mosi_data[ counter_mosi_msb_first ];  //Drive mosi line with correct bit of shift register
              
              counter_mosi_msb_first <= counter_mosi_msb_first - 3'd1;  //Decrement the counter
            end
            
            else
            begin
              mosi_o <= mosi_o;
              
              //if( counter_mosi_msb_first == 4'b1111 )  when count value reaches 4'b1111 then reset the value
                //counter_mosi_msb_first <= 4'd7;
            end
            
          end
       
        end
        
        else if( cpol_i == cpha_i )  //This indicates the posedge of sclk  
        begin
        
          if( lsbfe_i )  //lsbfe_i = 1 this indicates that transmit LSB bit first
          begin
          
            if( counter_mosi_lsb_first <= 3'd7 && mosi_send_sclk_pos_i )  //mosi send posedge flag
            begin
              mosi_o <= temp_mosi_data[ counter_mosi_lsb_first ];  //Drive mosi line with correct bit of shift register
              
              counter_mosi_lsb_first <= counter_mosi_lsb_first + 3'd1;  //Increment the counter
            end
            
            else
            begin
              mosi_o <= mosi_o;
              
              //if( counter_mosi_lsb_first == 4'd8 )  when count value reaches 8 then reset the value
                //counter_mosi_lsb_first <= 4'd0;
              
            end
          
          end
          
          else  //lsbfe_i = 0 this indicates that transmit MSB bit first
          begin
            
            if( ( counter_mosi_msb_first >= 3'd0 ) && ( mosi_send_sclk_pos_i ) )  //mosi send posedge flag
            begin
              mosi_o <= temp_mosi_data[ counter_mosi_msb_first ];  //Drive mosi line with correct bit of shift register
              
              counter_mosi_msb_first <= counter_mosi_msb_first - 3'd1;  //Decrement the counter
            end
            
            else
            begin
              mosi_o <= mosi_o;
              
              //if( counter_mosi_msb_first == 4'b1111 )  when count value reaches 4'b1111 then reset the value
                //counter_mosi_msb_first <= 4'd7;
            end
            
          end
       
        end
        
        else
        begin
          mosi_o <= 1'b0;
          counter_mosi_lsb_first <= 3'd0;
          counter_mosi_msb_first <= 3'd7;
        end
        
      end
      
      else  // do not work as slave select signal is high
      begin
        mosi_o <= 1'b0;
        counter_mosi_lsb_first <= 3'd0;
        counter_mosi_msb_first <= 3'd7;
      end
      
    end
  
  end
  
  
  //data_miso_o should be loaded with temporary register data
    /* 
 	1. Main target is to collect miso_i bit by bit and store it in a temporary register.
 	2. Then from temporary register we will be transmitting the data paralley onto [ 7 : 0 ]data_miso_o when receive_data_i is high. 
   */
/*  always @( posedge PCLK or negedge PRESET_n )
  begin
  
    if( !PRESET_n )
    begin
      temp_miso_data <= 8'd0;
      data_miso_o <= 8'd0;
    end
    
    else
    begin
      
      if( receive_data_i )
      begin
        data_miso_o <= temp_miso_data; 
      end
      
      else
      begin
        data_miso_o <= 8'd0;
      end
    
    end
  
  end */
  
  assign data_miso_o = ( receive_data_i ) ? temp_miso_data : 8'd0;  //write combinational logic
  
  
  //bit by bit data coming from miso_i has to be collected into temp_miso_data
  always @( posedge PCLK or negedge PRESET_n )
  begin
  
    if( !PRESET_n )
    begin
      temp_miso_data <= 8'd0;
      counter_miso_lsb_first <= 3'd0;
      counter_miso_msb_first <= 3'd7;
    end
    
    else
    begin
      
      if( !ss_i )  //work only if slave select signal is low
      begin
        
        if( cpol_i != cpha_i )  //This indicates negedge of sclk
        begin
        
          if( lsbfe_i )  //lsbfe_i = 1 indicates receive lsb bit first
          begin
          
            if( counter_miso_lsb_first <= 3'd7 && miso_receive_sclk_neg_i )  //miso receive negedge flag
            begin
              temp_miso_data[ counter_miso_lsb_first ] <= miso_i;  //Load the data coming bit by bit into a temp_miso_data register
              
              counter_miso_lsb_first <= counter_miso_lsb_first + 3'd1;  //increment the counter
            end
            
            else
            begin
              temp_miso_data[ counter_miso_lsb_first ] <= temp_miso_data[ counter_miso_lsb_first ];
              
              //if( counter_miso_lsb_first == 4'd8 )  when count value reaches 8 then reset the value
                //counter_miso_lsb_first <= 4'd0;
            end
          
          end
          
          else  //lsbfe_i = 0 indicates receive MSB bit first
          begin
            
            if( ( counter_miso_msb_first >= 3'd0 ) && ( miso_receive_sclk_neg_i ) )  //miso receive negedge flag
            begin
              temp_miso_data[ counter_miso_msb_first ] <= miso_i;  //Load the data coming bit by bit into a temp_miso_data register
              
              counter_miso_msb_first <= counter_miso_msb_first - 3'd1;  //decrement the counter
            end
            
            else
            begin
              temp_miso_data[ counter_miso_msb_first ] <= temp_miso_data[ counter_miso_msb_first ];
              
              //if( counter_miso_msb_first == 4'b1111 )  when count value reaches 4'b1111 then reset the value
                //counter_miso_msb_first <= 4'd7;
            end
            
          end
       
        end
        
        else if( cpol_i == cpha_i )  //This indicates posedge od sclk
        begin
        
          if( lsbfe_i )  //lsbfe_i = 1 indicates receive lsb bit first
          begin
          
            if( counter_miso_lsb_first <= 3'd7 && miso_receive_sclk_pos_i )  //miso receive posedge flag
            begin
              temp_miso_data[ counter_miso_lsb_first ] <= miso_i;  //Load the data coming bit by bit into a temp_miso_data register
              
              counter_miso_lsb_first <= counter_miso_lsb_first + 3'd1;  //increment the counter
            end
            
            else
            begin
              temp_miso_data[ counter_miso_lsb_first ] <= temp_miso_data[ counter_miso_lsb_first ];
              
              //if( counter_miso_lsb_first == 4'd8 )  when count value reaches 8 then reset the value
                //counter_miso_lsb_first <= 4'd0;
            end
          
          end
          
          else  //lsbfe_i = 0 indicates receive msb bit first
          begin
            
            if( ( counter_miso_msb_first >= 3'd0 ) && ( miso_receive_sclk_pos_i ) )  //miso receive posedge flag
            begin
              temp_miso_data[ counter_miso_msb_first ] <= miso_i;  //Load the data coming bit by bit into a temp_miso_data register
              
              counter_miso_msb_first <= counter_miso_msb_first - 3'd1;  //decrement the counter
            end
            
            else
            begin
              temp_miso_data[ counter_miso_msb_first ] <= temp_miso_data[ counter_miso_msb_first ];
              
              //if( counter_miso_msb_first == 4'b1111 )  when count value reaches 4'b1111 then reset the value
                //counter_miso_msb_first <= 4'd7;
            end
            
          end
       
        end
        
        
        else
        begin
          temp_miso_data <= temp_miso_data;
          counter_miso_lsb_first <= 3'd0;
          counter_miso_msb_first <= 3'd7;
        end
        
      end
      
      else //ss is high means do not work
      begin
        temp_miso_data <= temp_miso_data;
        counter_miso_lsb_first <= 3'd0;
        counter_miso_msb_first <= 3'd7;
      end
      
    end
  
  end
  
  
endmodule