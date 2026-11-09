class packet_read_control_item extends uvm_sequence_item;
  rand bit          rd_en;
  rand int unsigned cycles;

  constraint c_default_control {
    soft rd_en  == 1'b1;
    soft cycles == 1;
  }

  constraint c_cycles {
    cycles inside {[1:1000]};
  }

  `uvm_object_utils_begin(packet_read_control_item)
    `uvm_field_int(rd_en,  UVM_DEFAULT)
    `uvm_field_int(cycles, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "packet_read_control_item");
    super.new(name);
  endfunction
endclass
