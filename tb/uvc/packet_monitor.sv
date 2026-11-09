class packet_monitor extends uvm_monitor;
  `uvm_component_utils(packet_monitor)

  packet_agent_config cfg;
  uvm_analysis_port #(packet_item) ap;

  packet_item current_packet;
  bit collecting;

  function new(string name = "packet_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(packet_agent_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("NO_CFG", {get_full_name(), ": packet_agent_config was not configured"})
    if (cfg.vif == null)
      `uvm_fatal("NO_VIF", {get_full_name(), ": cfg.vif is null"})
  endfunction

  task run_phase(uvm_phase phase);
    bit transfer;

    collecting = 0;
    forever begin
      @(cfg.vif.mon_cb);
      if (cfg.vif.mon_cb.rst) begin
        collecting = 0;
        current_packet = null;
      end else begin
        if (cfg.role == PACKET_WRITE_SIDE)
          transfer = cfg.vif.mon_cb.wr_en && cfg.vif.mon_cb.valid;
        else
          transfer = cfg.vif.mon_cb.rd_en && cfg.vif.mon_cb.valid;

        if (transfer)
          sample_beat(cfg.vif.mon_cb.sop, cfg.vif.mon_cb.eop,
                      cfg.vif.mon_cb.data);
      end
    end
  endtask

  function void sample_beat(bit sop, bit eop, bit [7:0] data);
    string protocol_id;

    protocol_id = (cfg.role == PACKET_WRITE_SIDE) ?
                  "WRITE_PROTOCOL" : "READ_PROTOCOL";

    if (sop) begin
      if (collecting)
        `uvm_error(protocol_id,
                   "SOP observed before previous packet reached EOP")
      current_packet = packet_item::type_id::create("current_packet");
      current_packet.payload = new[0];
      collecting = 1;
    end else if (!collecting) begin
      `uvm_error(protocol_id,
                 $sformatf("Accepted %s beat observed without SOP",
                           cfg.role_name()))
      return;
    end

    current_packet.payload =
      new[current_packet.payload.size()+1](current_packet.payload);
    current_packet.payload[current_packet.payload.size()-1] = data;

    if (eop) begin
      ap.write(current_packet);
      collecting = 0;
      current_packet = null;
    end
  endfunction
endclass
