class packet_continuous_write_sequence extends packet_base_sequence;
  `uvm_object_utils(packet_continuous_write_sequence)

  function new(string name = "packet_continuous_write_sequence");
    super.new(name);
  endfunction

  task send_continuous_packet(packet_item packet,
                              int unsigned packet_index);
    packet_write_item beat;

    if (packet == null)
      `uvm_fatal("NULL_PACKET", "Cannot send a null packet")
    if (packet.payload.size() == 0)
      `uvm_fatal("EMPTY_PACKET", "Cannot send an empty packet")

    foreach (packet.payload[i]) begin
      beat = packet_write_item::type_id::create(
        $sformatf("packet_%0d_beat_%0d", packet_index, i)
      );
      beat.sop   = (i == 0);
      beat.eop   = (i == packet.payload.size()-1);
      beat.valid = 1'b1;
      beat.wr_en = 1'b1;
      beat.data  = packet.payload[i];
      send_write_beat(beat);
    end

    packets_sent++;
  endtask

  task body();
    packet_item packet;

    for (int unsigned i = 0; i < packet_count; i++) begin
      packet = packet_item::type_id::create($sformatf("packet_%0d", i));
      if (!packet.randomize())
        `uvm_fatal("RANDOMIZE", "Could not randomize packet item")
      send_continuous_packet(packet, i);
    end
  endtask
endclass
