class packet_base_sequence extends uvm_sequence #(packet_item);
  `uvm_object_utils(packet_base_sequence)

  int unsigned packet_count = 10;
  int unsigned packets_sent;

  function new(string name = "packet_base_sequence");
    super.new(name);
  endfunction

  // Send an item that a derived sequence has already configured.
  task send_packet(packet_item item);
    if (item == null)
      `uvm_fatal("NULL_ITEM", "Cannot send a null packet item")

    start_item(item);
    finish_item(item);
    packets_sent++;
  endtask

  // Create, randomize, and send one packet using packet_item constraints.
  task send_random_packet(string item_name = "item");
    packet_item item;

    item = packet_item::type_id::create(item_name);
    start_item(item);
    if (!item.randomize())
      `uvm_fatal("RANDOMIZE", "Could not randomize packet item")
    finish_item(item);
    packets_sent++;
  endtask
endclass
