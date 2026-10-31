`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class packet_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(packet_scoreboard)

  uvm_analysis_imp_expected #(packet_item, packet_scoreboard) expected_export;
  uvm_analysis_imp_actual   #(packet_item, packet_scoreboard) actual_export;

  packet_item expected_queue[$];
  int unsigned compared_packets;

  function new(string name = "packet_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
  endfunction

  function void write_expected(packet_item item);
    packet_item copy;
    if (!$cast(copy, item.clone()))
      `uvm_fatal("CLONE", "Could not clone expected packet")
    expected_queue.push_back(copy);
    `uvm_info("SCOREBOARD", $sformatf("Queued expected packet:\n%s", copy.sprint()), UVM_HIGH)
  endfunction

  function void write_actual(packet_item actual);
    packet_item expected;
    string reason;

    if (expected_queue.size() == 0) begin
      `uvm_error("SCOREBOARD", $sformatf("Unexpected output packet:\n%s", actual.sprint()))
      return;
    end

    expected = expected_queue.pop_front();
    if (!expected.compare_packet(actual, reason))
      `uvm_error("SCOREBOARD", $sformatf("Packet mismatch: %s\nExpected:\n%s\nActual:\n%s",
                                         reason, expected.sprint(), actual.sprint()))
    else
      `uvm_info("SCOREBOARD", $sformatf("Packet %0d matched", compared_packets), UVM_MEDIUM)

    compared_packets++;
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (expected_queue.size() != 0)
      `uvm_error("SCOREBOARD", $sformatf("%0d expected packet(s) were not observed",
                                         expected_queue.size()))
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", $sformatf("Compared %0d packet(s)", compared_packets), UVM_LOW)
  endfunction
endclass
