-------------------------------------------------------------------------------
--  Department of Computer Engineering and Communications
--  Author: LPRS2  <lprs2@rt-rk.com>
--
--  Module Name: top
--
--  Description:
--
--    Simple test for VGA control
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity top is
  generic (
    RES_TYPE             : natural := 1;
    TEXT_MEM_DATA_WIDTH  : natural := 6;
    GRAPH_MEM_DATA_WIDTH : natural := 32;
	 START_ROW_POS			 : natural := 12;
	 START_COL_POS			 : natural := 12;
	 SQUARE_DIM				 : natural := 10
    );
  port (
    clk_i          : in  std_logic;
    reset_n_i      : in  std_logic;
	 
	 direct_mode_i  : in	 std_logic;
	 display_mode_i : in  std_logic_vector(1 downto 0);
	 
	 tst_left_i		 : in	 std_logic;
	 tst_right_i	 : in  std_logic;
	 tst_up_i		 : in  std_logic;
	 tst_down_i		 : in  std_logic;
	 
    -- vga
    vga_hsync_o    : out std_logic;
    vga_vsync_o    : out std_logic;
    blank_o        : out std_logic;
    pix_clock_o    : out std_logic;
    psave_o        : out std_logic;
    sync_o         : out std_logic;
    red_o          : out std_logic_vector(7 downto 0);
    green_o        : out std_logic_vector(7 downto 0);
    blue_o         : out std_logic_vector(7 downto 0)
   );
end top;

architecture rtl of top is

  constant RES_NUM : natural := 6;

  type t_param_array is array (0 to RES_NUM-1) of natural;
  
  constant H_RES_ARRAY           : t_param_array := ( 0 => 64, 1 => 640,  2 => 800,  3 => 1024,  4 => 1152,  5 => 1280,  others => 0 );
  constant V_RES_ARRAY           : t_param_array := ( 0 => 48, 1 => 480,  2 => 600,  3 => 768,   4 => 864,   5 => 1024,  others => 0 );
  constant MEM_ADDR_WIDTH_ARRAY  : t_param_array := ( 0 => 12, 1 => 14,   2 => 13,   3 => 14,    4 => 14,    5 => 15,    others => 0 );
  constant MEM_SIZE_ARRAY        : t_param_array := ( 0 => 48, 1 => 4800, 2 => 7500, 3 => 12576, 4 => 15552, 5 => 20480, others => 0 ); 
  
  constant H_RES          : natural := H_RES_ARRAY(RES_TYPE);
  constant V_RES          : natural := V_RES_ARRAY(RES_TYPE);
  constant MEM_ADDR_WIDTH : natural := MEM_ADDR_WIDTH_ARRAY(RES_TYPE);
  constant MEM_SIZE       : natural := MEM_SIZE_ARRAY(RES_TYPE);

  component vga_top is 
    generic (
      H_RES                : natural := 640;
      V_RES                : natural := 480;
      MEM_ADDR_WIDTH       : natural := 32;
      GRAPH_MEM_ADDR_WIDTH : natural := 32;
      TEXT_MEM_DATA_WIDTH  : natural := 32;
      GRAPH_MEM_DATA_WIDTH : natural := 32;
      RES_TYPE             : integer := 1;
      MEM_SIZE             : natural := 4800
      );
    port (
      clk_i               : in  std_logic;
      reset_n_i           : in  std_logic;
      --
      direct_mode_i       : in  std_logic; -- 0 - text and graphics interface mode, 1 - direct mode (direct force RGB component)
      dir_red_i           : in  std_logic_vector(7 downto 0);
      dir_green_i         : in  std_logic_vector(7 downto 0);
      dir_blue_i          : in  std_logic_vector(7 downto 0);
      dir_pixel_column_o  : out std_logic_vector(10 downto 0);
      dir_pixel_row_o     : out std_logic_vector(10 downto 0);
      -- mode interface
      display_mode_i      : in  std_logic_vector(1 downto 0);  -- 00 - text mode, 01 - graphics mode, 01 - text & graphics
      -- text mode interface
      text_addr_i         : in  std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
      text_data_i         : in  std_logic_vector(TEXT_MEM_DATA_WIDTH-1 downto 0);
      text_we_i           : in  std_logic;
      -- graphics mode interface
      graph_addr_i        : in  std_logic_vector(GRAPH_MEM_ADDR_WIDTH-1 downto 0);
      graph_data_i        : in  std_logic_vector(GRAPH_MEM_DATA_WIDTH-1 downto 0);
      graph_we_i          : in  std_logic;
      --
      font_size_i         : in  std_logic_vector(3 downto 0);
      show_frame_i        : in  std_logic;
      foreground_color_i  : in  std_logic_vector(23 downto 0);
      background_color_i  : in  std_logic_vector(23 downto 0);
      frame_color_i       : in  std_logic_vector(23 downto 0);
      -- vga
      vga_hsync_o         : out std_logic;
      vga_vsync_o         : out std_logic;
      blank_o             : out std_logic;
      pix_clock_o         : out std_logic;
      vga_rst_n_o         : out std_logic;
      psave_o             : out std_logic;
      sync_o              : out std_logic;
      red_o               : out std_logic_vector(7 downto 0);
      green_o             : out std_logic_vector(7 downto 0);
      blue_o              : out std_logic_vector(7 downto 0)
    );
  end component;
  
  component ODDR2
  generic(
   DDR_ALIGNMENT : string := "NONE";
   INIT          : bit    := '0';
   SRTYPE        : string := "SYNC"
   );
  port(
    Q           : out std_ulogic;
    C0          : in  std_ulogic;
    C1          : in  std_ulogic;
    CE          : in  std_ulogic := 'H';
    D0          : in  std_ulogic;
    D1          : in  std_ulogic;
    R           : in  std_ulogic := 'L';
    S           : in  std_ulogic := 'L'
  );
  end component;
  
  component reg
	generic(
		WIDTH    : positive := 1;
		RST_INIT : integer := 0
	);
	port(
		i_clk  : in  std_logic;
		in_rst : in  std_logic;
		i_d    : in  std_logic_vector(WIDTH-1 downto 0);
		o_q    : out std_logic_vector(WIDTH-1 downto 0)
	);
	end component;
  
  
  constant update_period     : std_logic_vector(31 downto 0) := conv_std_logic_vector(1, 32);
  
  constant GRAPH_MEM_ADDR_WIDTH : natural := MEM_ADDR_WIDTH + 6;-- graphics addres is scales with minumum char size 8*8 log2(64) = 6
  
  type ADDR_ARRAY is array (0 to 5) of std_logic_vector(5 downto 0);
  signal text_to_screen : ADDR_ARRAY := ("00"&x"1", "00"&x"2", "00"&x"3", "00"&x"4", "00"&x"5", "00"&x"6");
  
  -- text
  signal message_lenght      : std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
  signal graphics_lenght     : std_logic_vector(GRAPH_MEM_ADDR_WIDTH-1 downto 0);
  
  signal direct_mode         : std_logic;
  --
  signal font_size           : std_logic_vector(3 downto 0);
  signal show_frame          : std_logic;
  signal display_mode        : std_logic_vector(1 downto 0);  -- 01 - text mode, 10 - graphics mode, 11 - text & graphics
  signal foreground_color    : std_logic_vector(23 downto 0);
  signal background_color    : std_logic_vector(23 downto 0);
  signal frame_color         : std_logic_vector(23 downto 0);

  signal char_we             : std_logic;
  signal char_address        : std_logic_vector(MEM_ADDR_WIDTH-1 downto 0);
  signal char_value          : std_logic_vector(5 downto 0);

  signal pixel_address       : std_logic_vector(GRAPH_MEM_ADDR_WIDTH-1 downto 0);
  signal pixel_value         : std_logic_vector(GRAPH_MEM_DATA_WIDTH-1 downto 0);
  signal pixel_we            : std_logic;

  signal pix_clock_s         : std_logic;
  signal vga_rst_n_s         : std_logic;
  signal pix_clock_n         : std_logic;
   
  signal dir_red             : std_logic_vector(7 downto 0);
  signal dir_green           : std_logic_vector(7 downto 0);
  signal dir_blue            : std_logic_vector(7 downto 0);
  signal dir_pixel_column    : std_logic_vector(10 downto 0);
  signal dir_pixel_row       : std_logic_vector(10 downto 0);
  
  signal txt_addr_reg		: std_logic_vector(MEM_ADDR_WIDTH - 1 downto 0);
  signal next_txt_addr		: std_logic_vector(MEM_ADDR_WIDTH - 1 downto 0);
  signal graph_addr_reg		: std_logic_vector(GRAPH_MEM_ADDR_WIDTH - 1 downto 0);
  signal next_graph_addr	: std_logic_vector(GRAPH_MEM_ADDR_WIDTH - 1 downto 0);
  signal pixel_we_s 			: std_logic;
  
  signal row_cnt_reg 		: std_logic_vector(10 downto 0);
  signal next_row_cnt		: std_logic_vector(10 downto 0);
  signal col_cnt_reg			: std_logic_vector(4 downto 0);
  signal next_col_cnt		: std_logic_vector(4 downto 0);
  
  signal row_cnt_s 			: std_logic;
  
  signal clk_dev_reg			: std_logic_vector(21 downto 0);
  signal next_clk_dev		: std_logic_vector(21 downto 0);
  signal clk_dev				: std_logic;
  

  
  signal next_text_hor		: std_logic_vector(11 downto 0);
  signal next_text_hor_tmp	: std_logic_vector(11 downto 0);
  signal text_hor_reg		: std_logic_vector(11 downto 0);
  signal text_hor_add		: std_logic_vector(11 downto 0);
  signal text_hor_sub		: std_logic_vector(11 downto 0);
  signal text_hor_add_bound		: std_logic_vector(11 downto 0);
  signal text_hor_sub_bound		: std_logic_vector(11 downto 0);
  
  signal next_text_ver		: std_logic_vector(11 downto 0);
  signal next_text_ver_tmp	: std_logic_vector(11 downto 0);
  signal text_ver_reg		: std_logic_vector(11 downto 0);
  signal text_ver_add		: std_logic_vector(11 downto 0);
  signal text_ver_sub		: std_logic_vector(11 downto 0);
  signal text_ver_add_bound		: std_logic_vector(11 downto 0);
  signal text_ver_sub_bound		: std_logic_vector(11 downto 0);
  
  signal right_shift_reg 	: std_logic_vector(11 downto 0);
  signal next_right_shift	: std_logic_vector(11 downto 0);
  signal next_right_shift_tmp	: std_logic_vector(11 downto 0);
  signal left_shift_reg		: std_logic_vector(11 downto 0);
  signal next_left_shift	: std_logic_vector(11 downto 0);
  signal next_left_shift_tmp	: std_logic_vector(11 downto 0);
  
  signal hor_graph_reg 			: std_logic_vector(11 downto 0);
  signal next_hor_graph			: std_logic_vector(11 downto 0);
  signal next_hor_graph_tmp	: std_logic_vector(11 downto 0);
  signal next_hor_graph_add		: std_logic_vector(11 downto 0);
  signal next_hor_graph_sub	: std_logic_vector(11 downto 0);
  signal hor_graph_add_bound	: std_logic_vector(11 downto 0);
  signal hor_graph_sub_bound	: std_logic_vector(11 downto 0);
  
  signal arr_ind_reg			: std_logic_vector(5 downto 0);
  signal next_arr_ind		: std_logic_vector(5 downto 0);
  signal writing_text_on	: std_logic;

  signal next_graph_clk_div: std_logic_vector(4 downto 0);
  signal graph_clk_div_reg : std_logic_vector(4 downto 0);
  signal pix_clock_s_32		: std_logic;
  signal pixel_value_tmp	: std_logic_vector(31 downto 0) := (others => '0');

begin

  -- calculate message lenght from font size
  message_lenght <= conv_std_logic_vector(MEM_SIZE/64, MEM_ADDR_WIDTH)when (font_size = 3) else -- note: some resolution with font size (32, 64)  give non integer message lenght (like 480x640 on 64 pixel font size) 480/64= 7.5
                    conv_std_logic_vector(MEM_SIZE/16, MEM_ADDR_WIDTH)when (font_size = 2) else
                    conv_std_logic_vector(MEM_SIZE/4 , MEM_ADDR_WIDTH)when (font_size = 1) else
                    conv_std_logic_vector(MEM_SIZE   , MEM_ADDR_WIDTH);
  
  graphics_lenght <= conv_std_logic_vector(MEM_SIZE*8*8, GRAPH_MEM_ADDR_WIDTH);
  
  -- removed to inputs pin
--  direct_mode <= '1';
--  display_mode     <= "10";  -- 01 - text mode, 10 - graphics mode, 11 - text & graphics

  direct_mode <= direct_mode_i;
  display_mode <= display_mode_i;
  
  font_size        <= x"1";
  show_frame       <= '1';
  foreground_color <= x"FFFFFF";
  background_color <= x"000000";
  frame_color      <= x"FF0000";

  clk5m_inst : ODDR2
  generic map(
    DDR_ALIGNMENT => "NONE",  -- Sets output alignment to "NONE","C0", "C1" 
    INIT => '0',              -- Sets initial state of the Q output to '0' or '1'
    SRTYPE => "SYNC"          -- Specifies "SYNC" or "ASYNC" set/reset
  )
  port map (
    Q  => pix_clock_o,       -- 1-bit output data
    C0 => pix_clock_s,       -- 1-bit clock input
    C1 => pix_clock_n,       -- 1-bit clock input
    CE => '1',               -- 1-bit clock enable input
    D0 => '1',               -- 1-bit data input (associated with C0)
    D1 => '0',               -- 1-bit data input (associated with C1)
    R  => '0',               -- 1-bit reset input
    S  => '0'                -- 1-bit set input
  );
  pix_clock_n <= not(pix_clock_s);

  -- component instantiation
  vga_top_i: vga_top
  generic map(
    RES_TYPE             => RES_TYPE,
    H_RES                => H_RES,
    V_RES                => V_RES,
    MEM_ADDR_WIDTH       => MEM_ADDR_WIDTH,
    GRAPH_MEM_ADDR_WIDTH => GRAPH_MEM_ADDR_WIDTH,
    TEXT_MEM_DATA_WIDTH  => TEXT_MEM_DATA_WIDTH,
    GRAPH_MEM_DATA_WIDTH => GRAPH_MEM_DATA_WIDTH,
    MEM_SIZE             => MEM_SIZE
  )
  port map(
    clk_i              => clk_i,
    reset_n_i          => reset_n_i,
    --
    direct_mode_i      => direct_mode,
    dir_red_i          => dir_red,
    dir_green_i        => dir_green,
    dir_blue_i         => dir_blue,
    dir_pixel_column_o => dir_pixel_column,
    dir_pixel_row_o    => dir_pixel_row,
    -- cfg
    display_mode_i     => display_mode,  -- 01 - text mode, 10 - graphics mode, 11 - text & graphics
    -- text mode interface
    text_addr_i        => char_address,
    text_data_i        => char_value,
    text_we_i          => char_we,
    -- graphics mode interface
    graph_addr_i       => pixel_address,
    graph_data_i       => pixel_value,
    graph_we_i         => pixel_we,
    -- cfg
    font_size_i        => font_size,
    show_frame_i       => show_frame,
    foreground_color_i => foreground_color,
    background_color_i => background_color,
    frame_color_i      => frame_color,
    -- vga
    vga_hsync_o        => vga_hsync_o,
    vga_vsync_o        => vga_vsync_o,
    blank_o            => blank_o,
    pix_clock_o        => pix_clock_s,
    vga_rst_n_o        => vga_rst_n_s,
    psave_o            => psave_o,
    sync_o             => sync_o,
    red_o              => red_o,
    green_o            => green_o,
    blue_o             => blue_o     
  );
  
  next_txt_addr <= txt_addr_reg + 1 when txt_addr_reg < (V_RES / 16) * (H_RES / 16)--1200
  else conv_std_logic_vector((V_RES / 16) * (H_RES / 16) + 1, MEM_ADDR_WIDTH);
  
  txt_addr_cnt: reg
	generic map(
		WIDTH    => MEM_ADDR_WIDTH,
		RST_INIT => 0
	)
	port map(
		i_clk  => pix_clock_s,
		in_rst => vga_rst_n_s and tst_left_i and tst_right_i and tst_up_i and tst_down_i,
		i_d    => next_txt_addr,
		o_q    => txt_addr_reg
	);
	
	next_graph_addr <= graph_addr_reg + 1 when graph_addr_reg < 9600
	else conv_std_logic_vector(9600, GRAPH_MEM_ADDR_WIDTH);
	
	graph_addr_cnt: reg
	generic map(
		WIDTH    => GRAPH_MEM_ADDR_WIDTH,
		RST_INIT => 0
	)
	port map(
		i_clk  => pix_clock_s,
		in_rst => vga_rst_n_s and tst_left_i and tst_right_i,
		i_d    => next_graph_addr,
		o_q    => graph_addr_reg
	);
	
		--usporava pix_clock_s 32 puta, zbog indeksiranja bita
	graph_clock_div: reg
	generic map(
		WIDTH    => 5,
		RST_INIT => 0
	)
	port map(
		i_clk  => pix_clock_s,
		in_rst => vga_rst_n_s and tst_left_i and tst_right_i,
		i_d    => next_graph_clk_div,
		o_q    => graph_clk_div_reg
	);
	
	next_graph_clk_div <= graph_clk_div_reg + 1; 
	
	pix_clock_s_32 <= '1' when graph_clk_div_reg = 31
	else '0';

	
	next_col_cnt <= col_cnt_reg + 1 when col_cnt_reg < 19
	else (others => '0') when row_cnt_reg < 479
	else conv_std_logic_vector(20, 5);
	
	graph_col_cnt: reg
	generic map(
		WIDTH    => 5,
		RST_INIT => 0
	)
	port map(
		i_clk  => pix_clock_s,
		in_rst => vga_rst_n_s and tst_left_i and tst_right_i,
		i_d    => next_col_cnt,
		o_q    => col_cnt_reg
	);
	
	next_row_cnt <= row_cnt_reg + 1 when row_cnt_reg < 479
	else conv_std_logic_vector(480, 11);
	
	row_cnt_s <= '1' when col_cnt_reg = 19
	else '0';
	
	graph_row_cnt: reg
	generic map(
		WIDTH    => 11,
		RST_INIT => 0
	)
	port map(
		i_clk  => row_cnt_s,
		in_rst => vga_rst_n_s and tst_left_i and tst_right_i,
		i_d    => next_row_cnt,
		o_q    => row_cnt_reg
	);
	
	
	--svakih 100ms
	next_clk_dev <= clk_dev_reg + 1 when clk_dev_reg < 10000000
	else (others => '0');
	
	clk_devide_reg : reg
	generic map(
		WIDTH    => 22,
		RST_INIT => 0
	)
	port map(
		i_clk  => pix_clock_s_32,
		in_rst => reset_n_i,
		i_d    => next_clk_dev,
		o_q    => clk_dev_reg
	);
	
	clk_dev <= '1' when clk_dev_reg = 10000000
	else '0';
	
	
-----------------------------------------------------------------------------------------------
--													POMERANJE TEKSTA													--
-----------------------------------------------------------------------------------------------

--Potrebna su dva registra, jedan za horizontalnu, a drugi za vertikalnu poziciju.
--Njihova reset vrednost zadaje se iz generic-a.
--Uveæavaju se za 1 (ili smanjuju) pritiskom na tastere up, down, left i right.
--Ne sme se dozvoliti da vrednost bude manja od 0, niti veæa od 39 za horizontalu i 29 za vertikalu, uzevsi u obzir poslednji karakter.
	
	--registar pomeraja teksta horizontalno
	text_hor_pos : reg
	generic map(
		WIDTH    => 12,
		RST_INIT => START_COL_POS
	)
	port map(
		i_clk  => clk_dev,
		in_rst => reset_n_i,
		i_d    => next_text_hor,
		o_q    => text_hor_reg
	);
	
	text_hor_add <= text_hor_reg + 1 when tst_right_i = '0'
	else text_hor_reg;
	
		--provera da li je poslednji znak na desnom kraju ekrana
	text_hor_add_bound <= text_hor_add when text_hor_reg + 6 < H_RES / 16 - 1
	else text_hor_reg;
	
	text_hor_sub <= text_hor_reg - 1 when tst_left_i = '0'
	else text_hor_reg;
	
		--provera da li je prvi znak na levom kraju ekrana
	text_hor_sub_bound <= text_hor_sub when text_hor_reg > 0
	else text_hor_reg;
	
	next_text_hor_tmp <= text_hor_add_bound when tst_right_i = '0'
	else 				  		text_hor_sub_bound when tst_left_i = '0'
	else	text_hor_reg;
	
		--provera da li je u text modu
	next_text_hor <= next_text_hor_tmp when display_mode = "01"
	else 	text_hor_reg;
	
	
	--registar pomeraja teksta vertikalno
	text_row_pos : reg
	generic map(
		WIDTH    => 12,
		RST_INIT => START_ROW_POS
	)
	port map(
		i_clk  => clk_dev,
		in_rst => reset_n_i,
		i_d    => next_text_ver,
		o_q    => text_ver_reg
	);
	
	text_ver_add <= text_ver_reg + 1 when tst_down_i = '0'
	else text_ver_reg;
	
		--provera da li je tekst na donjem kraju ekrana
	text_ver_add_bound <= text_ver_add when text_ver_reg < V_RES / 16 - 1
	else text_ver_reg;
	
	text_ver_sub <= text_ver_reg - 1 when tst_up_i = '0'
	else text_ver_reg;
	
		--provera da li je tekst na gornjem kraju ekrana
	text_ver_sub_bound <= text_ver_sub when text_ver_reg > 0
	else text_ver_reg;
	
	next_text_ver_tmp <= text_ver_add_bound when tst_down_i = '0'
	else 				  text_ver_sub_bound when tst_up_i = '0'
	else	text_ver_reg;
	
		--provera da li je u text modu
	next_text_ver <= next_text_ver_tmp when display_mode = "01"
	else 	text_ver_reg;
	
-----------------------------------------------------------------------------------------------
--													POMERANJE KVADRATA												--
-----------------------------------------------------------------------------------------------
	
	--registar horizontalne pozicije kvadrata
	hor_graphic_reg : reg
	generic map(
		WIDTH    => 12,
		RST_INIT => H_RES / 2 - SQUARE_DIM / 2
	)
	port map(
		i_clk  => clk_dev,
		in_rst => reset_n_i,
		i_d    => next_hor_graph,
		o_q    => hor_graph_reg
	);
	
	next_hor_graph_add <= hor_graph_reg + 8 when tst_right_i = '0'
	else hor_graph_reg;
	
		--provera da li se desna ivica kvadrata nalazi u blizini desne ivice ekrana
	hor_graph_add_bound <= next_hor_graph_add when next_hor_graph_add + SQUARE_DIM < H_RES
	else hor_graph_reg;
	
	next_hor_graph_sub <= hor_graph_reg - 8 when tst_left_i = '0'
	else hor_graph_reg;
	
		--provera da li se leva ivica kvadrata nalazi u blizini leve ivice ekrana
	hor_graph_sub_bound <= next_hor_graph_sub when next_hor_graph_sub > 0
	else hor_graph_reg;
	
	next_hor_graph_tmp <= next_hor_graph_add when tst_right_i = '0'
	else						 next_hor_graph_sub when tst_left_i  = '0'
	else hor_graph_reg;
	
	next_hor_graph <= next_hor_graph_tmp when display_mode = "10"
	else hor_graph_reg;
	
	
--	--registar desnog pomeranja kvadrata
--	next_right_shift_tmp <= right_shift_reg + 1 when tst_right_i = '1'
--	else 	right_shift_reg;
--	
--		--provera da li je dostigao maksimum
--	
--		--provera da li je u graphic modu
--	next_right_shift <= next_right_shift_tmp when display_mode = "10"
--	else right_shift_reg;
--	
--	right_sh_reg : reg
--	generic map(
--		WIDTH    => 12,
--		RST_INIT => 0
--	)
--	port map(
--		i_clk  => clk_dev,
--		in_rst => reset_n_i,
--		i_d    => next_right_shift,
--		o_q    => right_shift_reg
--	);
--	
--	--registar levog pomeranja kvadrata
--	next_left_shift_tmp <= left_shift_reg + 1 when tst_left_i = '1'
--	else 	left_shift_reg;
--	
--	--provera da li je u graphic modu
--	next_left_shift <= next_left_shift_tmp when display_mode = "10"
--	else left_shift_reg;
--	
--	left_sh_reg : reg
--	generic map(
--		WIDTH    => 12,
--		RST_INIT => 0
--	)
--	port map(
--		i_clk  => clk_dev,
--		in_rst => reset_n_i,
--		i_d    => next_left_shift,
--		o_q    => left_shift_reg
--	);

--FFFFFF
--FFFF00
--00FFFF
--00FF00
--FF00FF
--FF0000
--0000FF
--000000
  
  -- na osnovu signala iz vga_top modula dir_pixel_column i dir_pixel_row realizovati logiku koja genereise
  --dir_red
  --dir_green
  --dir_blue
--	dir_red <= 	x"FF"	when dir_pixel_column >=   0 	and dir_pixel_column <	80
--			else 		x"FF" when dir_pixel_column >=  80 	and dir_pixel_column < 160
--			else 		x"00" when dir_pixel_column >= 160 	and dir_pixel_column < 240
--			else 		x"00" when dir_pixel_column >= 240 	and dir_pixel_column < 320
--			else 		x"FF" when dir_pixel_column >= 320 	and dir_pixel_column < 400
--			else 		x"FF" when dir_pixel_column >= 400 	and dir_pixel_column < 480
--			else 		x"00" when dir_pixel_column >= 480 	and dir_pixel_column < 560
--			else 		x"00";
--		
--	dir_green <= 	x"FF"	when dir_pixel_column >=   0 	and dir_pixel_column <	80
--			else 		x"FF" when dir_pixel_column >=  80 	and dir_pixel_column < 160
--			else 		x"FF" when dir_pixel_column >= 160 	and dir_pixel_column < 240
--			else 		x"FF" when dir_pixel_column >= 240 	and dir_pixel_column < 320
--			else 		x"00" when dir_pixel_column >= 320 	and dir_pixel_column < 400
--			else 		x"00" when dir_pixel_column >= 400 	and dir_pixel_column < 480
--			else 		x"00" when dir_pixel_column >= 480 	and dir_pixel_column < 560
--			else 		x"00";
--
--	dir_blue <= 	x"FF"	when dir_pixel_column >=   0 	and dir_pixel_column <	80
--			else 		x"00" when dir_pixel_column >=  80 	and dir_pixel_column < 160
--			else 		x"FF" when dir_pixel_column >= 160 	and dir_pixel_column < 240
--			else 		x"00" when dir_pixel_column >= 240 	and dir_pixel_column < 320
--			else 		x"FF" when dir_pixel_column >= 320 	and dir_pixel_column < 400
--			else 		x"00" when dir_pixel_column >= 400 	and dir_pixel_column < 480
--			else 		x"FF" when dir_pixel_column >= 480 	and dir_pixel_column < 560
--			else 		x"00";	
		
	dir_red <= 		x"FF"	when dir_pixel_column >=				  0	and dir_pixel_column < 		 H_RES / 8
			else 		x"FF" when dir_pixel_column >=	   H_RES / 8	and dir_pixel_column < 		 H_RES / 4
			else 		x"00" when dir_pixel_column >= 		H_RES / 4	and dir_pixel_column < 3 * (H_RES / 8)
			else 		x"00" when dir_pixel_column >= 3 * (H_RES / 8)	and dir_pixel_column < 		 H_RES / 2
			else 		x"FF" when dir_pixel_column >= 		H_RES / 2 	and dir_pixel_column < 5 * (H_RES / 8)
			else 		x"FF" when dir_pixel_column >= 5 * (H_RES / 8) 	and dir_pixel_column < 3 * (H_RES / 4)
			else 		x"00" when dir_pixel_column >= 3 * (H_RES / 4) 	and dir_pixel_column < 7 * (H_RES / 8)
			else 		x"00";
		
	dir_green <= 	x"FF"	when dir_pixel_column >=   			  0 	and dir_pixel_column < 		 H_RES / 8
			else 		x"FF" when dir_pixel_column >=	   H_RES / 8 	and dir_pixel_column < 		 H_RES / 4
			else 		x"FF" when dir_pixel_column >= 		H_RES / 4 	and dir_pixel_column < 3 * (H_RES / 8)
			else 		x"FF" when dir_pixel_column >= 3 * (H_RES / 8) 	and dir_pixel_column < 		 H_RES / 2
			else 		x"00" when dir_pixel_column >= 		H_RES / 2 	and dir_pixel_column < 5 * (H_RES / 8)
			else 		x"00" when dir_pixel_column >= 5 * (H_RES / 8) 	and dir_pixel_column < 3 * (H_RES / 4)
			else 		x"00" when dir_pixel_column >= 3 * (H_RES / 4) 	and dir_pixel_column < 7 * (H_RES / 8)
			else 		x"00";

	dir_blue <= 	x"FF"	when dir_pixel_column >=   			  0 	and dir_pixel_column < 		 H_RES / 8
			else 		x"00" when dir_pixel_column >=	   H_RES / 8 	and dir_pixel_column < 		 H_RES / 4
			else 		x"FF" when dir_pixel_column >= 		H_RES / 4 	and dir_pixel_column < 3 * (H_RES / 8)
			else 		x"00" when dir_pixel_column >= 3 * (H_RES / 8) 	and dir_pixel_column < 		 H_RES / 2
			else 		x"FF" when dir_pixel_column >= 		H_RES / 2 	and dir_pixel_column < 5 * (H_RES / 8)
			else 		x"00" when dir_pixel_column >= 5 * (H_RES / 8) 	and dir_pixel_column < 3 * (H_RES / 4)
			else 		x"FF" when dir_pixel_column >= 3 * (H_RES / 4) 	and dir_pixel_column < 7 * (H_RES / 8)
			else 		x"00";			
		
		
  -- koristeci signale realizovati logiku koja pise po TXT_MEM
  --char_address
  --char_value
  --char_we
  
  --registar za indeksiranje niza
  array_index_register : reg
	generic map(
		WIDTH    => 6,
		RST_INIT => 0
	)
	port map(
		i_clk  => pix_clock_s,
		in_rst => vga_rst_n_s and tst_left_i and tst_down_i and tst_up_i and tst_down_i,
		i_d    => next_arr_ind,
		o_q    => arr_ind_reg
	);
	
	next_arr_ind <= arr_ind_reg + 1 when writing_text_on = '1'
	else (others => '0');
	
--	writing_text_on <= '1' when txt_addr_reg < (START_ROW_POS * H_RES / 16) + START_COL_POS + conv_integer(text_shift_reg)
--							 and txt_addr_reg > (START_ROW_POS * H_RES / 16) + START_COL_POS + conv_integer(text_shift_reg) + 6
--	else '0';
	
	writing_text_on <= '0' when (txt_addr_reg < conv_integer(text_ver_reg) * (H_RES / 16) + conv_integer(text_hor_reg))
									and (txt_addr_reg > conv_integer(text_ver_reg) * (H_RES / 16) + conv_integer(text_hor_reg) + 6)
	else '1';

--	writing_text_on <= '0' when txt_addr_reg < (conv_integer(12) * (H_RES / 16)) + conv_integer(12)
--									and txt_addr_reg > (conv_integer(12) * (H_RES / 16)) + conv_integer(12) + 6
--	else '1';

  
  
  char_address <= txt_addr_reg;-- + conv_integer(text_shift_reg);
--  char_value <= text_to_screen(conv_integer(arr_ind_reg)) when writing_text_on = '1'
--  else "100000";

  char_value <= text_to_screen(conv_integer(txt_addr_reg)) when txt_addr_reg < 6
  else "100000";
  
  char_we <= '1' when txt_addr_reg < (H_RES / 16) * (V_RES / 16)--1200
  else '0';
  
  
  -- koristeci signale realizovati logiku koja pise po GRAPH_MEM
  --pixel_address
  --pixel_value
  --pixel_we
  
--  pixel_value <= (others => '1') when	dir_pixel_row 		>	 79
--											and	dir_pixel_row 		< 	160
--											and	dir_pixel_column	>	159
--											and	dir_pixel_column	<	480
--	else (others => '0');
--	
--  pixel_value <= (others => '1') when	row_cnt_reg 		>=		 V_RES / 6  --80
--											and	row_cnt_reg 		<= 5 * V_RES / 6  - 1 --399
--											and	col_cnt_reg			>=	(H_RES / 32) / 4  --5
--											and	col_cnt_reg			<=	(H_RES / 32) / 4 - 1 --14
--	else (others => '0');
	pixel_we <= '1' when row_cnt_reg < V_RES - 1
		else '0';
		
--	pixel_value <= (others => '0') when row_cnt_reg < V_RES / 2 - SQUARE_DIM / 2
--	else (others => '0') when row_cnt_reg > V_RES / 2 + SQUARE_DIM / 2 + SQUARE_DIM mod 2
--	else (others => '0') when conv_integer(col_cnt_reg + 1) * (H_RES / 32) < conv_integer(hor_graph_reg)
--	else (others => '0') when conv_integer(col_cnt_reg) * (H_RES / 32) >= conv_integer(hor_graph_reg) + SQUARE_DIM
--	else pixel_value_tmp;
	
	pixel_value_tmp(conv_integer(graph_clk_div_reg)) <= '0' when conv_integer(col_cnt_reg) * 32 + conv_integer(graph_clk_div_reg) < hor_graph_reg 
																				  and conv_integer(col_cnt_reg) * 32 + conv_integer(graph_clk_div_reg) > hor_graph_reg + SQUARE_DIM
		else '1';
		
	pixel_value <= (others => '1') when (conv_integer(row_cnt_reg) > 80)
											and (conv_integer(row_cnt_reg) < 320)
											and (conv_integer(col_cnt_reg) > 4)
											and (conv_integer(row_cnt_reg) > 15)
											else (others => '0');
												
	
	pixel_address <= conv_std_logic_vector(conv_integer(row_cnt_reg) * 32 + conv_integer(col_cnt_reg), GRAPH_MEM_ADDR_WIDTH);
  
end rtl;