class packet_base_sequence extends uvm_sequence #(packet_write_item);
  `uvm_object_utils(packet_base_sequence)

  int unsigned packet_count = 10;
  int unsigned packets_sent;

  function new(string name = "packet_base_sequence");
    super.new(name);
  endfunction

  // Send one explicitly configured cycle. Derived sequences can randomize the
  // item with inline constraints before calling this helper.
  task send_write_beat(packet_write_item item);
    if (item == null)
      `uvm_fatal("NULL_ITEM", "Cannot send a null write item")

    start_item(item);
    finish_item(item);
  endtask

  // Send one complete logical packet as accepted write beats.
  task send_packet(packet_item packet);
    packet_write_item beat;

    if (packet == null)
      `uvm_fatal("NULL_PACKET", "Cannot send a null packet")
    if (packet.payload.size() == 0)
      `uvm_fatal("EMPTY_PACKET", "Cannot send an empty packet")

    foreach (packet.payload[i]) begin
      beat = packet_write_item::type_id::create($sformatf("beat_%0d", i));
      beat.sop   = (i == 0);
      beat.eop   = (i == packet.payload.size()-1);
      beat.valid = 1'b1;
      beat.wr_en = 1'b1;
      beat.data  = packet.payload[i];
      send_write_beat(beat);
    end

    packets_sent++;
    send_idle_cycles(1);
  endtask

  // Create and randomize packet data, then serialize it into write beats.
  task send_random_packet(string item_name = "packet");
    packet_item packet;

    packet = packet_item::type_id::create(item_name);
    if (!packet.randomize())
      `uvm_fatal("RANDOMIZE", "Could not randomize packet item")
    send_packet(packet);
  endtask

  task send_idle_cycles(int unsigned cycles = 1);
    packet_write_item idle;

    repeat (cycles) begin
      idle = packet_write_item::type_id::create("idle");
      start_item(idle);
      if (!idle.randomize() with {
            valid == 1'b0;
            wr_en == 1'b0;
            sop   == 1'b0;
            eop   == 1'b0;
          })
        `uvm_fatal("RANDOMIZE", "Could not randomize idle write item")
      finish_item(idle);
    end
  endtask
endclass
