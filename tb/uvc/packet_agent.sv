class packet_agent extends uvm_agent;
  `uvm_component_utils(packet_agent)

  packet_agent_config cfg;
  packet_sequencer    sequencer;
  packet_driver       driver;
  packet_read_sequencer read_sequencer;
  packet_read_driver    read_driver;
  packet_monitor      monitor;

  function new(string name = "packet_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(packet_agent_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("NO_CFG", {get_full_name(), ": packet_agent_config was not configured"})

    if (cfg.vif == null)
      `uvm_fatal("NO_VIF", {get_full_name(), ": cfg.vif is null"})

    is_active = cfg.is_active;

    uvm_config_db#(packet_agent_config)::set(this, "monitor", "cfg", cfg);
    monitor = packet_monitor::type_id::create("monitor", this);

    if (get_is_active() == UVM_ACTIVE) begin
      if (cfg.role == PACKET_WRITE_SIDE) begin
        uvm_config_db#(packet_agent_config)::set(this, "driver", "cfg", cfg);
        sequencer = packet_sequencer::type_id::create("sequencer", this);
        driver    = packet_driver::type_id::create("driver", this);
      end else begin
        uvm_config_db#(packet_agent_config)::set(this, "driver", "cfg", cfg);
        read_sequencer = packet_read_sequencer::type_id::create("sequencer", this);
        read_driver    = packet_read_driver::type_id::create("driver", this);
      end
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      if (cfg.role == PACKET_WRITE_SIDE)
        driver.seq_item_port.connect(sequencer.seq_item_export);
      else
        read_driver.seq_item_port.connect(read_sequencer.seq_item_export);
    end
  endfunction
endclass
