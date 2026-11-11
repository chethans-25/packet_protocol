class packet_wr_en_variation_sequence extends packet_base_sequence;
  `uvm_object_utils(packet_wr_en_variation_sequence)

  rand bit random_wr_en;

  int unsigned wr_en_low_weight  = 40;
  int unsigned wr_en_high_weight = 60;
  int unsigned wr_en_low_cycles;

  constraint c_random_wr_en {
    random_wr_en dist {
      1'b0 := wr_en_low_weight,
      1'b1 := wr_en_high_weight
    };
  }

  function new(string name = "packet_wr_en_variation_sequence");
    super.new(name);
  endfunction

  // Keep valid asserted throughout each packet. A low wr_en cycle is a stall;
  // the same payload beat is then sent with wr_en high so the packet remains
  // complete at both the write monitor and DUT input.
  task send_packet_with_random_wr_en(packet_item packet,
                                     int unsigned packet_index);
    packet_write_item beat;
    int unsigned middle_index;

    if (packet == null)
      `uvm_fatal("NULL_PACKET", "Cannot send a null packet")
    if (packet.payload.size() < 3)
      `uvm_fatal("SHORT_PACKET",
                 "wr_en variation requires at least three payload beats")

    middle_index = $urandom_range(packet.payload.size()-2, 1);

    foreach (packet.payload[i]) begin
      if (!this.randomize(random_wr_en))
        `uvm_fatal("RANDOMIZE", "Could not randomize wr_en")

      // Guarantee that wr_en changes in the interior of every packet while
      // retaining random stalls at any other beat.
      if (i == middle_index)
        random_wr_en = 1'b0;

      if (!random_wr_en) begin
        beat = packet_write_item::type_id::create(
          $sformatf("packet_%0d_stall_%0d", packet_index, i)
        );
        beat.sop   = 1'b0;
        beat.eop   = 1'b0;
        beat.valid = 1'b1;
        beat.wr_en = 1'b0;
        beat.data  = packet.payload[i];
        send_write_beat(beat);
        wr_en_low_cycles++;
      end

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
    packet_write_item final_stall;

    wr_en_low_cycles = 0;
    for (int unsigned i = 0; i < packet_count; i++) begin
      packet = packet_item::type_id::create($sformatf("packet_%0d", i));
      if (!packet.randomize() with { payload.size() inside {[3:8]}; })
        `uvm_fatal("RANDOMIZE", "Could not randomize packet item")
      send_packet_with_random_wr_en(packet, i);
    end

    // Keep valid high for one final disabled-write cycle. Besides exercising
    // wr_en low, this lets the monitor sample the last packet's EOP before the
    // sequence completes and the test drops its stimulus objection.
    final_stall = packet_write_item::type_id::create("final_stall");
    final_stall.sop   = 1'b0;
    final_stall.eop   = 1'b0;
    final_stall.valid = 1'b1;
    final_stall.wr_en = 1'b0;
    final_stall.data  = '0;
    send_write_beat(final_stall);
    wr_en_low_cycles++;
  endtask
endclass
