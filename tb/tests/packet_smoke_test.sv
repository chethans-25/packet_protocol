class packet_smoke_test extends uvm_test;
  `uvm_component_utils(packet_smoke_test)

  packet_env env;

  function new(string name = "packet_smoke_test", uvm_component parent = null);
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

  task run_phase(uvm_phase phase);
    packet_smoke_sequence smoke_seq;
    int unsigned expected_count = 10;

    phase.raise_objection(this);
    smoke_seq = packet_smoke_sequence::type_id::create("smoke_seq");
    smoke_seq.packet_count = expected_count;
    smoke_seq.start(env.write_agent.sequencer);

    wait (env.scoreboard.compared_packets >= expected_count);
    phase.drop_objection(this);
  endtask
endclass
