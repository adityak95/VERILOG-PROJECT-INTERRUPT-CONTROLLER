module ic(pclk,prst,pwdata,paddr,prdata,pwr_rd_en,penable,perror,psel,pready,interrupt_active,interrupt_to_service,interrupt_serviced,interrupt_valid);
parameter PERIPHERALS=16;
parameter WIDTH=$clog2(PERIPHERALS);
//parameter for state diagram
parameter S_NO_INTERRUPTS=3'b001;
parameter S_ACTIVE_INTERRUPTS=3'b010;
parameter S_WAITING_FOR_SERVICE=3'b100;



//Directions of APB
input pclk,prst,psel;
input pwr_rd_en,penable;
input [WIDTH-1:0] pwdata,paddr;

output reg [WIDTH-1:0] prdata;
output reg pready,perror;

//INTERRUPT CONTROLLER direction 
input [PERIPHERALS-1:0] interrupt_active;
input interrupt_serviced;
output reg [WIDTH-1:0] interrupt_to_service;
output reg interrupt_valid;

// declare the priority register
reg [WIDTH-1:0] priority_reg [PERIPHERALS-1:0];

//internal registers
reg [2:0]present_state,next_state;
reg [WIDTH-1:0] current_interrupt_priority,interrupt_with_highest_priority;
reg first_check_flag;
integer i;


//modeling of priority register
always@(posedge pclk)begin 
		if(prst)begin 
			prdata=0;
			pready=0;
			perror=0;
			interrupt_to_service=0;
			interrupt_valid=0;
			current_interrupt_priority=0;
			interrupt_with_highest_priority=0;
			first_check_flag=1;
			present_state=S_NO_INTERRUPTS;
			next_state=S_NO_INTERRUPTS;
			for(i=0;i<PERIPHERALS;i=i+1) priority_reg[i]=0;
		end
		else begin
			if(penable)begin
				pready=1;
				if(pwr_rd_en)begin
					priority_reg[paddr]=pwdata;
				end
				else begin 
					prdata=priority_reg[paddr];
				end
			end
		end
end
// Handling of interrupt
always@(posedge pclk)begin 
		if(prst!=1)begin 
			case(present_state)
				S_NO_INTERRUPTS:begin 
					if(interrupt_active!=0)begin 
						next_state=S_ACTIVE_INTERRUPTS;
						first_check_flag=1;
					end
					else begin 
						next_state=S_NO_INTERRUPTS;
					end
				end
				S_ACTIVE_INTERRUPTS:begin 
					for(i=0;i<PERIPHERALS;i=i+1)begin 
						if(interrupt_active[i]==1)begin 
							if(first_check_flag==1)begin 
								current_interrupt_priority=priority_reg[i];
								interrupt_with_highest_priority=i;
								first_check_flag=0;
							end	
							else begin 
								if(current_interrupt_priority<priority_reg[i])begin 
										current_interrupt_priority=priority_reg[i];
										interrupt_with_highest_priority=i;
								end
							end
						end
					end
					interrupt_to_service=interrupt_with_highest_priority;
					interrupt_valid=1;
					next_state=S_WAITING_FOR_SERVICE;
				end
				S_WAITING_FOR_SERVICE:begin 
					if(interrupt_serviced==1)begin 
						interrupt_to_service=0;
						interrupt_valid=0;
						current_interrupt_priority=0;
						interrupt_with_highest_priority=0;
							if(interrupt_active!=0)begin 
								next_state=S_ACTIVE_INTERRUPTS;
								first_check_flag=1;
							end
							else begin 
								next_state=S_NO_INTERRUPTS;
							end
					end
				end
			endcase
		end
end

always@(posedge pclk) begin
		present_state=next_state;
end
endmodule
