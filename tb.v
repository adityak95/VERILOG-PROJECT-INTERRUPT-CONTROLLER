`include"design.v"
module tb;
parameter PERIPHERALS=16;
parameter WIDTH=$clog2(PERIPHERALS);
//parameter for state diagram
parameter S_NO_INTERRUPTS=3'b001;
parameter S_ACTIVE_INTERRUPTS=3'b010;
parameter S_WAITING_FOR_SERVICE=3'b100;

//Directions of APB
reg pclk,prst,psel;
reg pwr_rd_en,penable;
reg [WIDTH-1:0] pwdata,paddr;

wire [WIDTH-1:0] prdata;
wire pready,perror;

//INTERRUPT CONTROLLER direction 
reg [PERIPHERALS-1:0] interrupt_active;
reg interrupt_serviced;
wire [WIDTH-1:0] interrupt_to_service;
wire interrupt_valid;

integer i,x,y;
reg [100*8:0]testcase;

ic dut (.*);

initial begin 
	pclk=0;
	forever #5 pclk=~pclk;
end
initial begin
	x=100;
	prst=1;
	reset();
	repeat(2)@(posedge pclk);
	prst=0;
	@(posedge pclk);
	$value$plusargs("testcase=%s",testcase);
			case(testcase)
				"ASENDING":begin 
					write(i);
				end
				"DESENDING":begin 
					write(PERIPHERALS-1-i);
				end
				"SINGLE_VALUE":begin 
					write(1'b1);
				end
				"RANDOM_VALUES":begin 
					write($urandom_range(0,PERIPHERALS));
				end
				"SEED_VALUES":begin 
					y=1011;
					write($random(y));
				end
			endcase
		
		interrupt_active=$random(x);
		#800;
		$finish;
end

//reset task
task reset();
begin 
	pwr_rd_en=0;
	penable=0;
	pwdata=0;
	paddr=0;
	interrupt_active=0;
	interrupt_serviced=0;
end
endtask

//Write to priority register
task write(input [WIDTH:0]value);
begin 
		for(i=0;i<PERIPHERALS;i=i+1)begin 
			@(posedge pclk);
			pwr_rd_en=1;
			paddr=i;
			pwdata=value;
			penable=1;
			wait (pready==1);
		end
		@(posedge pclk);
		pwr_rd_en=0;
		paddr=0;
		pwdata=0;
		penable=0;
end
endtask

//processor modeling
always@(posedge pclk)begin 
		if(interrupt_to_service !=0)begin 
			#30;  //bcoz processor will not respond immediately it will take some time
			interrupt_active[interrupt_to_service]=0;
			interrupt_serviced=1;
			@(posedge pclk);
			interrupt_serviced=0;
		end
end

endmodule
