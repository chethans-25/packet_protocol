class packet_valid_variation_test extends packet_base_test;
  `uvm_component_utils(packet_valid_variation_test)

  localparam int unsigned EXPECTED_PACKETS = 10;

  packet_valid_variation_sequence valid_seq;

  function new(string name = "packet_valid_variation_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    valid_seq = packet_valid_variation_sequence::type_id::create("valid_seq");
    valid_seq.packet_count = EXPECTED_PACKETS;

    // run_packet_sequence starts packet_read_ready_sequence concurrently. The
    // read driver retains its value, so rd_en remains high for the test.
    run_packet_sequence(phase, valid_seq);
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (valid_seq == null)
      `uvm_error("VALID_TEST", "valid variation sequence was not created")
    else begin
      if (valid_seq.packets_sent != EXPECTED_PACKETS)
        `uvm_error("VALID_TEST",
                   $sformatf("Expected %0d sent packets, observed %0d",
                             EXPECTED_PACKETS, valid_seq.packets_sent))
      if (valid_seq.valid_low_cycles < EXPECTED_PACKETS)
        `uvm_error("VALID_TEST",
                   $sformatf("Expected an interior valid-low cycle in every packet; observed %0d low cycles",
                             valid_seq.valid_low_cycles))
    end

    if (env.scoreboard.compared_packets != EXPECTED_PACKETS)
      `uvm_error("VALID_TEST",
                 $sformatf("Expected %0d compared packets, observed %0d",
                           EXPECTED_PACKETS,
                           env.scoreboard.compared_packets))
  endfunction
endclass
