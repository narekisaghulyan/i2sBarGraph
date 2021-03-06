module FPGA_TOP_ML505(
			GPIO_COMPLED,	// OUT(5b), W4, S3, N2, E1, C0
			LRCLK_OUT,
			LRCLK_IN,
			SCLK_OUT,
			SCLK_IN,
			STEREO_AUDIO_IN1,
			STEREO_AUDIO_IN2,
			AUDIO_BIT_CLK,			
			
			GPIO_LED,
			
			FPGA_CPU_RESET_B,

			CLK_33MHZ_FPGA
		);
	input   			LRCLK_IN;	    //48KHz = SCLK_OUT/64
	output	reg			LRCLK_OUT;	    //48KHz
	input				SCLK_IN;            //3.072MHz
	output	reg			SCLK_OUT;           //12.288/4MHz = 3.072MHz
	input 				STEREO_AUDIO_IN1;
	input				STEREO_AUDIO_IN2;
	input				AUDIO_BIT_CLK;    //12.288MHz 	
	output  [4:0]           	GPIO_COMPLED;
	output	[7:0]			GPIO_LED;
        input                   	FPGA_CPU_RESET_B;
	input				CLK_33MHZ_FPGA;

	wire						Clock;
	BUFG        clock_buf(	   .I(CLK_33MHZ_FPGA),	.O(Clock));

	wire						SystemReset;
	wire	[2:0]					State;


	/*
         * /-L-\  R
	 *    M1 M2
         *
	 * M0    M3
	 *
	*/
	parameter MicSel  = 0;
	parameter LineSel = MicSel[0] ^ MicSel[1];// 0 = L1, 1 = L2
	parameter ChSel   = MicSel[1]; 		  // 0 = L, 1 = R
	reg     [7:0]					AudioClkDiv;
	wire	[23:0]					DataL, DataR;
	wire						Strobe, StrobeLR;

	reg [8:0]					Volume;
	wire [7:0]					AbsVolume;

	parameter ClockFreq =				33000000;
	
	ButtonParse #(	.Width(		1),
			.DebWidth(	`log2(ClockFreq / 100)),
			.EdgeOutWidth(	1)
		) 
		systemResetParse(	
			.Clock(		Clock),
			.Reset(		1'b0),
			.Enable(	1'b1),
			.In(		FPGA_CPU_RESET_B),
			.Out(		SystemReset));

	i2s_to_parallel #( .width(	24)
		)
		i2s(
		.LR_CK(		LRCLK_IN), 
		.BIT_CK(	SCLK_IN), 
		.DIN(		LineSel ? STEREO_AUDIO_IN2 : STEREO_AUDIO_IN1), 
		.RESET(		SystemReset),
		.DATA_L(	DataL),
		.DATA_R(	DataR),
		.STROBE(	Strobe),
		.STROBE_LR(	StrobeLR)
	);

	LogGraph graph(
		.I(AbsVolume),
		.O(GPIO_LED)
	);

	always @(posedge AUDIO_BIT_CLK) begin
		AudioClkDiv <= AudioClkDiv + 1;
		
		SCLK_OUT <= AudioClkDiv[1];   //  /4
		LRCLK_OUT <= AudioClkDiv[7];  //  /(4*64)
	end

	always @(posedge Strobe) begin
		if (ChSel) begin
			Volume <= {
				DataR[23],
				DataR[22],
				DataR[20],
				DataR[18],
				DataR[16],
				DataR[14],
				DataR[12],
				DataR[10],
				DataR[ 8]};
		end
		else begin
			Volume <= {
				DataL[23],
				DataL[22],
				DataL[20],
				DataL[18],
				DataL[16],
				DataL[14],
				DataL[12],
				DataL[10],
				DataL[ 8]};
		end
	end

	assign AbsVolume = Volume[8] ? -Volume[7:0] : Volume[7:0];
	assign	GPIO_COMPLED	= -1;
endmodule
