class packet_driver extends uvm_driver #(packet_write_item);
  `uvm_component_utils(packet_driver)

  packet_agent_config cfg;
  virtual packet_if vif;

  function new(string name = "packet_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(packet_agent_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("NO_CFG", {get_full_name(), ": packet_agent_config was not configured"})
    if (cfg.vif == null)
      `uvm_fatal("NO_VIF", {get_full_name(), ": cfg.vif is null"})
    if (cfg.is_active != UVM_ACTIVE || cfg.role != PACKET_WRITE_SIDE)
      `uvm_fatal("BAD_WRITE_CFG",
                 "packet_driver requires an active write-side configuration")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    packet_write_item req;

    drive_idle();

    // Poll once per cycle so every request controls exactly one DUT cycle.
    // When no request is available, drive an idle cycle instead of repeating
    // the previous valid beat.
    forever begin
      @(negedge vif.clk);

      if (vif.rst) begin
        drive_idle();
      end else begin
        req = null;
        seq_item_port.try_next_item(req);
        if (req == null) begin
          drive_idle();
        end else begin
          drive_beat(req);
          seq_item_port.item_done();
        end
      end
    end
  endtask

  function void drive_beat(packet_write_item item);
    vif.sop   <= item.sop;
    vif.eop   <= item.eop;
    vif.valid <= item.valid;
    vif.data  <= item.data;
    vif.wr_en <= item.wr_en;
  endfunction

  function void drive_idle();
    vif.sop   <= 1'b0;
    vif.eop   <= 1'b0;
    vif.valid <= 1'b0;
    vif.data  <= '0;
    vif.wr_en <= 1'b0;
  endfunction
endclass
