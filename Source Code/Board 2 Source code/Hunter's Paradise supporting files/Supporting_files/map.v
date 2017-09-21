//	map.v - World map logic for rojobot systems
//	
//	Copyright Roy Kravitz, 2006-2015, 2016
//
//	Created By:			Roy Kravitz
//	Last Modified:		11-Oct-2014 (RK)
//	
//	Revision History:
//	-----------------
//	Sep-2006		RK		Created this module
//	Jan-2006		RK		Changed map addressing to 128 x 128
//	Jan-2006		RK		Modified to use world map generated by CoreGen
//	Oct-2009		RK		Minor changes (comments only) for conversion to ECE 510
//	Oct-2011		RK		Minor changes (comments only)
//	Oct-2012		RK		Modified for kcpsm6 and Nexys 3
//	Jan-2014		RK		Cleaned up the formatting.  No functional changes	
//	Oct-2014		RK		Checked for Nexys4 and Vivado compatibility.  No changes		
//	
//	Description
//	-----------
//	This module implements the world map for the rojobot to exist in.  It
//	interfaces with the world simulator (implemented in a Picoblaze) and with
//	the VGA logic.
//	
//	The interface to the BOTSIM is through several registers 
//	(produced in world_if.v) that interrogate the map logic (in this module)
//	to find the type of location that Rojobot is on and the sensor readings
//	for the locations around the Rojobot.
//	
//	The interface to the video logic is simpler in that it only returns
//	the value of the location being displayed to the video logic.
//	
//	The major component of map.v is a 16K dual port RAM implemented in two
//	block RAMS.  This RAM is addressed by the simulator
//	with a 7-bit column address and a 7-bit row address.
//
// 	The world map is 128 (cols) by 128 (rows)with each location on the world map
// 	roughly convering 16 (4 x 4) pixels on the 640 x 480 display.  Each location is represented by
// 	two pixels with the following meaning:
//		00 - "ground"   	This is just the background.  No obstruction, no black line
//		01 - "black line"	This location has a black line painted on it
//		10 - "obstruction"	There is an obstruction (like a wall) at this location
//		11-  "reserved"		This is nothing yet so should be treated like "ground"
//
//////////

module map (

  // interface to external world emulator
  input 		[7:0]	wrld_col_addr,	// column address of world map location
  input 		[7:0]	wrld_row_addr,	// row address of world map location	
  output		[1:0]	wrld_loc_info,	// map value for location [row_addr, col_addr]

  // interface to the video logic
  input 		[9:0]	vid_row,		// video logic row address
  vid_col,		// video logic column address
  output		[7:0]	vid_pixel_out,	// pixel (location) value

  // interface to the system
  input				clk,			// system clock
  reset,			// system reset
  input [5:0]         minutes					
);

  localparam
  GND		= 2'b00,	// ground - no obstruction, no black line
  BLKL	= 2'b01,	// black line
  OBSTR	= 2'b10,	// obstruction - either border wall or barrier
  RSVD	= 2'b00;	// reserved - treat as "ground" for now

  reg [9:0] offset;
  reg [31:0] count;
  reg en;		

  reg 	[13:0] 	wrld_addr, vid_addr;	// dual port RAM addresses for 
  // external world emulator and video logic

  reg [5:0] offset_incrementer=1;
  // Instantiate the world map ROM (generated by Xilinx Core Gnerator
  //world_map MAP (
  //	.clka(clk),
  //	.addra(wrld_addr),
  //	.douta(wrld_loc_info),
  //	.clkb(clk),
  //	.addrb(vid_addr),
  //	.doutb(vid_pixel_out)
  //);	
  reg [16:0] addr;
  reg [7:0] data_1, data_2;
  reg image_count=0;

  background_512x240 backgrnd
  (
    .clka(clk),
    .addra(addr),
    .douta(vid_pixel_out)
  );	




  // implement the address latches
  always @(posedge clk) begin
    //remove when scrollling
    //    offset <= 0;

    wrld_addr <= {wrld_row_addr[6:0], wrld_col_addr[6:0]};
    vid_addr <= {vid_row[6:0], (vid_col[6:0]+offset)};
    addr <= {vid_row[7:0], vid_col[8:0]+offset[8:0]}; 

  end

  // scrolling logic
  always@(posedge clk)
    begin


      if(count==20000000)
        begin
          en <= 1'b1;
          count <= 0;
          if(minutes==0)
            begin
              offset_incrementer<=1;
            end
          else if (minutes==1)
            begin
              offset_incrementer<=4;
            end
          else if(minutes==2)
            begin
              offset_incrementer<=8;
            end
          else if(minutes==3)
            begin
              offset_incrementer<=16;
            end
          else
            begin
              offset_incrementer<=offset_incrementer;
            end
          if(offset <= 511)
            offset <= offset + offset_incrementer;
          else
            offset <= 0;
        end

      else
        begin
          en <= 1'b0;
          count <= count + 1'b1;
        end
    end
endmodule
