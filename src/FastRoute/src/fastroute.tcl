###############################################################################
##
## BSD 3-Clause License
##
## Copyright (c) 2019, University of California, San Diego.
## All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are met:
##
## * Redistributions of source code must retain the above copyright notice, this
##   list of conditions and the following disclaimer.
##
## * Redistributions in binary form must reproduce the above copyright notice,
##   this list of conditions and the following disclaimer in the documentation
##   and#or other materials provided with the distribution.
##
## * Neither the name of the copyright holder nor the names of its
##   contributors may be used to endorse or promote products derived from
##   this software without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
## AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
## ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
## LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
##
###############################################################################

sta::define_cmd_args "set_global_routing_layer_adjustment" { layer adj }

proc set_global_routing_layer_adjustment { args } {
  if {[llength $args] == 2} {
    lassign $args layer adj

    if {$layer == {*}} {
      sta::check_positive_float "adjustment" $adj
      grt::set_capacity_adjustment $adj
    } elseif {[string is integer $layer]} {
      grt::check_routing_layer $layer
      sta::check_positive_float "adjustment" $adj

      grt::add_layer_adjustment $layer $adj
    } else {
      set layer_range [grt::parse_layer_range "set_global_routing_layer_adjustment" $layer]
      lassign $layer_range first_layer last_layer
      for {set l $first_layer} {$l <= $last_layer} {incr l} {
        grt::check_routing_layer $l
        sta::check_positive_float "adjustment" $adj

        grt::add_layer_adjustment $l $adj
      }
    }
  } else {
    utl::error GRT 44 "set_global_routing_layer_adjustment: Wrong number of arguments."
  }
}

sta::define_cmd_args "set_global_routing_layer_pitch" { layer pitch }

proc set_global_routing_layer_pitch { args } {
  if {[llength $args] == 2} {
    lassign $args layer pitch

    grt::check_routing_layer $layer
    sta::check_positive_float "pitch" $pitch

    grt::set_layer_pitch $layer $pitch
  } else {
    utl::error GRT 45 "set_global_routing_layer_pitch: Wrong number of arguments."
  }
}

sta::define_cmd_args "set_pdrev_topology_priority" { net alpha }

proc set_pdrev_topology_priority { args } {
  if {[llength $args] == 2} {
    lassign $args net alpha
    
    sta::check_positive_float "-alpha" $alpha
    grt::set_alpha_for_net $net $alpha
  } else {
    utl::error GRT 46 "set_pdrev_topology_priority: Wrong number of arguments."
  }
}

sta::define_cmd_args "set_global_routing_region_adjustment" { region \
                                                              [-layer layer] \
                                                              [-adjustment adjustment] \
}

proc set_global_routing_region_adjustment { args } {
  sta::parse_key_args "set_global_routing_region_adjustment" args \
                 keys {-layer -adjustment}

  if { ![ord::db_has_tech] } {
    utl::error GRT 47 "missing dbTech."
  }
  set tech [ord::get_db_tech]
  set lef_units [$tech getLefUnits]

  if { [info exists keys(-layer)] } {
    set layer $keys(-layer)
  } else {
    utl::error GRT 48 "set_global_routing_region_adjustment: Missing layer."
  }

  if { [info exists keys(-adjustment)] } {
    set adjustment $keys(-adjustment)
  } else {
    utl::error GRT 49 "set_global_routing_region_adjustment: Missing adjustment."
  }

  sta::check_argc_eq1 "set_global_routing_region_adjustment" $args
  set region [lindex $args 0]
  if {[llength $region] == 4} {
    lassign $region lower_x lower_y upper_x upper_y
    sta::check_positive_float "lower_left_x" $lower_x
    sta::check_positive_float "lower_left_y" $lower_y
    sta::check_positive_float "upper_right_x" $upper_x
    sta::check_positive_float "upper_right_y" $upper_y
    sta::check_positive_integer "-layer" $layer
    sta::check_positive_float "-adjustment" $adjustment

    set lower_x [expr { int($lower_x * $lef_units) }]
    set lower_y [expr { int($lower_y * $lef_units) }]
    set upper_x [expr { int($upper_x * $lef_units) }]
    set upper_y [expr { int($upper_y * $lef_units) }]

    grt::check_region $lower_x $lower_y $upper_x $upper_y

    grt::add_region_adjustment $lower_x $lower_y $upper_x $upper_y $layer $adjustment
  } else {
    utl::error GRT 50 "set_global_routing_region_adjustment: Wrong number of arguments to define a region."
  }
}

sta::define_cmd_args "repair_antennas" { lib_port }

proc repair_antennas { args } {
  sta::check_argc_eq1 "repair_antennas" $args
  set lib_port [lindex $args 0]
  if { ![sta::is_object $lib_port] } {
    set lib_port [sta::get_lib_pins [lindex $args 0]]
  }
  if { $lib_port != "" } {
    grt::repair_antennas $lib_port
  }
}

sta::define_cmd_args "write_guides" { file_name }

proc write_guides { args } {
  set file_name $args
  grt::write_guides $file_name
}

sta::define_cmd_args "global_route" {[-guide_file out_file] \
                                  [-layers layers] \
                                  [-unidirectional_routing] \
                                  [-tile_size tile_size] \
                                  [-verbose verbose] \
                                  [-overflow_iterations iterations] \
                                  [-grid_origin origin] \
                                  [-allow_overflow] \
                                  [-seed seed] \
                                  [-report_congestion congest_file] \
                                  [-clock_layers layers] \
                                  [-clock_pdrev_fanout fanout] \
                                  [-clock_topology_priority priority] \
                                  [-clock_tracks_cost clock_tracks_cost] \
                                  [-macro_extension macro_extension] \
                                  [-only_signal_nets] \
                                  [-output_file out_file] \
                                  [-min_routing_layer min_layer] \
                                  [-max_routing_layer max_layer] \
                                  [-layers_adjustments layers_adjustments] \
                                  [-layers_pitches layers_pitches] \
}

# sta::define_cmd_alias "fastroute" "global_route"

proc fastroute { args } {
  utl::warn GRT 19 "fastroute command is deprecated. Use global_route instead."
  [eval global_route $args]
}

proc global_route { args } {
  sta::parse_key_args "global_route" args \
    keys {-guide_file -layers -tile_size -verbose -layers_adjustments \ 
          -overflow_iterations -grid_origin -seed -report_congestion \
          -clock_layers -clock_pdrev_fanout -clock_topology_priority \
          -clock_tracks_cost -macro_extension \
          -output_file -min_routing_layer -max_routing_layer -layers_pitches \
         } \
    flags {-unidirectional_routing -allow_overflow -only_signal_nets} \

  if { ![ord::db_has_tech] } {
    utl::error GRT 51 "missing dbTech."
  }

  if { [ord::get_db_block] == "NULL" } {
    utl::error GRT 52 "missing dbBlock."
  }

  if { [info exists keys(-verbose) ] } {
    set verbose $keys(-verbose)
    grt::set_verbose $verbose
  } else {
    grt::set_verbose 0
  }

  if { [info exists keys(-layers_pitches)] } {
    utl::warn GRT 20 "option -layers_pitches is deprecated. Use command set_global_routing_layer_pitch layer pitch."
    set layers_pitches $keys(-layers_pitches)
    foreach layer_pitch $layers_pitches {
      if { [llength $layer_pitch] == 2 } {
        lassign $layer_pitch layer pitch
        grt::set_layer_pitch $layer $pitch
      } else {
        utl::error GRT 53 "Wrong number of arguments for layer pitches."
      }
    }
  }

  if { [info exists keys(-layers_adjustments)] } {
    utl::warn GRT 21 "option -layers_adjustments is deprecated. Use command set_global_routing_layer_adjustment layer adjustment."
    set layers_adjustments $keys(-layers_adjustments)
    foreach layer_adjustment $layers_adjustments {
      if { [llength $layer_adjustment] == 2 } {
        lassign $layer_adjustment layer reductionPercentage
        grt::add_layer_adjustment $layer $reductionPercentage
      } else {
        utl::error GRT 54 "Wrong number of arguments for layer adjustments."
      }
    }
  }

  grt::set_unidirectional_routing [info exists flags(-unidirectional_routing)]

  if { [info exists keys(-grid_origin)] } {
    set origin $keys(-grid_origin)
    if { [llength $origin] == 2 } {
      lassign $origin origin_x origin_y
      grt::set_grid_origin $origin_x $origin_y
    } else {
      utl::error GRT 55 "Wrong number of arguments for origin."
    }
  } else {
    grt::set_grid_origin 0 0
  }

  if { [info exists keys(-overflow_iterations) ] } {
    set iterations $keys(-overflow_iterations)
    sta::check_positive_integer "-overflow_iterations" $iterations
    grt::set_overflow_iterations $iterations
  } else {
    grt::set_overflow_iterations 50
  }

  if { [info exists keys(-clock_topology_priority) ] } {
    set priority $keys(-clock_topology_priority)
    sta::check_positive_float "-clock_topology_priority" $priority
    grt::set_alpha $clock_topology_priority
  } else {
    # Default alpha as 0.3 prioritize wire length, but keeps
    # aware of skew in the topology construction (see PDRev paper
    # for more reference)
    grt::set_alpha 0.3
  }

  if { [info exists keys(-clock_tracks_cost)] } {
    set clock_tracks_cost $keys(-clock_tracks_cost)
    grt::set_clock_cost $clock_tracks_cost
  } else {
    grt::set_clock_cost 1
  }

  if { [info exists keys(-clock_pdrev_fanout)] } {
    set fanout $keys(-clock_pdrev_fanout)
    grt::set_pdrev_for_high_fanout $fanout
  } else {
    grt::set_pdrev_for_high_fanout -1
  }

  if { [info exists keys(-tile_size)] } {
    set tile_size $keys(-tile_size)
    grt::set_tile_size $tile_size
  }

  if { [info exists keys(-seed) ] } {
    set seed $keys(-seed)
    grt::set_seed $seed
  } else {
    grt::set_seed 0
  }

  grt::set_allow_overflow [info exists flags(-allow_overflow)]

  if { [info exists keys(-macro_extension)] } {
    set macro_extension $keys(-macro_extension)
    grt::set_macro_extension $macro_extension
  } else {
    grt::set_macro_extension 0
  }

  set min_clock_layer 6
  if { [info exists keys(-clock_layers)] } {
    set layer_range [grt::parse_layer_range "-clock_layers" $keys(-clock_layers)]
    lassign $layer_range min_clock_layer max_clock_layer
    grt::check_routing_layer $min_clock_layer
    grt::check_routing_layer $max_clock_layer

    if { $min_clock_layer < $max_clock_layer } {
      grt::set_clock_layer_range $min_clock_layer $max_clock_layer
      grt::route_clock_nets
    } else {
      utl::error GRT 56 "-clock_layers: Min routing layer is greater than max routing layer."
    }
  }

  if { [info exists keys(-min_routing_layer)] } {
    utl::warn GRT 22 "option -min_routing_layer is deprecated. Use option -layers {min max}."
    set min_layer $keys(-min_routing_layer)
    sta::check_positive_integer "-min_routing_layer" $min_layer
    grt::set_min_layer $min_layer
  } else {
    grt::set_min_layer 1
  }

  set max_layer -1
  if { [info exists keys(-max_routing_layer)] } {
    utl::warn GRT 23 "option -max_routing_layer is deprecated. Use option -layers min-max."
    set max_layer $keys(-max_routing_layer)
    sta::check_positive_integer "-max_routing_layer" $max_layer
    grt::set_max_layer $max_layer
  } else {
    grt::set_max_layer -1
  }

  if { [info exists keys(-layers)] } {
    set layer_range [grt::parse_layer_range "-layers" $keys(-layers)]
    lassign $layer_range min_layer max_layer
    grt::check_routing_layer $min_layer
    grt::check_routing_layer $max_layer

    grt::set_min_layer $min_layer
    grt::set_max_layer $max_layer
  }

  for {set layer 1} {$layer <= $max_layer} {set layer [expr $layer+1]} {
    if { !([ord::db_layer_has_hor_tracks $layer] && \
         [ord::db_layer_has_ver_tracks $layer]) } {
      utl::error GRT 57 "missing track structure."
    }
  }

  if { [info exists keys(-report_congestion)] } {
    set congest_file $keys(-report_congestion)
    grt::report_congestion $congest_file
  }

  set only_signal [expr [info exists keys(-clock_layers)] || [info exists flags(-only_signal_nets)]]
  grt::run_fastroute $only_signal
  
  if { [info exists keys(-output_file)] } {
    utl::warn GRT 24 "option -output_file is deprecated. Use option -guide_file."
    set out_file $keys(-output_file)
    grt::write_guides $out_file
  }

  if { [info exists keys(-guide_file)] } {
    set out_file $keys(-guide_file)
    grt::write_guides $out_file
  }
}

namespace eval grt {

proc estimate_rc_cmd {} {
  if { [have_routes] } {
    estimate_rc
  } else {
    utl::error GRT 58 "run fastroute before estimating parasitics for global routing."
  }
}

proc check_routing_layer { layer } {
  if { ![ord::db_has_tech] } {
    utl::error GRT 59 "no technology has been read."
  }
  sta::check_positive_integer "layer" $layer

  set tech [ord::get_db_tech]
  set max_routing_layer [$tech getRoutingLayerCount]
  
  if {$layer > $max_routing_layer} {
    utl::error GRT 60 "check_routing_layer: layer $layer is greater than the max routing layer ($max_routing_layer)."
  }
  if {$layer < 1} {
    utl::error GRT 61 "check_routing_layer: layer $layer is lesser than the min routing layer (1)."
  }
}

proc parse_layer_range { cmd layer_range } {
  if [regexp -all {([0-9]+)-([0-9]+)} $layer_range - min_layer max_layer] {
    set layers "$min_layer $max_layer"
    return $layers
  } else {
    utl::error GRT 62 "Input format to define layer range for $cmd is min-max."
  }
}

proc check_region { lower_x lower_y upper_x upper_y } {
  set block [ord::get_db_block]
  if { $block == "NULL" } {
    utl::error GRT 63 "missing dbBlock."
  }

  set core_area [$block getDieArea]

  if {$lower_x < [$core_area xMin] || $lower_x > [$core_area xMax]} {
    utl::error GRT 64 "check_region: Lower left x is outside die area."
  }

  if {$lower_y < [$core_area yMin] || $lower_y > [$core_area yMax]} {
    utl::error GRT 65 "check_region: Lower left y is outside die area."
  }

  if {$upper_x < [$core_area xMin] || $upper_x > [$core_area xMax]} {
    utl::error GRT 66 "check_region: Upper right x is outside die area."
  }

  if {$upper_y < [$core_area yMin] || $upper_y > [$core_area yMax]} {
    utl::error GRT 67 "check_region: Upper right y is outside die area."
  }
}

proc highlight_route { net_name } {
  set block [ord::get_db_block]
  set net [$block findNet $net_name]
  if { $net != "NULL" } {
    highlight_net_route $net
  }
}

# grt namespace end
}
