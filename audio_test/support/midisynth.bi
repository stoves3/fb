const m_pi=3.14159265358979323846

type sine_wave_generator
        declare sub set_cycle(cycle as single)
        declare sub add_modulation(x as long)
        declare function get_next() as integer
        declare function get_next(modulation as long) as integer

        position as unsigned long
        _step as unsigned long
end type

enum ADSR
   ATTACK
   ATTACK_RELEASE
   DECAY
   DECAY_RELEASE
   SUSTAIN
   RELEASE
   SOUNDOFF
   FINISHED 
end enum

type envelope_generator
        declare sub set_rate(rate as single)
        declare sub set_hold(value as single)
        declare sub set_freeze(value as single)
        declare sub key_off()
        declare sub sound_off()
        declare function get_next() as integer

        state as ADSR
        AR as integer
        DR as integer
        SR as integer
        RR as integer
        TL as integer
        fAR as unsigned long
        fDR as unsigned long
        fSR as unsigned long
        fRR as unsigned long
        fSL as unsigned long
        fTL as unsigned long
        _fOR as unsigned long
        fSS as unsigned long
        fDRR as unsigned long
        fDSS as unsigned long
        current as unsigned long
        rate as single
        hold as single
        freeze as single
        declare sub update_parameters()
end type

type fm_operator
        declare sub set_freq_rate(freq as single, rate as single)
        declare function get_next() as integer
        declare function get_next(modulate as integer) as integer
        declare function get_next(lfo as integer, modulate as integer) as integer

        swg as sine_wave_generator 
        eg as envelope_generator
        ML as single
        DT as single
        ams_factor as long
        ams_bias as long
end type

type fm_sound_generator
        declare sub set_rate(rate as single)
        declare sub set_frequency_multiplier(value as single)
        declare sub set_damper(damper as integer)
        declare sub set_sostenute(sostenute as integer)
        declare sub set_freeze(freeze as integer)
        declare sub set_tremolo(depth as integer, frequency as single)
        declare sub set_vibrato(depth as single, frequency as single)
        declare sub key_off()
        declare sub sound_off()
        declare function is_finished() as integer
        declare function get_next() as integer

        op1 as fm_operator
        op2 as fm_operator
        op3 as fm_operator
        op4 as fm_operator
        ams_lfo as sine_wave_generator
        vibrato_lfo as sine_wave_generator
        tremolo_lfo as sine_wave_generator
        ALG as integer
        FB as integer
        freq as single
        freq_mul as single
        ams_freq as single
        ams_enable as integer
        tremolo_depth as integer
        tremolo_freq as single
        vibrato_depth as integer
        vibrato_freq as single
        rate as single
        feedback as integer
        damper as integer
        sostenute as integer
end type


Type fm_note
        declare function synthesize(buf as long ptr, samples as uinteger, rate as single, _left as long, _right as long) as integer
        'declare sub note_off(velocity as integer) 
        'declare sub sound_off()
        'declare sub set_frequency_multiplier(value as single)
        'declare sub set_tremolo(depth as integer, freq as single)
        'declare sub set_vibrato(depth as single, freq as single) 
        'declare sub set_damper(value as integer)
        'declare sub set_sostenute(value as integer)
        'declare sub set_freeze(value as integer)

        declare sub release()

        assign as integer
        panpot as integer

        fm as fm_sound_generator
        velocity as integer

end type

type FMPARAMETEROP
        AR as integer
        DR as integer
        SR as integer
        RR as integer
        SL as integer
        TL as integer
        KS as integer
        ML as integer
        DT as integer
        AMS as integer
end type

type FMPARAMETER
        ALG as integer
        FB as integer
        LFO as integer
        op1 as FMPARAMETEROP
        op2 as FMPARAMETEROP
        op3 as FMPARAMETEROP
        op4 as FMPARAMETEROP
end type

type DRUMPARAMETER
        ALG as integer
        FB as integer
        LFO as integer
        op1 as FMPARAMETEROP
        op2 as FMPARAMETEROP
        op3 as FMPARAMETEROP
        op4 as FMPARAMETEROP
        key as integer
        panpot as integer
        assign as integer
end type


type fm_note_factory
        declare function note_on(program as long, note as integer, velocity as integer, frequency_multiplier as single) as fm_note ptr

        declare sub clear_

        programs(128) as FMPARAMETER ptr 
        drums(128) as DRUMPARAMETER ptr

end type

type _NOTES
   note as fm_note ptr
   key as integer
   status as integer

   _prev as _NOTES ptr
   _next as _NOTES ptr
end type

type channel:
        declare function synthesize(out as long ptr, samples as uinteger, rate as single, master_volume as long, master_balance as integer) as integer
        declare sub reset_all_parameters()
        declare sub reset_all_controller()
        declare sub all_note_off()
        declare sub all_sound_off()
        declare sub all_sound_off_immediately()

        declare sub note_off(note as integer, velocity as integer)
        declare sub note_on(note as integer, velocity as integer)
        declare sub polyphonic_key_pressure(note as integer, value as integer)
        declare sub channel_pressure(value as integer)
        declare sub control_change(control as integer, value as integer)
        declare sub bank_select(value as integer)

        declare sub set_damper(value as integer)
        declare sub set_sostenute(value as integer)
        declare sub set_freeze(value as integer)

        notes as _NOTES ptr
   _firstnote as _NOTES ptr
   _lastnote as _NOTES ptr      'Linked list

        factory as fm_note_factory ptr
        default_bank as integer
        program as integer
        bank as integer
        panpot as integer
        volume as integer
        expression as integer
        pressure as integer
        pitch_bend as integer
        pitch_bend_sensitivity as integer
        modulation_depth as integer
        modulation_depth_range as integer
        damper as integer
        sostenute as integer
        freeze as integer
        fine_tuning as integer
        coarse_tuning as integer
        RPN as integer
        NRPN as integer
        mono as integer
        mute as integer
        tremolo_frequency as single
        vibrato_frequency as single
        frequency_multiplier as single
        master_frequency_multiplier as single
        system_mode as integer

        declare function get_registered_parameter() as integer
        declare sub set_registered_parameter(value as integer)
        declare sub update_frequency_multiplier()
        declare sub update_modulation()
end type

type synthesizer
        declare function synthesize(_output as short ptr, samples as uinteger, rate as single) as integer
        declare function synthesize_mixing(_output as long ptr, samples as uinteger, rate as single) as integer
        declare sub reset()
        declare sub reset_all_parameters()
        declare sub reset_all_controller()
        declare sub all_note_off()
        declare sub all_sound_off()
        declare sub all_sound_off_immediately()

        declare sub sysex_message(pvdata as string)
        declare sub midi_event(_command as integer, param1 as integer, param2 as integer)

        declare sub set_system_mode(mode as integer)

        channels(15) as channel
        active_sensing as single
        main_volume as integer
        master_volume as integer
        master_balance as integer
        master_fine_tuning as integer
        master_coarse_tuning as integer
        master_frequency_multiplier as single
        system_mode as integer
        declare sub update_master_frequency_multiplier()
end type