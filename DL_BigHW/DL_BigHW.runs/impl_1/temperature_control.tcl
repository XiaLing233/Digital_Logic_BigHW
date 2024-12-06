proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  set_param xicom.use_bs_reader 1
  set_param simulator.modelsimInstallPath C:/WorkSpace/ModelSim/win32pe
  set_property design_mode GateLvl [current_fileset]
  set_param project.singleFileAddWarning.threshold 0
  set_property webtalk.parent_dir C:/WorkSpace/Homework_Digital_Logic/Digital_Logic_BigHW/DL_BigHW/DL_BigHW.cache/wt [current_project]
  set_property parent.project_path C:/WorkSpace/Homework_Digital_Logic/Digital_Logic_BigHW/DL_BigHW/DL_BigHW.xpr [current_project]
  set_property ip_repo_paths c:/WorkSpace/Homework_Digital_Logic/Digital_Logic_BigHW/DL_BigHW/DL_BigHW.cache/ip [current_project]
  set_property ip_output_repo c:/WorkSpace/Homework_Digital_Logic/Digital_Logic_BigHW/DL_BigHW/DL_BigHW.cache/ip [current_project]
  add_files -quiet C:/WorkSpace/Homework_Digital_Logic/Digital_Logic_BigHW/DL_BigHW/DL_BigHW.runs/synth_1/temperature_control.dcp
  read_xdc C:/WorkSpace/Homework_Digital_Logic/Digital_Logic_BigHW/DL_BigHW/DL_BigHW.srcs/constrs_1/new/init_tmp_tb.xdc
  link_design -top temperature_control -part xc7a100tcsg324-1
  write_hwdef -file temperature_control.hwdef
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  opt_design 
  write_checkpoint -force temperature_control_opt.dcp
  report_drc -file temperature_control_drc_opted.rpt
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  implement_debug_core 
  place_design 
  write_checkpoint -force temperature_control_placed.dcp
  report_io -file temperature_control_io_placed.rpt
  report_utilization -file temperature_control_utilization_placed.rpt -pb temperature_control_utilization_placed.pb
  report_control_sets -verbose -file temperature_control_control_sets_placed.rpt
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force temperature_control_routed.dcp
  report_drc -file temperature_control_drc_routed.rpt -pb temperature_control_drc_routed.pb
  report_timing_summary -warn_on_violation -max_paths 10 -file temperature_control_timing_summary_routed.rpt -rpx temperature_control_timing_summary_routed.rpx
  report_power -file temperature_control_power_routed.rpt -pb temperature_control_power_summary_routed.pb -rpx temperature_control_power_routed.rpx
  report_route_status -file temperature_control_route_status.rpt -pb temperature_control_route_status.pb
  report_clock_utilization -file temperature_control_clock_utilization_routed.rpt
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}

start_step write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  catch { write_mem_info -force temperature_control.mmi }
  write_bitstream -force temperature_control.bit 
  catch { write_sysdef -hwdef temperature_control.hwdef -bitfile temperature_control.bit -meminfo temperature_control.mmi -file temperature_control.sysdef }
  catch {write_debug_probes -quiet -force debug_nets}
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
}

