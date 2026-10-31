class packet_driver extends uvm_driver #(packet_item);
  `uvm_component_utils(packet_driver)

  virtual packet_if vif;

  function new(string name = "packet_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual packet_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {get_full_name(), ": packet_if was not configured"})
  endfunction

  task run_phase(uvm_phase phase);
    packet_item req;

    vif.sop   <= 1'b0;
    vif.eop   <= 1'b0;
    vif.valid <= 1'b0;
    vif.data  <= '0;
    vif.wr_en <= 1'b0;

    forever begin
      seq_item_port.get_next_item(req);
      drive_packet(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_packet(packet_item pkt);
    while (vif.rst)
      @(negedge vif.clk);

    foreach (pkt.payload[i]) begin
      @(negedge vif.clk);
      vif.sop   <= (i == 0);
      vif.eop   <= (i == pkt.payload.size()-1);
      vif.valid <= 1'b1;
      vif.data  <= pkt.payload[i];
      vif.wr_en <= 1'b1;
    end

    @(negedge vif.clk);
    vif.sop   <= 1'b0;
    vif.eop   <= 1'b0;
    vif.valid <= 1'b0;
    vif.data  <= '0;
    vif.wr_en <= 1'b0;
  endtask
endclass
