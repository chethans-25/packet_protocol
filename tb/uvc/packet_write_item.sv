class packet_write_item extends uvm_sequence_item;
  rand bit       sop;
  rand bit       eop;
  rand bit       valid;
  rand bit       wr_en;
  rand bit [7:0] data;

  // Normal traffic is enabled by default, but derived sequences can override
  // these soft constraints inline for idle and disabled-write scenarios.
  constraint c_default_control {
    soft valid == 1'b1;
    soft wr_en == 1'b1;
  }

  constraint c_default_markers {
    soft sop == 1'b0;
    soft eop == 1'b0;
  }

  // SOP and EOP are only legal on a beat that the DUT can accept.
  constraint c_markers_require_transfer {
    (sop || eop) -> (valid && wr_en);
  }

  `uvm_object_utils_begin(packet_write_item)
    `uvm_field_int(sop,   UVM_DEFAULT)
    `uvm_field_int(eop,   UVM_DEFAULT)
    `uvm_field_int(valid, UVM_DEFAULT)
    `uvm_field_int(wr_en, UVM_DEFAULT)
    `uvm_field_int(data,  UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "packet_write_item");
    super.new(name);
  endfunction
endclass
