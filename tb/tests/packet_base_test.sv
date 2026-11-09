class packet_base_test extends uvm_test;
  `uvm_component_utils(packet_base_test)

  packet_env          env;
  packet_agent_config write_cfg;
  packet_agent_config read_cfg;

  virtual packet_if write_vif;
  virtual packet_if read_vif;

  function new(string name = "packet_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual packet_if)::get(this, "", "write_vif", write_vif))
      `uvm_fatal("NO_WRITE_VIF", "write_vif was not configured")
    if (!uvm_config_db#(virtual packet_if)::get(this, "", "read_vif", read_vif))
      `uvm_fatal("NO_READ_VIF", "read_vif was not configured")

    write_cfg = packet_agent_config::type_id::create("write_cfg");
    write_cfg.is_active = UVM_ACTIVE;
    write_cfg.role      = PACKET_WRITE_SIDE;
    write_cfg.vif       = write_vif;

    read_cfg = packet_agent_config::type_id::create("read_cfg");
    read_cfg.is_active = UVM_PASSIVE;
    read_cfg.role      = PACKET_READ_SIDE;
    read_cfg.vif       = read_vif;

    uvm_config_db#(packet_agent_config)::set(
      this, "env.write_agent", "cfg", write_cfg
    );
    uvm_config_db#(packet_agent_config)::set(
      this, "env.read_agent", "cfg", read_cfg
    );

    env = packet_env::type_id::create("env", this);
  endfunction

  // Run a packet sequence. The test objection only covers the time the
  // sequence is actively sending. The scoreboard raises its own objection
  // while packets are still in flight, so the run phase stays alive until the
  // FIFO has drained and every expected packet has been observed.
  task run_packet_sequence(uvm_phase phase, packet_base_sequence packet_seq);
    if (packet_seq == null)
      `uvm_fatal("NULL_SEQUENCE", "Cannot run a null packet sequence")

    packet_seq.packets_sent = 0;
    phase.raise_objection(this, "driving packet sequence");
    packet_seq.start(env.write_agent.sequencer);
    phase.drop_objection(this, "packet sequence finished driving");
  endtask
endclass
