class packet_valid_variation_sequence extends packet_base_sequence;
  `uvm_object_utils(packet_valid_variation_sequence)

  rand bit random_valid;

  int unsigned valid_low_weight  = 40;
  int unsigned valid_high_weight = 60;
  int unsigned valid_low_cycles;

  constraint c_random_valid {
    random_valid dist {
      1'b0 := valid_low_weight,
      1'b1 := valid_high_weight
    };
  }

  function new(string name = "packet_valid_variation_sequence");
    super.new(name);
  endfunction

  // Keep wr_en asserted throughout the sequence. A low-valid cycle is an
  // idle cycle; the same payload beat is then sent with valid high so the
  // packet remains complete at both the write monitor and DUT input.
  task send_packet_with_random_valid(packet_item packet,
                                     int unsigned packet_index);
    packet_write_item beat;
    int unsigned middle_index;

    if (packet == null)
      `uvm_fatal("NULL_PACKET", "Cannot send a null packet")
    if (packet.payload.size() < 3)
      `uvm_fatal("SHORT_PACKET",
                 "valid variation requires at least three payload beats")

    middle_index = $urandom_range(packet.payload.size()-2, 1);

    foreach (packet.payload[i]) begin
      if (!this.randomize(random_valid))
        `uvm_fatal("RANDOMIZE", "Could not randomize valid")

      // Guarantee that valid changes in the interior of every packet while
      // retaining randomized idle cycles at any other beat.
      if (i == middle_index)
        random_valid = 1'b0;

      if (!random_valid) begin
        beat = packet_write_item::type_id::create(
          $sformatf("packet_%0d_idle_%0d", packet_index, i)
        );
        beat.sop   = 1'b0;
        beat.eop   = 1'b0;
        beat.valid = 1'b0;
        beat.wr_en = 1'b1;
        beat.data  = packet.payload[i];
        send_write_beat(beat);
        valid_low_cycles++;
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
    packet_write_item final_idle;

    valid_low_cycles = 0;
    for (int unsigned i = 0; i < packet_count; i++) begin
      packet = packet_item::type_id::create($sformatf("packet_%0d", i));
      if (!packet.randomize() with { payload.size() inside {[3:8]}; })
        `uvm_fatal("RANDOMIZE", "Could not randomize packet item")
      send_packet_with_random_valid(packet, i);
    end

    // Keep wr_en high for one final valid-low cycle. This also lets the
    // monitor sample the last packet's EOP before the sequence completes and
    // the test drops its stimulus objection.
    final_idle = packet_write_item::type_id::create("final_idle");
    final_idle.sop   = 1'b0;
    final_idle.eop   = 1'b0;
    final_idle.valid = 1'b0;
    final_idle.wr_en = 1'b1;
    final_idle.data  = '0;
    send_write_beat(final_idle);
    valid_low_cycles++;
  endtask
endclass
