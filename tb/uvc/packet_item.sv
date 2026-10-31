class packet_item extends uvm_sequence_item;
  rand bit [7:0] payload[];

  constraint c_packet_length {
    payload.size() inside {[1:8]};
  }

  `uvm_object_utils_begin(packet_item)
    `uvm_field_array_int(payload, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "packet_item");
    super.new(name);
  endfunction

  function bit compare_packet(packet_item rhs, output string reason);
    if (rhs == null) begin
      reason = "actual packet is null";
      return 0;
    end
    if (payload.size() != rhs.payload.size()) begin
      reason = $sformatf("length mismatch: expected=%0d actual=%0d",
                         payload.size(), rhs.payload.size());
      return 0;
    end
    foreach (payload[i]) begin
      if (payload[i] !== rhs.payload[i]) begin
        reason = $sformatf("byte[%0d] mismatch: expected=0x%02h actual=0x%02h",
                           i, payload[i], rhs.payload[i]);
        return 0;
      end
    end
    reason = "";
    return 1;
  endfunction
endclass
