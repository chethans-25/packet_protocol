class packet_read_driver extends uvm_driver #(packet_read_control_item);
  `uvm_component_utils(packet_read_driver)

  packet_agent_config cfg;
  virtual packet_if vif;

  function new(string name = "packet_read_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(packet_agent_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("NO_CFG", {get_full_name(), ": packet_agent_config was not configured"})
    if (cfg.vif == null)
      `uvm_fatal("NO_VIF", {get_full_name(), ": cfg.vif is null"})
    if (cfg.is_active != UVM_ACTIVE || cfg.role != PACKET_READ_SIDE)
      `uvm_fatal("BAD_READ_CFG",
                 "packet_read_driver requires an active read-side configuration")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    packet_read_control_item req;

    vif.rd_en <= 1'b0;

    forever begin
      seq_item_port.get_next_item(req);
      drive_read_control(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_read_control(packet_read_control_item item);
    while (vif.rst)
      @(negedge vif.clk);

    repeat (item.cycles) begin
      @(negedge vif.clk);
      vif.rd_en <= item.rd_en;
    end
  endtask
endclass
