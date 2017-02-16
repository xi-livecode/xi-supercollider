module Xi::Supercollider
  module MusicParameters
    DEFAULT = {
      out:  0,
      amp:  1.0,
      freq: 440,
      pan:  0.0,
      vel:  127,
    }

    def transform_state
      super

      @state = DEFAULT.merge(@state)

      if changed_param?(:db) && !changed_param?(:amp)
        @state[:amp] = @state[:db].db_to_amp
        @changed_params << :amp
      end

      if changed_param?(:midinote) && !changed_param?(:freq)
        @state[:freq] = Array(@state[:midinote]).map(&:midi_to_cps)
        @changed_params << :freq
      end
    end
  end
end
