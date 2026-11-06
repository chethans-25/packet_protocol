class packet_random_test extends packet_base_test;
  `uvm_component_utils(packet_random_test)

  function new(string name = "packet_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    packet_random_sequence random_seq;

    random_seq = packet_random_sequence::type_id::create("random_seq");
    random_seq.packet_count = 10;
    run_packet_sequence(phase, random_seq);
  endtask
endclass
