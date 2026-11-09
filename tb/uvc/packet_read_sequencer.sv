class packet_read_sequencer extends uvm_sequencer #(packet_read_control_item);
  `uvm_component_utils(packet_read_sequencer)

  function new(string name = "packet_read_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass
