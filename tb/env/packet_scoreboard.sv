`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class packet_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(packet_scoreboard)

  uvm_analysis_imp_expected #(packet_item, packet_scoreboard) expected_export;
  uvm_analysis_imp_actual   #(packet_item, packet_scoreboard) actual_export;

  packet_item expected_queue[$];
  int unsigned compared_packets;

  // Run-phase handle captured so the analysis callbacks (which have no phase
  // argument) can raise/drop an objection while packets are still in flight.
  uvm_phase run_phase_h;
  // True while an objection is currently raised for outstanding packets.
  bit        objection_raised;

  function new(string name = "packet_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
  endfunction

  // Capture the run phase so write_expected/write_actual can gate phase end.
  task run_phase(uvm_phase phase);
    run_phase_h = phase;
  endtask

  // Raise the run-phase objection when the first packet becomes outstanding.
  function void raise_if_needed();
    if (run_phase_h != null && !objection_raised) begin
      run_phase_h.raise_objection(this, "packets outstanding in scoreboard");
      objection_raised = 1'b1;
    end
  endfunction

  // Drop the objection once every expected packet has been observed.
  function void drop_if_drained();
    if (run_phase_h != null && objection_raised && expected_queue.size() == 0) begin
      run_phase_h.drop_objection(this, "all expected packets observed");
      objection_raised = 1'b0;
    end
  endfunction

  function void write_expected(packet_item item);
    packet_item copy;
    if (!$cast(copy, item.clone()))
      `uvm_fatal("CLONE", "Could not clone expected packet")
    expected_queue.push_back(copy);
    raise_if_needed();
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
    drop_if_drained();
  endfunction

  // Guard against the run phase ending while packets are still outstanding.
  // If the queue is not empty, keep the phase open with a short drain window so
  // the final beats can propagate from the DUT to the read monitor.
  function void phase_ready_to_end(uvm_phase phase);
    if (phase.get_name() == "run" && expected_queue.size() != 0) begin
      phase.raise_objection(this, "scoreboard draining remaining packets");
      fork
        begin
          #200ns;
          phase.drop_objection(this, "scoreboard drain window elapsed");
        end
      join_none
    end
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
