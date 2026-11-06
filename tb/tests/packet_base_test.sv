class packet_base_test extends uvm_test;
  `uvm_component_utils(packet_base_test)

  packet_env env;

  function new(string name = "packet_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "env.write_agent",
                                                  "is_active", UVM_ACTIVE);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "env.read_agent",
                                                  "is_active", UVM_PASSIVE);
    super.build_phase(phase);
    env = packet_env::type_id::create("env", this);
  endfunction

  // Run a packet sequence and keep the phase alive until every packet that
  // the sequence intends to send has reached the scoreboard.
  task run_packet_sequence(uvm_phase phase, packet_base_sequence packet_seq);
    int unsigned starting_count;
    int unsigned target_count;

    if (packet_seq == null)
      `uvm_fatal("NULL_SEQUENCE", "Cannot run a null packet sequence")

    starting_count = env.scoreboard.compared_packets;
    packet_seq.packets_sent = 0;
    phase.raise_objection(this);
    packet_seq.start(env.write_agent.sequencer);
    target_count = starting_count + packet_seq.packets_sent;
    wait (env.scoreboard.compared_packets >= target_count);
    phase.drop_objection(this);
  endtask
endclass
