class packet_sequencer extends uvm_sequencer #(packet_write_item);
  `uvm_component_utils(packet_sequencer)

  function new(string name = "packet_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass
