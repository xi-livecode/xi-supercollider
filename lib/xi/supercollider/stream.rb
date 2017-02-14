require 'xi/stream'
require 'xi/osc'
require 'set'

module Xi::Supercollider
  class Stream < ::Stream
    include Xi::OSC

    BASE_SYNTH_ID = 1000

    def initialize(clock, server: 'localhost', port: 57110)
      super
      @playing_synths = [].to_set
    end

    def set(params)
      super(gate: params[:gate] || :freq, **params)
    end

    def stop
      @mutex.synchronize do
        @playing_synths.each { |id| set_synth(BASE_SYNTH_ID + id, gate: 0) }
      end
      super
    end

    private

    def do_gate_on_change(so_ids)
      logger.debug "Gate on change: #{so_ids}"
      name = @state[:s] || :default
      so_ids.each do |so_id|
        state_params = @state.reject { |k, _| %i(s).include?(k) }
        new_synth(name, BASE_SYNTH_ID + so_id, state_params)
        @playing_synths << so_id
      end
    end

    def do_gate_off_change(so_ids)
      logger.debug "Gate off change: #{so_ids}"
      so_ids.each do |so_id|
        set_synth(BASE_SYNTH_ID + so_id, gate: 0)
        @playing_synths.delete(so_id)
      end
    end

    def do_state_change
      logger.debug "State change: #{changed_state}"
      @playing_synths.each do |so_id|
        set_synth(BASE_SYNTH_ID + so_id, **changed_state)
      end
    end

    def set_synth(id, at: Time.now, **args)
      send_bundle('/n_set', id, *osc_args(args), at: at)
    end

    def new_synth(name, id, at: Time.now, **args)
      # '/s_new', synth_name (s), synth_id (i), node_action (i), target_id (i), *args (s, i)
      send_bundle('/s_new', name.to_s, id.to_i, 0, 1, *osc_args(args), at: at)
    end

    def free_synth(id, at: Time.now)
      send_bundle('/n_free', id, at: at)
    end

    def osc_args(**args)
      args.map { |k, v| [k.to_s, v] }.flatten(1)
    end
  end
end
