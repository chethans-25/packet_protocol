class packet_write_monitor extends uvm_monitor;
  `uvm_component_utils(packet_write_monitor)

  virtual packet_if vif;
  uvm_analysis_port #(packet_item) ap;

  packet_item current_packet;
  bit collecting;

  function new(string name = "packet_write_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual packet_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {get_full_name(), ": packet_if was not configured"})
  endfunction

  task run_phase(uvm_phase phase);
    collecting = 0;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.rst) begin
        collecting = 0;
        current_packet = null;
      end else if (vif.mon_cb.wr_en && vif.mon_cb.valid) begin
        sample_beat(vif.mon_cb.sop, vif.mon_cb.eop, vif.mon_cb.data);
      end
    end
  endtask

  function void sample_beat(bit sop, bit eop, bit [7:0] data);
    if (sop) begin
      if (collecting)
        `uvm_error("WRITE_PROTOCOL", "SOP observed before previous packet reached EOP")
      current_packet = packet_item::type_id::create("current_packet");
      current_packet.payload = new[0];
      collecting = 1;
    end else if (!collecting) begin
      `uvm_error("WRITE_PROTOCOL", "Accepted write beat observed without SOP")
      return;
    end

    current_packet.payload = new[current_packet.payload.size()+1](current_packet.payload);
    current_packet.payload[current_packet.payload.size()-1] = data;

    if (eop) begin
      ap.write(current_packet);
      collecting = 0;
      current_packet = null;
    end
  endfunction
endclass
