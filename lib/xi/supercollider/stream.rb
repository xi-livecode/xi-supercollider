require 'xi/supercollider/music_parameters'
require 'xi/stream'
require 'xi/osc'
require 'set'

module Xi::Supercollider
  class Stream < Xi::Stream
    include Xi::OSC
    prepend MusicParameters

    BASE_SYNTH_ID = 1000

    def initialize(name, clock, server: 'localhost', port: 57110)
      super

      @playing_synths = [].to_set
      at_exit { free_playing_synths }
    end

    def set(params)
      super(gate: params[:gate] || :freq, **params)
    end

    def stop
      @mutex.synchronize do
        @playing_synths.each do |id|
          set_synth(BASE_SYNTH_ID + id, gate: 0)
        end
      end
      super
    end

    def free_playing_synths
      @playing_synths.each do |id|
        free_synth(BASE_SYNTH_ID + id)
      end
    end

    private

    def do_gate_on_change(changes)
      logger.debug "Gate on change: #{changes}"

      name = @state[:s] || :default
      state_params = @state.reject { |k, _| %i(s).include?(k) }

      changes.each do |change|
        at = Time.at(change.fetch(:at))

        change.fetch(:so_ids).each do |id|
          new_synth(name, BASE_SYNTH_ID + id, **state_params, at: at)
          @playing_synths << id
        end
      end
    end

    def do_gate_off_change(changes)
      logger.debug "Gate off change: #{changes}"

      changes.each do |change|
        at = Time.at(change.fetch(:at))

        change.fetch(:so_ids).each do |id|
          set_synth(BASE_SYNTH_ID + id, gate: 0, at: at)
          @playing_synths.delete(id)
        end
      end
    end

    def do_state_change
      logger.debug "State change: #{changed_state}"
      @playing_synths.each do |id|
        set_synth(BASE_SYNTH_ID + id, **changed_state)
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
