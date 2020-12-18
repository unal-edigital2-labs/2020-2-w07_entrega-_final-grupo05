
# Create Project

create_project -force -name nexys4ddr -part xc7a100t-CSG324-1
set_msg_config -id {Common 17-55} -new_severity {Warning}

# Add Sources

read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/camara/camara.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/camara/buffer_ram_dp.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/camara/cam_read.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/camara/procesamiento.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/camara/VGA_driver.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/camara/PLL/clk24_25_nexys4.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/camara/PLL/clk24_25_nexys4_0.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/camara/PLL/clk24_25_nexys4_clk_wiz.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/radar/radar.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/radar/servo.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/radar/ultrasonido1.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/motor/motor.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/infrarojo/infra.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/module/verilog/infrarojo/infrarojo.v}
read_verilog {/opt/litex/pythondata-cpu-picorv32/pythondata_cpu_picorv32/verilog/picorv32.v}
read_verilog {/home/alvaro/Imágenes/Digital_II-main/Integrationii/build/nexys4ddr/gateware/nexys4ddr.v}

# Add EDIFs


# Add IPs


# Add constraints

read_xdc nexys4ddr.xdc
set_property PROCESSING_ORDER EARLY [get_files nexys4ddr.xdc]

# Add pre-synthesis commands


# Synthesis

synth_design -directive default -top nexys4ddr -part xc7a100t-CSG324-1

# Synthesis report

report_timing_summary -file nexys4ddr_timing_synth.rpt
report_utilization -hierarchical -file nexys4ddr_utilization_hierarchical_synth.rpt
report_utilization -file nexys4ddr_utilization_synth.rpt

# Optimize design

opt_design -directive default

# Add pre-placement commands


# Placement

place_design -directive default

# Placement report

report_utilization -hierarchical -file nexys4ddr_utilization_hierarchical_place.rpt
report_utilization -file nexys4ddr_utilization_place.rpt
report_io -file nexys4ddr_io.rpt
report_control_sets -verbose -file nexys4ddr_control_sets.rpt
report_clock_utilization -file nexys4ddr_clock_utilization.rpt

# Add pre-routing commands


# Routing

route_design -directive default
phys_opt_design -directive default
write_checkpoint -force nexys4ddr_route.dcp

# Routing report

report_timing_summary -no_header -no_detailed_paths
report_route_status -file nexys4ddr_route_status.rpt
report_drc -file nexys4ddr_drc.rpt
report_timing_summary -datasheet -max_paths 10 -file nexys4ddr_timing.rpt
report_power -file nexys4ddr_power.rpt

# Bitstream generation

write_bitstream -force nexys4ddr.bit 

# End

quit