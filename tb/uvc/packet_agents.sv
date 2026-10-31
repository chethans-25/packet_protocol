class packet_write_agent extends uvm_agent;
  `uvm_component_utils(packet_write_agent)

  packet_sequencer     sequencer;
  packet_driver        driver;
  packet_write_monitor monitor;

  function new(string name = "packet_write_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = packet_write_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = packet_sequencer::type_id::create("sequencer", this);
      driver    = packet_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

class packet_read_agent extends uvm_agent;
  `uvm_component_utils(packet_read_agent)

  packet_read_monitor monitor;

  function new(string name = "packet_read_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = packet_read_monitor::type_id::create("monitor", this);
  endfunction
endclass
