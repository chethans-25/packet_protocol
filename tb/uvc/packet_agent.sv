class packet_agent extends uvm_agent;
  `uvm_component_utils(packet_agent)

  packet_agent_config cfg;
  packet_sequencer    sequencer;
  packet_driver       driver;
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

    // Keep the standard uvm_agent state consistent with the shared config.
    is_active = cfg.is_active;

    uvm_config_db#(packet_agent_config)::set(this, "monitor", "cfg", cfg);
    monitor = packet_monitor::type_id::create("monitor", this);

    if (get_is_active() == UVM_ACTIVE) begin
      if (cfg.role != PACKET_WRITE_SIDE)
        `uvm_fatal("UNSUPPORTED_ROLE",
                   "Only PACKET_WRITE_SIDE can be configured as UVM_ACTIVE")

      uvm_config_db#(packet_agent_config)::set(this, "driver", "cfg", cfg);
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
