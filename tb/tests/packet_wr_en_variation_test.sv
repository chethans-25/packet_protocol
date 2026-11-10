class packet_wr_en_variation_test extends packet_base_test;
  `uvm_component_utils(packet_wr_en_variation_test)

  localparam int unsigned EXPECTED_PACKETS = 10;

  packet_wr_en_variation_sequence wr_en_seq;

  function new(string name = "packet_wr_en_variation_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wr_en_seq = packet_wr_en_variation_sequence::type_id::create("wr_en_seq");
    wr_en_seq.packet_count = EXPECTED_PACKETS;

    // run_packet_sequence starts packet_read_ready_sequence concurrently. The
    // read driver retains its value, so rd_en remains high for the test.
    run_packet_sequence(phase, wr_en_seq);
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (wr_en_seq == null)
      `uvm_error("WR_EN_TEST", "wr_en variation sequence was not created")
    else begin
      if (wr_en_seq.packets_sent != EXPECTED_PACKETS)
        `uvm_error("WR_EN_TEST",
                   $sformatf("Expected %0d sent packets, observed %0d",
                             EXPECTED_PACKETS, wr_en_seq.packets_sent))
      if (wr_en_seq.wr_en_low_cycles < EXPECTED_PACKETS)
        `uvm_error("WR_EN_TEST",
                   $sformatf("Expected an interior wr_en stall in every packet; observed %0d low cycles",
                             wr_en_seq.wr_en_low_cycles))
    end

    if (env.scoreboard.compared_packets != EXPECTED_PACKETS)
      `uvm_error("WR_EN_TEST",
                 $sformatf("Expected %0d compared packets, observed %0d",
                           EXPECTED_PACKETS,
                           env.scoreboard.compared_packets))
  endfunction
endclass
