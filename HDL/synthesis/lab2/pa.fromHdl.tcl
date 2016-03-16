
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name lab2 -dir "D:/Sa diska F na staroj masini/Projekcije i Programi/ISE/RA77-2013/lab2/HDL/synthesis/lab2/planAhead_run_4" -part xc6slx45fgg676-2
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "top.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {../../source/rtl/vhdl/vga_sync.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/coregen/dcm75MHz.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/coregen/dcm50MHz.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/coregen/dcm25MHz.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/coregen/dcm108MHz.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/coregen/char_rom/char_rom_def.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/rtl/vhdl/vga.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/rtl/vhdl/text_mem.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/rtl/vhdl/graphics_mem.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/rtl/vhdl/char_rom.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/rtl/vhdl/vga_top.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {../../source/rtl/vhdl/top.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top top $srcset
add_files [list {top.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx45fgg676-2
