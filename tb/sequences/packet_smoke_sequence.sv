class packet_smoke_sequence extends uvm_sequence #(packet_item);
  `uvm_object_utils(packet_smoke_sequence)

  int unsigned packet_count = 10;

  function new(string name = "packet_smoke_sequence");
    super.new(name);
  endfunction

  task body();
    repeat (packet_count) begin
      packet_item item;
      item = packet_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_fatal("RANDOMIZE", "Could not randomize packet item")
      finish_item(item);
    end
  endtask
endclass
