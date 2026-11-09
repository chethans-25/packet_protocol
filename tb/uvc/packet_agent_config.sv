typedef enum {
  PACKET_WRITE_SIDE,
  PACKET_READ_SIDE
} packet_agent_role_e;

class packet_agent_config extends uvm_object;
  `uvm_object_utils(packet_agent_config)

  uvm_active_passive_enum is_active = UVM_PASSIVE;
  packet_agent_role_e     role      = PACKET_WRITE_SIDE;
  virtual packet_if       vif;

  function new(string name = "packet_agent_config");
    super.new(name);
  endfunction

  function string role_name();
    return (role == PACKET_WRITE_SIDE) ? "write" : "read";
  endfunction
endclass
