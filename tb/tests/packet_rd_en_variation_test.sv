class packet_rd_en_variation_test extends packet_base_test;
  `uvm_component_utils(packet_rd_en_variation_test)

  localparam int unsigned EXPECTED_PACKETS = 10;

  packet_continuous_write_sequence write_seq;
  packet_rd_en_variation_sequence  rd_en_seq;

  function new(string name = "packet_rd_en_variation_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    write_seq = packet_continuous_write_sequence::type_id::create("write_seq");
    rd_en_seq = packet_rd_en_variation_sequence::type_id::create("rd_en_seq");

    write_seq.packet_count = EXPECTED_PACKETS;
    run_packet_sequences(phase, write_seq, rd_en_seq);
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (write_seq == null)
      `uvm_error("RD_EN_TEST", "continuous write sequence was not created")
    else if (write_seq.packets_sent != EXPECTED_PACKETS)
      `uvm_error("RD_EN_TEST",
                 $sformatf("Expected %0d sent packets, observed %0d",
                           EXPECTED_PACKETS, write_seq.packets_sent))

    if (rd_en_seq == null)
      `uvm_error("RD_EN_TEST", "rd_en variation sequence was not created")
    else begin
      if (rd_en_seq.rd_en_low_cycles == 0)
        `uvm_error("RD_EN_TEST", "rd_en was never driven low")
      if (rd_en_seq.rd_en_high_cycles == 0)
        `uvm_error("RD_EN_TEST", "rd_en was never driven high")
      if (rd_en_seq.rd_en_transitions == 0)
        `uvm_error("RD_EN_TEST", "rd_en did not vary during the test")
    end

    if (env.scoreboard.compared_packets != EXPECTED_PACKETS)
      `uvm_error("RD_EN_TEST",
                 $sformatf("Expected %0d compared packets, observed %0d",
                           EXPECTED_PACKETS,
                           env.scoreboard.compared_packets))
  endfunction
endclass
