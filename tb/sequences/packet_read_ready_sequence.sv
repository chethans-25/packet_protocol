class packet_read_ready_sequence extends packet_read_base_sequence;
  `uvm_object_utils(packet_read_ready_sequence)

  function new(string name = "packet_read_ready_sequence");
    super.new(name);
  endfunction

  task body();
    // The read driver retains the most recently requested level. One item is
    // therefore sufficient to keep reads enabled until another sequence
    // changes rd_en.
    send_read_control(1'b1);
  endtask
endclass
