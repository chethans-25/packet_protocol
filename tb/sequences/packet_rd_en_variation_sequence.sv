class packet_rd_en_variation_sequence extends packet_read_base_sequence;
  `uvm_object_utils(packet_rd_en_variation_sequence)

  localparam int unsigned MAX_LOW_BURST = 3;

  rand bit random_rd_en;

  int unsigned rd_en_low_weight  = 40;
  int unsigned rd_en_high_weight = 60;
  int unsigned control_cycles    = 100;
  int unsigned rd_en_low_cycles;
  int unsigned rd_en_high_cycles;
  int unsigned rd_en_transitions;

  constraint c_random_rd_en {
    random_rd_en dist {
      1'b0 := rd_en_low_weight,
      1'b1 := rd_en_high_weight
    };
  }

  function new(string name = "packet_rd_en_variation_sequence");
    super.new(name);
  endfunction

  task body();
    int unsigned consecutive_low_cycles;
    int unsigned forced_low_cycle;
    bit previous_rd_en;
    bit have_previous_value;

    if (control_cycles < 2)
      `uvm_fatal("CONTROL_CYCLES",
                 "rd_en variation requires at least two control cycles")

    rd_en_low_cycles  = 0;
    rd_en_high_cycles = 0;
    rd_en_transitions = 0;
    consecutive_low_cycles = 0;
    have_previous_value = 1'b0;
    forced_low_cycle = control_cycles / 2;

    for (int unsigned i = 0; i < control_cycles; i++) begin
      if (!this.randomize(random_rd_en))
        `uvm_fatal("RANDOMIZE", "Could not randomize rd_en")

      // Guarantee visible variation near the middle of the stream. Limit all
      // other low bursts so ten maximum-size packets cannot fill the FIFO.
      if (i == forced_low_cycle-1)
        random_rd_en = 1'b1;
      else if (i == forced_low_cycle)
        random_rd_en = 1'b0;
      else if (consecutive_low_cycles >= MAX_LOW_BURST)
        random_rd_en = 1'b1;

      if (have_previous_value && random_rd_en != previous_rd_en)
        rd_en_transitions++;

      if (random_rd_en) begin
        rd_en_high_cycles++;
        consecutive_low_cycles = 0;
      end else begin
        rd_en_low_cycles++;
        consecutive_low_cycles++;
      end

      previous_rd_en = random_rd_en;
      have_previous_value = 1'b1;
      send_read_control(random_rd_en);
    end

    // The read driver retains the last requested level. Leave rd_en high so
    // every packet still in the FIFO drains after randomized backpressure.
    send_read_control(1'b1);
  endtask
endclass
