/********************************************************************************************
Filename    :	   spi_APB_slave_interface.v   

Description :      spi_APB_slave_interface

Author Name :      Sriker

Version     :      1.4
*********************************************************************************************/
module spi_APB_slave_interface(
  input PCLK, PRESET_n,
  
  input [ 2 : 0 ]PADDR_i,  //3 bit address to select one of control registers
  
  input PWRITE_i,  //done
  
  input PSEL_i,  //To transition to setup phase
  
  input PENABLE_i,  //To transition to enable phase
  
  input [ 7 : 0 ]PWDATA_i,
  
  input ss_i,
  
  input [ 7 : 0 ]miso_data_i,  //done
  
  input receive_data_i,  //done
  
  input tip_i,
  
  output reg [ 7 : 0 ]PRDATA_O,
  
  output mstr_o, cpol_o, cphase_o, lsbfe_o,  //CR1 Outputs
  
  output spiswai_o,  //CR2 Outputs
  
  output [ 2 : 0 ]sppr_o, spr_o,  //Output of Baud register
  
  output reg spi_interrupt_request_o,  //done
  
  output PREADY_o, PSLAVERR_o,  //done
  
  output reg send_data_o,  //done
  
  output reg [ 7 : 0 ]mosi_data_o,  //done
  
  output reg [ 1 : 0 ]spi_mode_o  //done

);

  reg [ 7 : 0 ]SPI_CR1, SPI_CR2, SPI_BR, SPI_SR, SPI_DR;
  
  parameter cr2_mask = 8'b0001_1011;  //2,5,6,7 bits of cr2 are to be left empty, remember like one, eleven
 
  parameter br_mask = 8'b0111_0111;  //3,7 bits of baud register are to be left empty
  
  //CR1[ 7 ], CR1[ 6 ], CR1[ 5 ], CR1[ 1 ], 
  wire spie, spe, sptie, ssoe;
  
  //CR2[ 4 ]
  wire modfen;
  
  //SR[ 7 ], SR[ 5 ], SR[ 4 ] 
  wire spif, sptef, modf;
  
  wire wr_enb, rd_enb;
  
  //APB FSM States
  parameter IDLE = 2'b00,
   	    SETUP = 2'b01, 
   	    ENABLE = 2'b10;
   	    
  //APB FSM reg declaration 	    
  reg [ 1 : 0 ]state, next_state;
  
  //APB FSM Present state logic
  always @( posedge PCLK, negedge PRESET_n )
  begin
  	if( !PRESET_n )
  	begin
  		state <= IDLE;
  	end
  	
  	else
  	begin
  		state <= next_state;
  	end
  	
  end
  
  //APB FSM next state combinational logic
  always @( * )
  begin
  	case( state )
  	
  	IDLE :  if( PSEL_i && !PENABLE_i )
  		  next_state = SETUP;
		else
  		  next_state = IDLE;
  		  
  	SETUP : if( !PSEL_i )
	  	  next_state = IDLE;
  	
  		else if( PSEL_i && PENABLE_i )
	  	  next_state = ENABLE;
	  	  
		else 	//if( PSEL_i && !PENABLE_i )
	  	  next_state = SETUP;  	  
	  	  
  	ENABLE : if( !PSEL_i )
	  	  next_state = IDLE;
 
  		 else if( PSEL_i && !PENABLE_i )
  	  	    next_state = SETUP;
  	  	    
		 else
  	  	    next_state = ENABLE;
  	  	    
  	default : next_state = IDLE;   	    
  	  	    
  	endcase
  end
  
  
  //Generate APB Control Signals output PREADY_o, PSLAVERR_o,
  assign PREADY_o = ( state == ENABLE ) ? 1'b1 : 1'b0;

  /*  PSLVERR is only considered valid during the last cycle of an APB transfer, when
	PSEL, PENABLE, and PREADY are all HIGH.
	
	It is recommended, but not mandatory, that you drive PSLVERR LOW when it is not
	being sampled. That is, when any of PSEL, PENABLE, or PREADY are LOW.
  */
  
  //assign PSLAVERR_o = ( state == ENABLE ) ? 1'b0 : ~tip_i;  //if send data goes high tip should also go high , if this is not happening flag the error
  
  //assign PSLAVERR_o = ( state == ENABLE && !tip_i ) ? 1'b1 : 1'b0;

  assign PSLAVERR_o = ( ( send_data_o && !tip_i ) || ( !ss_i && !tip_i )  || ( ss_i && tip_i ) ) ? 1'b1 : 1'b0;
  
  //wire wr_enb, rd_enb;  Generate Write and Read Enables
  assign wr_enb = ( ( state == ENABLE ) && PWRITE_i ) ? 1'b1 : 1'b0;
  
  assign rd_enb = ( ( state == ENABLE ) && !PWRITE_i ) ? 1'b1 : 1'b0;
  
  
  //spi mode FSM States
  parameter SPI_RUN = 2'b00,
   	    SPI_WAIT = 2'b01, 
   	    SPI_STOP = 2'b10;
   	    
  //spi mode FSM reg declaration 	    
  reg [ 1 : 0 ]next_mode;

  //SPI mode FSM Present state logic
  always @( posedge PCLK, negedge PRESET_n )
  begin
  	if( !PRESET_n )
  	begin
  		spi_mode_o <= SPI_RUN;
  	end
  	
  	else
  	begin
  		spi_mode_o <= next_mode;
  	end
  end

  //SPI mode FSM next state combinational logic
  always @( * )
  begin
  	case( spi_mode_o )
  	
  	SPI_RUN : if( !spe  )
  		  next_mode = SPI_WAIT;
  		  
  		  else
  		  next_mode = SPI_RUN;
  		  
  	SPI_WAIT : if( spiswai_o )
  		   next_mode = SPI_STOP;
  		   
  		   else if( spe )
  		   next_mode = SPI_RUN;
  		   
  		   else
  		   next_mode = SPI_WAIT;  
	  	  
  	SPI_STOP : if( spe )
  		   next_mode = SPI_RUN;
  		   
  		   else if( !spiswai_o )
  		   next_mode = SPI_WAIT;
  		   
  		   else
  	  	   next_mode = SPI_STOP;
  	  	   
  	default : next_mode = SPI_RUN; 	   
  	  	    
  	endcase
  end	
  
  

  /*
	Write a sequential logic to register PWDATA to internal variables(SPI_CR_1,SPI_CR_2, SPI_BR) based on PDDR.
  */
  //CR1 Control Register 1
  always @( posedge PCLK, negedge PRESET_n )
  begin
  	if( !PRESET_n )
  	begin
  		SPI_CR1 <= 8'b0000_0100;  //8'h04
  	end
  	
  	else
  	begin
  		if( wr_enb )
  		begin
  			if( PADDR_i == 3'b000 )
  			begin
  				SPI_CR1 <= PWDATA_i;
  			end
  			
  			else
  			begin
  				SPI_CR1 <= SPI_CR1;  //HOLD DATA
  			end
  		end
  		
  		else
  		begin
  			SPI_CR1 <= SPI_CR1;
  		end
  	end
  end
  
  
  //Decode Control Register Fields, Assign fields from SPI_CR_1 to outputs: mstr_o, cpol_o, cphase_o, lsbfe_o, wire spie, spe, sptie, ssoe;
  assign spie = SPI_CR1[ 7 ];
  
  assign spe = SPI_CR1[ 6 ];
  
  assign sptie = SPI_CR1[ 5 ];
  
  assign mstr_o = SPI_CR1[ 4 ];
  
  assign cpol_o = SPI_CR1[ 3 ];
  
  assign cphase_o = SPI_CR1[ 2 ];
  
  assign ssoe = SPI_CR1[ 1 ];
  
  assign lsbfe_o = SPI_CR1[ 0 ];
  
  
  //CR2 Control Register 2
  always @( posedge PCLK, negedge PRESET_n )
  begin
  	if( !PRESET_n )
  	begin
  		SPI_CR2 <= 8'b0000_0000;  //8'h00
  	end
  	
  	else
  	begin
  		if( wr_enb )
  		begin
  			if( PADDR_i == 3'b001 )
  			begin
  				SPI_CR2 <= cr2_mask & PWDATA_i;
  			end
  			
  			else
  			begin
  				SPI_CR2 <= SPI_CR2;
  			end
  		end
  		
  		else
  		begin
  			SPI_CR2 <= SPI_CR2;  //8'h00
  		end
  	end
  end
  
  
  //Decode Control Register Fields, Assign fields from SPI_CR_2 to outputs:
  assign modfen = SPI_CR2[ 4 ];
  
  assign spiswai_o = SPI_CR2[ 1 ];
  
  
  //BAUD REGISTER
  always @( posedge PCLK, negedge PRESET_n )
  begin
  	if( !PRESET_n )
  	begin
  		SPI_BR <= 8'b0000_0000;  //8'h00
  	end
  	
  	else
  	begin
  		if( wr_enb )
  		begin
  			if( PADDR_i == 3'b010 )
  			begin
  				SPI_BR <= br_mask & PWDATA_i;
  			end
  			
  			else
  			begin
  				SPI_BR <= SPI_BR;
  			end
  		end
  		
  		else  //I am in setup or idle state
  		begin
  			SPI_BR <= SPI_BR;  //8'h00
  		end
  	end
  end
  
  
  //Decode Baud Register Fields, Assign fields from SPI_BR to outputs: sppr_o, spr_o
  assign sppr_o = SPI_BR[ 6 : 4 ];
  
  assign spr_o = SPI_BR[ 2 : 0 ];
  
  
  
  //SPI DATA REGISTER
  always @( posedge PCLK, negedge PRESET_n )
  begin
  	if( !PRESET_n )
  	begin
  		SPI_DR <= 8'b0000_0000;  //8'h00
  	end
  	
  	else
  	begin
  		if( wr_enb )  //PWRITE_i should be high and state must be ENABLE then only write the data to data register
  		begin
  			if( PADDR_i == 3'b101 )
  			begin
  				SPI_DR <= PWDATA_i;
  			end
  			
  			else
  			begin
  				SPI_DR <= SPI_DR;
  			end
  		end
  		
  		else  //PWRITE_i should be high and state may be IDLE or SETUP then only write the data
  		begin
  			if( ( ( spi_mode_o == SPI_RUN ) || ( spi_mode_o == SPI_WAIT ) ) && ( SPI_DR != miso_data_i ) && ( SPI_DR == PWDATA_i ) )
  			begin
  				SPI_DR <= 8'b0000_0000; 
  			end
  			
  			else
  			begin
  				if( ( ( spi_mode_o == SPI_RUN ) || ( spi_mode_o == SPI_WAIT ) ) && ( receive_data_i ) )
  				begin
  					SPI_DR <= miso_data_i;
  				end
  				
  				else
  				begin
  					SPI_DR <= SPI_DR;
  				end
  			end
  		end
  	end
  end
  
  
  //assign status register values   //SR[ 7 ], SR[ 5 ], SR[ 4 ] wire spif, sptef, modf;
  assign spif = ( SPI_DR != 8'b0000_0000 ) ? 1'b1 : 1'b0 ;
  
  assign sptef = ( SPI_DR == 8'b0000_0000 ) ? 1'b1 : 1'b0 ;
  
  assign modf = ( ( !ss_i ) && ( mstr_o ) && ( modfen ) && ( ssoe ) ) ? 1'b1 : 1'b0;
    
  //SPI STATUS REGISTER
  always @( posedge PCLK, negedge PRESET_n )
  begin
  	if( !PRESET_n )
  	begin
  		SPI_SR <= 8'b0010_0000;  //8'h20
  	end
  	
  	else
  	begin
  		SPI_SR <= { spif, 1'b0, sptef, modf, 4'b0 };
  	end
  end
  
  
  //Send data output signal
  always @( posedge PCLK, negedge PRESET_n )
  begin
  	if( !PRESET_n )
  	begin
  		send_data_o <= 1'b0;
  	end
  	
  	else
  	begin
		if( ( ( spi_mode_o == SPI_RUN ) || ( spi_mode_o == SPI_WAIT ) ) && ( SPI_DR != miso_data_i ) && ( SPI_DR == PWDATA_i ) )
		begin
			send_data_o <= 1'b1;
		end
		
		else
		begin
			send_data_o <= 1'b0;
		end
  	end
  end
  
  
    
  //mosi_data_o output data
  always @( posedge PCLK, negedge PRESET_n )
  begin
  	if( !PRESET_n )
  	begin
  		mosi_data_o <= 8'd0;
  	end
  	
  	else
  	begin  			  		
		if( ( ( spi_mode_o == SPI_RUN ) || ( spi_mode_o == SPI_WAIT ) ) && ( SPI_DR != miso_data_i ) && ( SPI_DR == PWDATA_i ) )
		begin
			mosi_data_o <= SPI_DR;
		end
	
		else
		begin
			mosi_data_o <= mosi_data_o;
		end
  	end
  end


  //Implement APB Read Data Path
  always @( * )
  begin
  	if( !rd_enb )
  	begin
  		PRDATA_O = 8'd0;
  	end
  	
  	else
  	begin
  		case( PADDR_i )
  		
  		3'b000 : PRDATA_O = SPI_CR1;
  		
  		3'b001 : PRDATA_O = SPI_CR2;
  		
  		3'b010 : PRDATA_O = SPI_BR;
  		
  		3'b011 : PRDATA_O = SPI_SR;
  		
  		3'b101 : PRDATA_O = SPI_DR;
  		
  		default : PRDATA_O = 8'd0;
  		
  		endcase
  	end
  end

  
  
  //spi interrupt signal
  always@( * )
  begin
  
  	//if( !spie && !sptie )
  	//begin
  		//spi_interrupt_request_o = 1'b0;
  	//end
  	
  	if( spie && !sptie )  //this interrupt is given highest priority. SPIF interrupt has more priority.
  	begin
  		spi_interrupt_request_o = ( spif || modf );  //CPU can hold the data, first accept the data from outside let the data come in and store in 
  	end							//data register then CPU will take control and place its data
  	
  	else if( !spie && sptie )
  	begin
  		spi_interrupt_request_o = sptef;
  	end
  	
  	else
  	begin
  		spi_interrupt_request_o = ( spif || sptef || modf );
  	end
 
  end
  
  


endmodule
