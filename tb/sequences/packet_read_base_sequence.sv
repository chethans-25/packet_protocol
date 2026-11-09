class packet_read_base_sequence extends uvm_sequence #(packet_read_control_item);
  `uvm_object_utils(packet_read_base_sequence)

  function new(string name = "packet_read_base_sequence");
    super.new(name);
  endfunction

  task send_read_control(bit rd_en, int unsigned cycles = 1);
    packet_read_control_item item;

    item = packet_read_control_item::type_id::create("item");
    start_item(item);
    if (!item.randomize() with {
          item.rd_en  == local::rd_en;
          item.cycles == local::cycles;
        })
      `uvm_fatal("RANDOMIZE", "Could not randomize read-control item")
    finish_item(item);
  endtask
endclass
