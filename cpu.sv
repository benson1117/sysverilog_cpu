module cpu(	
	input reset,	
	input clk,
	output logic[7:0]w_q
);

	logic [10:0] pc_q	,mar_q, pc_next,pc,stack_q,k_change,w_change;
	logic [2:0]ps,ns, sel_pc, sel_alu, dnum, sel_bus,sel_bit;
	logic [3:0]op;
	logic load_pc,load_mar,load_ir,load_w, ram_en,load_port_b,addr_port_b,reset_ir;
	logic [13:0] ir_q,prog_data;
	logic [7:0] alu, ram_out, mux1_out, databus,RAM_mux,bcf_mux,bsf_mux,btfsc_btfss_skip_bit,port_b_out;
	logic [1:0] sel_RAM_mux;
	logic MOVLW,ADDLW,SUBLW,ANDLW,IORLW,XORLW;
	logic GOTO, ADDWF, ANDWF,CLRF, CLRW,COMF, DECF,BCF,BSF,BTFSC,BTFSS,DECFSZ,INCFSZ,btfsc_skip_bit,btfss_skip_bit,alu_zero;
	logic ASRF,LSLF,LSRF,RLF,RRF,SWAPF, CALL, RETURN;
	logic push,pop;
	logic BRA,BRW,NOP;
	

assign MOVLW=ir_q[13:8]==6'b110000;
assign ADDLW=ir_q[13:8]==6'b111110;
assign SUBLW=ir_q[13:8]==6'b111100;
assign ANDLW=ir_q[13:8]==6'b111001;
assign IORLW=ir_q[13:8]==6'b111000;
assign XORLW=ir_q[13:8]==6'b111010;

assign GOTO =ir_q[13:11]==3'b101;
assign ADDWF=ir_q[13:8]==6'b000111;
assign ANDWF=ir_q[13:8]==6'b000101;
assign CLRF =ir_q[13:7]==7'b0000011;
assign CLRW  = ir_q[13:2]== 12'b000001000000;
assign COMF =ir_q[13:8]==6'b001001;
assign DECF =ir_q[13:8]==6'b000011;

assign INCF =ir_q[13:8]==6'b001010;
assign IORWF=ir_q[13:8]==6'b000100;
assign MOVF =ir_q[13:8]==6'b001000;
assign MOVWF=ir_q[13:7]==7'b0000001;
assign SUBWF=ir_q[13:8]==6'b000010;
assign XORWF=ir_q[13:8]==6'b000110;

assign BCF=ir_q[13:10]==4'b0100;
assign BSF=ir_q[13:10]==4'b0101;
assign BTFSC=ir_q[13:10]==4'b0110;
assign BTFSS=ir_q[13:10]==4'b0111;

assign DECFSZ=ir_q[13:8]==6'b001011;
assign INCFSZ=ir_q[13:8]==6'b001111;

assign ASRF		=ir_q[13:8]	==6'b110111;
assign LSLF		=ir_q[13:8]	==6'b110101;
assign LSRF		=ir_q[13:8]	==6'b110110;
assign RLF		=ir_q[13:8]	==6'b001101;
assign RRF		=ir_q[13:8]	==6'b001100;
assign SWAPF	=ir_q[13:8]	==6'b001110;
assign CALL		=ir_q[13:11]==3'b100;
assign RETURN	=ir_q[13:0]==14'b00000000001000;

assign BRA 		=ir_q[13:9]==5'b11001;
assign BRW     =ir_q[13:0]==14'b00000000001011;
assign NOP		=ir_q[13:0]==14'b00000000000000;

assign dnum=ir_q[7];
assign pc=pc_q+1;
assign sel_bit=ir_q[9:7];
assign btfsc_skip_bit = ram_out[ir_q[9:7]]==0;
assign btfss_skip_bit = ram_out[ir_q[9:7]]==1;
assign btfsc_btfss_skip_bit = (BTFSC & btfsc_skip_bit)|(BTFSS & btfss_skip_bit);
assign alu_zero=(alu == 0)? 1'b1 : 1'b0;
assign addr_port_b = (ir_q[6:0] == 7'h0d);

assign k_change = {ir_q[8],ir_q[8],ir_q[8:0]}; 
assign w_change = {3'b0,w_q};

always_comb
begin
		unique case(sel_RAM_mux)
			0:RAM_mux=ram_out;
			1:RAM_mux=bcf_mux;
			2:RAM_mux=bsf_mux;
		endcase
end
	
	
always_ff@(posedge clk)
begin
	if (load_mar) mar_q <=  pc_q;
end

always_comb
begin
	unique case(sel_pc)
		0:pc_next <=  pc;
		1:pc_next <=  ir_q[10:0];
		2:pc_next <= stack_q;
		3:pc_next <= pc_q+k_change;
		4:pc_next <= pc_q+w_change;
	endcase
end


always_ff@(posedge clk or posedge reset)
begin
	if (reset) pc_q <=  0;
	else if (load_pc) pc_q <=  pc_next;
end

Program_Rom rom(
	.Rom_data_out(prog_data),
	.Rom_addr_in(mar_q)
	
);



always_ff@(posedge clk)
begin
	if(reset_ir) ir_q <=  0;
	else if (load_ir) ir_q <=  prog_data;
end



always_ff@(posedge clk or posedge reset)
begin
	if(reset) ps <= 0; 
	else ps <= ns;
end

single_port_ram_128x8 Ram(
	.data(databus),
	.addr(ir_q[6:0]),
	.ram_en(ram_en),
	.clk(clk),
	.q(ram_out)
);
Stack stk1(
	.clk(clk),
	.reset(reset),
	.push(push),
	.pop(pop),
	.stack_in(pc_q),
	.stack_out(stack_q)
);

always_comb
begin
	unique case(sel_alu)
		0:mux1_out <=  ir_q[7:0];
		1:mux1_out <=  RAM_mux;
endcase
end

always_comb
begin
	unique case(sel_bus)
		0:databus <=  alu[7:0];
		1:databus <=  w_q;
endcase
end

always_comb
	begin
		unique case(sel_bit)
			3'b000 : bcf_mux = ram_out & 8'b1111_1110;
			3'b001 : bcf_mux = ram_out & 8'b1111_1101;
			3'b010 : bcf_mux = ram_out & 8'b1111_1011;
			3'b011 : bcf_mux = ram_out & 8'b1111_0111;
			3'b100 : bcf_mux = ram_out & 8'b1110_1111;
			3'b101 : bcf_mux = ram_out & 8'b1101_1111;
			3'b110 : bcf_mux = ram_out & 8'b1011_1111;
			3'b111 : bcf_mux = ram_out & 8'b0111_1111;
		endcase
	end

always_comb
	begin
		unique case(sel_bit)
			3'b000 : bsf_mux = ram_out | 8'b0000_0001;
			3'b001 : bsf_mux = ram_out | 8'b0000_0010;
			3'b010 : bsf_mux = ram_out | 8'b0000_0100;
			3'b011 : bsf_mux = ram_out | 8'b0000_1000;
			3'b100 : bsf_mux = ram_out | 8'b0001_0000;
			3'b101 : bsf_mux = ram_out | 8'b0010_0000;
			3'b110 : bsf_mux = ram_out | 8'b0100_0000;
			3'b111 : bsf_mux = ram_out | 8'b1000_0000;
		endcase
	end	

always_comb
	 begin
		case(op)
			4'h0: alu=mux1_out[7:0] + w_q;
			4'h1: alu=mux1_out[7:0] - w_q;
			4'h2: alu=mux1_out[7:0] & w_q;
			4'h3: alu=mux1_out[7:0] | w_q;
			4'h4: alu=mux1_out[7:0] ^ w_q;
			4'h5: alu=mux1_out[7:0];
			4'h6: alu=mux1_out[7:0] + 1;
			4'h7: alu=mux1_out[7:0] - 1;
			4'h8: alu=0;
			4'h9: alu= ~mux1_out[7:0];
			4'hA: alu={mux1_out[7],mux1_out[7:1]};
			4'hB: alu={mux1_out[6:0],1'b0};
			4'hC: alu={1'b0,mux1_out[7:1]};
			4'hD: alu={mux1_out[6:0],mux1_out[7]};
			4'hE: alu={mux1_out[0],mux1_out[7:1]};
			4'hF: alu={mux1_out[3:0],mux1_out[7:4]};
			default: alu = mux1_out + w_q;
		endcase
	end



always_ff@(posedge clk or posedge reset)
begin
	if(reset) w_q <= 0;
	else if(load_w) w_q <= alu;
end

always_ff@(posedge clk)
begin
	if(reset)port_b_out <= 0;
	else if(load_port_b) port_b_out <= databus;
end



always_comb
begin
	ns=0;
	op=0;
	load_pc=0;
	load_mar=0;
	load_ir=0;
	load_w=0;
	ram_en=0;
	sel_pc=0;
	sel_alu=0;
	sel_bus=1;
	sel_RAM_mux=0;
	load_port_b=0;
	push=0;
	pop=0;
	reset_ir=0;
	case(ps)
		0:
		begin
			load_mar=1;
			sel_pc=0;
			load_pc=1;
			ns=1;
			
		end
		1:
		begin
			
			ns=2;
		end
		2:
		begin
			load_ir=1;
			ns=3;
		end
		3:
		begin
			load_mar= 1;
			sel_pc= 2'b00;
			load_pc= 1;
			if(MOVLW)
				begin
					op=5;
					load_w=1;
					
				end
			else if(ADDLW)
				begin
					op=0;
					load_w=1;
				end
			else if(IORLW)
				begin
					op=3;
					load_w=1;
				end
			else if(SUBLW)
				begin
					op=1;
					load_w=1;
				end
			else if(ANDLW)
				begin
					op=2;
					load_w=1;
				end
			else if(XORLW)
				begin
					op=4;
					load_w=1;
				end
			
			else if(ADDWF)
				begin
					op=0;
					sel_alu=1;
					case(dnum)
						0:load_w=1;
						1:ram_en=1;
					endcase
				end
			else if(ANDWF)
				begin
					op=2;
					sel_alu=1;
					case(dnum)
						0:load_w=1;
						1:ram_en=1;
					endcase
				end
			else if(CLRF)
				begin
					op=8;
					ram_en=1;
					
				end
			else if(CLRW)
				begin
					op=8;
					load_w=1;
				end
			else if(COMF)
				begin
					op=9;
					sel_alu=1;
					ram_en=1;
				end
			else if(DECF)
				begin
					op=7;
					sel_alu=1;
					ram_en=1;
				end
				
				
				
				
				
			else if(INCF)
				begin
					op=6;
					sel_alu=1;
					case(dnum)
						0:	load_w=1;
						1:	begin
								ram_en=1;
								sel_bus=0;
							end
					endcase
				end	
			else if(IORWF)
				begin
					op=3;
					sel_alu=1;
					case(dnum)
						0:	load_w=1;
						1:	begin
								ram_en=1;
								sel_bus=0;
							end
					endcase
				end	
			else if(MOVF)
				begin
					op=5;
					sel_alu=1;
					case(dnum)
						0:	load_w=1;
						1:	begin
								ram_en=1;
								sel_bus=0;
							end
					endcase
				end	
				
			else if(MOVWF)
				begin
					
					sel_bus=1;
					case(addr_port_b)
						0:ram_en=1;
						1:load_port_b= 1;
					endcase
				end
				
			else if(SUBWF)
				begin
					op      = 1;
					sel_alu = 1;
					case(dnum)
						0:	load_w=1;
						1:	begin
								ram_en=1;
								sel_bus=0;
							end
					endcase
				end	
			else if(XORWF)
				begin
					op=4;
					sel_alu=1;
					case(dnum)
						0:	load_w=1;
						1:	begin 
								ram_en = 1;
								sel_bus = 0;
							end
					endcase
				end
			
		
	
			else if (BCF)
				begin
					sel_alu= 1;
					sel_RAM_mux = 1;
					op[3:0] = 5;
					sel_bus= 0;
					ram_en= 1;
				end
			else if (BSF)
				begin
					sel_alu= 1;
					sel_RAM_mux = 2;
					op[3:0] = 5;
					sel_bus= 0;
					ram_en= 1;
				end
			else if(CALL)
				begin
					push=1;
				end
///			else if(BTFSC)
///				begin
///					if (btfsc_btfss_skip_bit)
///						begin
///							load_pc= 1;
///							sel_pc= 0;
///						end
///				end
///			else if(BTFSS)
///				begin
///					if (btfsc_btfss_skip_bit)
///						begin
///							load_pc= 1;
///							sel_pc= 0;
///						end
///				end	
			else if(DECFSZ)
				begin
					case(dnum)
					0:
						begin
							sel_alu= 1;
							op[3:0] =  7;
							load_w= 1;
							if (alu_zero)
								begin
									load_pc= 1;
									sel_pc=0;
								end
						
						end
					1:
						begin
							sel_alu= 1;
							op[3:0] = 7;
							ram_en= 1;
							sel_bus= 0;
							if (alu_zero)
								begin
									load_pc= 1;
									sel_pc=0;
								end
							
						end
					endcase
				end
///			else if(INCFSZ)
///				begin
///					case(dnum)
///					0:
///						begin
///							sel_alu= 1;
///							op[3:0] =  6;
///							load_w= 1;
///							if (alu_zero)
///								begin
///									load_pc= 1;
///									sel_pc=0;
///								end
///						end
///					1:
///						begin
///							sel_alu= 1;
///							op[3:0] = 6;
///							ram_en= 1;
///							sel_bus= 0;
///							if (alu_zero)
///								begin
///									load_pc= 1;
///									sel_pc=0;
///								end
///						end
///					endcase
///				end
		//////////////////////////////////////////////////		
			else if(ASRF)
				begin
					sel_alu= 1;
					sel_RAM_mux= 0;
					op = 4'hA;
					case(dnum)
					0:load_w= 1;
					1:
						begin
							sel_bus= 0;
							ram_en= 1;
						end
					endcase
				end
			
			else if(LSLF)
				begin
					sel_alu= 1;
					sel_RAM_mux= 0;
					op = 4'hB;
					case(dnum)
					0:load_w= 1;
					1:
						begin
							sel_bus= 0;
							ram_en= 1;
						end
					endcase
				end
			
			else if(LSRF)
				begin
					sel_alu= 1;
					sel_RAM_mux= 0;
					op = 4'hC;
					case(dnum)
					0:load_w= 1;
					1:
						begin
							sel_bus= 0;
							ram_en= 1;
						end
					endcase
				end
				
			else if(RLF)
				begin
					sel_alu= 1;
					sel_RAM_mux= 0;
					op = 4'hD;
					case(dnum)
						0:load_w= 1;
						1:
							begin
								sel_bus= 0;
								ram_en= 1;
							end
					endcase
				end
			
			else if(RRF)
				begin
					sel_alu= 1;
					sel_RAM_mux= 0;
					op = 4'hE;
					case(dnum)
						0:load_w= 1;
						1:
							begin
								sel_bus= 0;
								ram_en= 1;
							end
					endcase
				end
			
			else if(SWAPF)
				begin
					sel_alu= 1;
					sel_RAM_mux= 0;
					op = 4'hF;
					case(dnum)
						0:load_w= 1;
						1:
							begin
								sel_bus= 0;
								ram_en= 1;
							end
					endcase
				end
			
				
		/////////////////////////////////////////////////////////
			else if(BRA)
				begin
					load_pc= 1;
					sel_pc= 3;
				end
			else if(BRW)
				begin
					load_pc= 1;
					sel_pc= 4;
				end
		else if(NOP)
				begin
				end
			
			
			
			
			ns=4;
		end
		4:
		begin
			if(GOTO)
				begin
					sel_pc=1;
					load_pc=1;
				end
			else if(CALL)
				begin
					sel_pc=1;
					load_pc=1;
					
				end
			else if(RETURN)
				begin
					sel_pc=2;
					load_pc=1;
					pop=1;
				end
//			else if(BRA)
//				begin
//					load_pc= 1;
//					sel_pc= 3;
//				end
//			else if(BRW)
//				begin
//					load_pc= 1;
//					sel_pc= 4;
//				end	
//				
				
				
			ns=5;
		end
		5:
		begin
			load_ir= 1;
			if(GOTO)
				begin
					reset_ir= 1;
				end
			else if(CALL)
				begin
					reset_ir= 1;
				end
			else if(RETURN)
				begin
					reset_ir= 1;
				end
//			else if(DECFSZ)
//				begin
//					case(dnum)
//					0:
//						begin
//							sel_alu= 1;
//							op[3:0] =  7;
//							load_w= 1;
//							if (alu_zero)
//								begin
//									reset_ir= 1;
//								end
//						
//						end
//					1:
//						begin
//							sel_alu= 1;
//							op[3:0] = 7;
//							ram_en= 1;
//							sel_bus= 0;
//							if (alu_zero)
//								begin
//									reset_ir= 1;
//								end
//							
//						end
//					endcase
//				end
			else if(INCFSZ)
				begin
					case(dnum)
					0:
						begin
							sel_alu= 1;
							op[3:0] =  6;
							load_w= 1;
							if (alu_zero)
								begin
									reset_ir= 1;
								end
						end
					1:
						begin
							sel_alu= 1;
							op[3:0] = 6;
							ram_en= 1;
							sel_bus= 0;
							if (alu_zero)
								begin
									reset_ir= 1;
								end
						end
					endcase
				end
			else if(BTFSC)
				begin
					if (btfsc_btfss_skip_bit)
						begin
							reset_ir= 1;;
						end
				end
			else if(BTFSS)
				begin
					if (btfsc_btfss_skip_bit)
						begin
							reset_ir= 1;
						end
				end	
				
			else if(BRA)
				begin
					reset_ir= 1;
				end
			else if(BRW)
				begin
					reset_ir= 1;
				end	
				
			ns=3;
		end
	endcase

end

    
endmodule