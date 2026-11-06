class packet_random_sequence extends packet_base_sequence;
  `uvm_object_utils(packet_random_sequence)

  function new(string name = "packet_random_sequence");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < packet_count; i++)
      send_random_packet($sformatf("item_%0d", i));
  endtask
endclass
