class packet_env extends uvm_env;
  `uvm_component_utils(packet_env)

  packet_write_agent write_agent;
  packet_read_agent  read_agent;
  packet_scoreboard  scoreboard;

  function new(string name = "packet_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    write_agent = packet_write_agent::type_id::create("write_agent", this);
    read_agent  = packet_read_agent::type_id::create("read_agent", this);
    scoreboard  = packet_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    write_agent.monitor.ap.connect(scoreboard.expected_export);
    read_agent.monitor.ap.connect(scoreboard.actual_export);
  endfunction
endclass
