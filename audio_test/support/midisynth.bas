'
 ' Copyright(c)2007 yuno  --- Port to FreeBasic by Angelo Rosina
 ' 
 ' This software is provided 'as-is', without any express or implied warranty.
 ' In no event will the authors be held liable for any damages arising from the
 ' use of this software.
 ' 
 ' Permission is granted to anyone to use this software for any purpose,
 ' including commercial applications, and to alter it and redistribute it
 ' freely, subject to the following restrictions:
 ' 
 ' 1. The origin of this software must not be misrepresented; you must not claim
 ' that you wrote the original software. If you use this software in a product,
 ' an acknowledgment in the product documentation would be appreciated but is
 ' not required.
 ' 
 ' 2. Altered source versions must be plainly marked as such, and must not be
 ' misrepresented as being the original software.
 ' 
 ' 3. This notice may not be removed or altered from any source distribution.
 '


const LOG10_32767=4.5154366811416989472479934140484
const LOGTABLE_FACTOR=(4096 / LOG10_32767)

dim shared as short sine_table(4095)
dim shared as unsigned short log_table(4095)

type _envelope_table
     TL(127) as unsigned long
     SL(15,127) as unsigned long
     AR(63,127) as double
     RR(63,127) as double
end type

dim shared envelope_table as _envelope_table
dim shared as long vibrato_table(16383)

#include once "midisynth.bi"
#include once "instruments.bi"

sub InitTables() constructor
        for i as integer= 0 to 4095
            sine_table(i) = cast(short, sin(i * 2 * M_PI / 4096)*32767)
            log_table(i) = 10^ (cast(double,i) / LOGTABLE_FACTOR)
        next
        for t as integer=0 to 127
            dim as double fTL = 32767 * 10^(t * -0.75 / 10)
            envelope_table.TL(t) = fTL
            if envelope_table.TL(t) = 0 then
                envelope_table.TL(t) = 1
            end if
            for s as integer = 0 to 15
                dim as double x = fTL * 10^(s * -3.0 / 10)
                if x <= 1 then
                    envelope_table.SL(s,t) = 0
                else
                    envelope_table.SL(s,t) = 65536 * LOGTABLE_FACTOR * (log(x)/log(10))
                end if
            next
        next
        for x as integer = 0 to 63
            dim as double attack_time = 15.3262 * 10^(x * -0.75 / 10)
            dim as double release_time = 211.84 * 10^(x * -0.75 / 10)
            for t as integer = 0 to 127
                envelope_table.AR(x,t) = envelope_table.TL(t) / attack_time
                envelope_table.RR(x,t) = 65536 * LOGTABLE_FACTOR * 48.0 / 10 * envelope_table.TL(t) / 32767 / release_time
            next
        next
        for i as integer= 0 to 16383
            dim x as double = (cast(double,i) / 16384 - 0.5) * 256.0 / 12.0
            vibrato_table(i) = cast(long,(2^x - 1) * 65536.0)
        next


end sub


function channel.synthesize(out as long ptr, samples as uinteger, rate as single, master_volume as long, master_balance as integer) as integer
        dim volume as double
        if mute=0 then volume = (cast(double,master_volume) * this.volume * expression / (16383.0 * 16383.0 * 16383.0))^ 2 * 16383.0
        dim num_notes as integer
        dim i as _NOTES ptr= _firstnote
        while(i <> 0)
            dim as fm_note ptr note = i->note
            dim as ulong panpot = note->panpot
            if this.panpot <= 8192 then
                panpot = panpot * this.panpot / 8192
            else
                panpot = panpot * (16384 - this.panpot) / 8192 + (this.panpot - 8192) * 2
            end if
            if master_balance <= 8192 then
                panpot = panpot * master_balance / 8192
            else
                panpot = panpot * (16384 - master_balance) / 8192 + (master_balance - 8192) * 2
            end if

            if panpot<1 then panpot=0 else panpot-=1
            dim as long _left = cast(long,volume * cos(panpot * (M_PI / 2 / 16382)))
            dim as long _right = cast(long,volume * sin(panpot * (M_PI / 2 / 16382)))
            dim as integer ret = note->synthesize(out, samples, rate, _left, _right)
            if ret then
                i=i->_next
            else
                if i=this._firstnote then this._firstnote=i->_next
                if i=this._lastnote then this._lastnote=i->_prev
                if i->_next<>0 then i->_next->_prev=i->_prev
                if i->_prev<>0 then i->_prev->_next=i->_next

                delete note
                dim old as _NOTES ptr= i->_next
      delete i
                i=old
            end if
            num_notes+=1
        wend
        return num_notes
end function

sub channel.reset_all_parameters()
        program = default_bank * 128
        bank = default_bank
        panpot = 8192
        volume = 12800
        fine_tuning = 8192
        coarse_tuning = 8192
        tremolo_frequency = 3
        vibrato_frequency = 3
        master_frequency_multiplier = 1
        mono = 0
        mute = 0
        system_mode = 0'system_mode_default
        reset_all_controller()
end sub

sub channel.reset_all_controller()
        expression = 16383
        channel_pressure(0)
        pitch_bend = 8192
        pitch_bend_sensitivity = 256
        update_frequency_multiplier()
        modulation_depth = 0
        modulation_depth_range = 64
        update_modulation()
        set_damper(0)
        set_sostenute(0)
        set_freeze(0)
        RPN = &H3FFF
        NRPN = &H3FFF
end sub

sub channel.all_note_off()
   dim as _NOTES ptr i=this._firstnote
   do until i=0
            if i->status = 1 then
                i->status = 0
                i->note->fm.key_off()
            end if
            i=i->_next
        loop
end sub

sub channel.all_sound_off()
   dim as _NOTES ptr i=this._firstnote
   do until i=0
            if i->status <> -1 then
                i->status = -1
                i->note->fm.sound_off()
            end if
            i=i->_next
        loop
end sub

sub channel.all_sound_off_immediately()
   dim as _NOTES ptr i=this._firstnote
   do until i=0
            delete i->note
            i=i->_next
            if i->_prev<>0 then delete i->_prev
        loop
        this._firstnote=0
        this._lastnote=0
end sub

sub channel.note_on(note as integer, velocity as integer)

        note_off(note, 64)
        if velocity then
            if mono then
                all_sound_off()
            end if
            dim as fm_note ptr p = factory->note_on(program, note, velocity, frequency_multiplier)
            if p<>0 then
                dim as integer assign = p->assign
                if assign<>0 then
                    dim as _NOTES ptr i=this._firstnote
                    do until i=0
                        if i->note->assign = assign then
                            i->note->fm.sound_off()
                        end if
                        i=i->_next
                    loop
                end if
                if freeze then
                    p->fm.set_freeze(freeze)
                end if
                if damper then
                    p->fm.set_damper(damper)
                end if
                if modulation_depth then
                    dim as single depth = cast(double,modulation_depth) * modulation_depth_range / (16383.0 * 128.0)
                    p->fm.set_vibrato(depth, vibrato_frequency)
                end if
                if pressure then
                    p->fm.set_tremolo(pressure, tremolo_frequency)
                end if

                dim as _NOTES ptr pp=new _NOTES:
                pp->note=p: pp->key=note: pp->status=1
                if this._firstnote=0 then this._firstnote=pp:this._lastnote=pp else pp->_prev=this._lastnote:this._lastnote->_next=pp
                this._lastnote=pp

            end if
        end if
end sub

sub channel.note_off(note as integer, velocity as integer)
   dim as _NOTES ptr i=this._firstnote
   do until i=0
            if i->key = note andalso i->status = 1 then
                i->status = 0
                i->note->fm.key_off()
            end if
            i=i->_next
        loop
end sub

sub channel.polyphonic_key_pressure(note as integer, value as integer)
   dim as _NOTES ptr i=this._firstnote
   do until i=0
            if i->key = note andalso i->status = 1 then
                i->note->fm.set_tremolo(value, tremolo_frequency)
            end if
            i=i->_next
        loop
end sub

sub channel.channel_pressure(value as integer)
        if pressure <> value then
            pressure = value
       dim as _NOTES ptr i=this._firstnote
       do until i=0
                if i->status = 1 then
                    i->note->fm.set_tremolo(value, tremolo_frequency)
                end if
                i=i->_next
            loop
        end if
end sub

sub channel.control_change(control as integer, value as integer)
        select case control
        case &H00
            bank_select((bank and &H7F) or (value shl 7))
        case &H01
            modulation_depth=(modulation_depth and &H7F) or (value shl 7)
            update_modulation()
        case &H06
            set_registered_parameter((get_registered_parameter() and &H7F) or (value shl 7))
        case &H07
            volume = (volume and &H7F) or (value shl 7)
        case &H0A
            panpot = (panpot and &H7F) or (value shl 7)
        case &H0B
            expression = (expression and &H7F) or (value shl 7)
        case &H20
            bank_select((bank and &H7F) or (value shl 7))
        case &H21
            modulation_depth=(modulation_depth and not &H7F) or value
            update_modulation()
        case &H26
            set_registered_parameter((get_registered_parameter() and not &H7F) or value)
        case &H27
            volume = (volume and not &H7F) or value
        case &H2A
            panpot = (panpot and not &H7F) or value
        case &H2B
            expression = (expression and not &H7F) or value
        case &H40
            set_damper(value)
        case &H42
            set_sostenute(value)
        case &H45
            set_freeze(value)
        case &H60
            if get_registered_parameter() + 1>&H3FFF then
               set_registered_parameter(get_registered_parameter() + 1)
            else
               set_registered_parameter(&H3FFF)
            end if
        case &H61
            if get_registered_parameter() - 1<0 then
               set_registered_parameter(get_registered_parameter() - 1)
            else
               set_registered_parameter(0)
            end if
        case &H62
            NRPN=(NRPN and not &H7F) or value
            RPN = &H3FFF
        case &H63
            NRPN=(NRPN and &H7F) or (value shl 7)
            RPN = &H3FFF
        case &H64
            RPN=(RPN and not &H7F) or value
            NRPN = &H3FFF
        case &H65
            RPN=(RPN and &H7F) or (value shl 7)
            NRPN = &H3FFF
        case &H78
            all_sound_off()
        case &H79
            reset_all_controller()
        case &H7B, &H7C, &H7D
            all_note_off()
        case &H7E
            all_note_off(): mono = 1
        case &H7F
            all_note_off(): mono = 0
        end select
end sub

sub channel.bank_select(value as integer)
        select case system_mode
        case 1
        case 3
            if ((bank and &H3F80) = &H3C00) = ((value and &H3F80) = &H3C00) then
                bank=value
            end if
        case 4
            if default_bank = &H3C00 then
                bank=&H3C00 or (value and &H7F)
            elseif (value and &H3F80) = &H3F80 then
                bank=&H3C00 or (value and &H7F)
            else
                bank=value
            end if
        case else
            if default_bank = &H3C00 then
                bank=&H3C00 or (value and &H7F)
            else
                bank=value
            end if
        end select
end sub

sub channel.set_damper(value as integer)
        if damper <> value then
            damper = value
       dim as _NOTES ptr i=this._firstnote
       do until i=0
                i->note->fm.set_damper(value)
                i=i->_next
            loop
            
        end if
end sub

sub channel.set_sostenute(value as integer)
        sostenute = value
   dim as _NOTES ptr i=this._firstnote
   do until i=0
            i->note->fm.set_sostenute(value)
            i=i->_next
        loop
end sub

sub channel.set_freeze(value as integer)
        if freeze <> value then
            freeze = value
       dim as _NOTES ptr i=this._firstnote
       do until i=0
                i->note->fm.set_freeze(value)
                i=i->_next
            loop
        end if
end sub

function channel.get_registered_parameter() as integer
        select case RPN
        case &H0000
            return pitch_bend_sensitivity
        case &H0001
            return fine_tuning
        case &H0002
            return coarse_tuning
        case &H0005
            return modulation_depth_range
        case else
            return 0
        end select
end function

sub channel.set_registered_parameter(value as integer)
        select case RPN
        case &H0000
            pitch_bend_sensitivity=value
            update_frequency_multiplier()
        case &H0001
            fine_tuning=value
            update_frequency_multiplier()
        case &H0002
            coarse_tuning=value
            update_frequency_multiplier()
        case &H0005
            modulation_depth_range=value
            update_modulation()
        case else
        end select
end sub

sub channel.update_frequency_multiplier()
        dim as single value = master_frequency_multiplier * _
                    2^ ((coarse_tuning - 8192) / (128.0 * 100.0 * 12.0) _
                                + (fine_tuning - 8192) / (8192.0 * 100.0 * 12.0) _
                                + cast(double,pitch_bend - 8192) * pitch_bend_sensitivity / (8192.0 * 128.0 * 12.0))
        if frequency_multiplier <> value then
            frequency_multiplier = value
       dim as _NOTES ptr i=this._firstnote
       do until i=0
                i->note->fm.set_damper(value)
                i->note->fm.set_frequency_multiplier(value)
                i=i->_next
            loop
        end if
end sub

sub channel.update_modulation()
        dim as single depth = cast(double,modulation_depth) * modulation_depth_range / (16383.0 * 128.0)
   dim as _NOTES ptr i=this._firstnote
   do until i=0
            i->note->fm.set_vibrato(depth, vibrato_frequency)
            i=i->_next
        loop
end sub

function synthesizer.synthesize(_output as short ptr, samples as uinteger, rate as single) as integer
        dim as uinteger n = samples * 2
        dim as long buf(n+1)
        dim as integer num_notes = synthesize_mixing(@buf(0), samples, rate)
        if num_notes then
            for i as uinteger = 0 to n
                dim as long x = buf(i)
                if x < -32767 then
                    _output[i] = -32767
                elseif x > 32767 then
                    _output[i] = 32767
                else
                    _output[i] = x
                end if
            next
        else
            clear _output[0], 0, len(short) * n
        end if
        return num_notes
end function

function synthesizer.synthesize_mixing(_output as long ptr, samples as uinteger, rate as single) as integer
        if active_sensing = 0 then
            all_sound_off()
            active_sensing = -1
        elseif active_sensing > 0 then
            active_sensing -= samples / rate
            if active_sensing < 0 then active_sensing=0
        end if
        dim as long volume = cast(long,main_volume) * master_volume / 16384
        dim as integer num_notes = 0
        for i as integer = 0 to 15
            num_notes += channels(i).synthesize(_output, samples, rate, volume, master_balance)
        next
        return num_notes
end function

sub synthesizer.reset()
   for i as integer=0 to 15
      if channels(i).factory=0 then channels(i).factory= new fm_note_factory
      for a as integer=0 to 128
         channels(i).factory->programs(a)=@programs(a)
      next
      for a as integer=35 to 81
         channels(i).factory->drums(a)=@drums(a)
      next

   next

        all_sound_off_immediately()
        reset_all_parameters()
end sub

sub synthesizer.reset_all_parameters()
        active_sensing = -1
        main_volume = 8192
        master_volume = 16383
        master_balance = 8192
        master_fine_tuning = 8192
        master_coarse_tuning = 8192
        master_frequency_multiplier = 1
        system_mode = 0
        for i as integer = 0 to 15
            channels(i).reset_all_parameters()
        next
end sub

sub synthesizer.reset_all_controller()
        for i as integer = 0 to 15
            channels(i).reset_all_controller()
        next
end sub

sub synthesizer.all_note_off()
        for i as integer = 0 to 15
            channels(i).all_note_off()
        next
end sub

sub synthesizer.all_sound_off()
        for i as integer = 0 to 15
            channels(i).all_sound_off()
        next
end sub

sub synthesizer.all_sound_off_immediately()
        for i as integer = 0 to 15
            channels(i).all_sound_off_immediately()
        next
end sub

sub synthesizer.sysex_message(pvdata as string)
        if left(pvdata,6)= !"\xF0\x7E\x7F\x09\x01\xF7" then
            ' GM system on 
            set_system_mode(1)
        elseif left(pvdata,6) =!"\xF0\x7E\x7F\x09\x02\xF7" then
            ' GM system off 
            set_system_mode(2)
        elseif left(pvdata,6)=!"\xF0\x7E\x7F\x09\x03\xF7" then
            ' GM2 system on 
            set_system_mode(2)
        elseif left(pvdata,2)= !"\xF0\x41" andalso mid(pvdata,4,8)= !"\x42\x12\x40\x00\x7F\x00\x41\xF7" then
            ' GS reset 
            set_system_mode(3)
        elseif left(pvdata,2)= !"\xF0\x43" andalso (asc(pvdata,3) and &HF0) = &H10 andalso mid(pvdata, 4, 6)= !"\x4C\x00\x00\x7E\x00\xF7" then
            ' XG system on 
            set_system_mode(4)
        elseif left(pvdata, 5) =!"\xF0\x7F\x7F\x04\x01" andalso asc(pvdata,8) = &HF7 then
            ' master volume 
            master_volume=(asc(pvdata,6) and &H7F) or ((asc(pvdata,7) and &H7F) shl 7)
        elseif left(pvdata,5) = !"\xF0\x7F\x7F\x04\x02" andalso asc(pvdata,8) = &HF7 then
            ' master balance 
            master_balance=(asc(pvdata,6) and &H7F) or ((asc(pvdata,7) and &H7F) shl 7)
        elseif left(pvdata,5) = !"\xF0\x7F\x7F\x04\x03" andalso asc(pvdata,8) = &HF7 then
            ' master fine tuning 
            master_fine_tuning=(asc(pvdata,6) and &H7F) or ((asc(pvdata,7) and &H7F) shl 7)
            update_master_frequency_multiplier()
        elseif left(pvdata,5) = !"\xF0\x7F\x7F\x04\x04" andalso asc(pvdata,8) = &HF7 then
            ' master coarse tuning 
            master_coarse_tuning=(asc(pvdata,6) and &H7F) or ((asc(pvdata,7) and &H7F) shl 7)
            update_master_frequency_multiplier()
        elseif left(pvdata, 2) = !"\xF0\x41" andalso (asc(pvdata,3) and &HF0) = &H10 andalso mid(pvdata, 4, 3) = !"\x42\x12\x40"andalso (asc(pvdata,7) and &HF0) = &H10 andalso asc(pvdata,8) = &H15 andalso asc(pvdata,11) = &HF7 then
            ' use for rhythm part 
            dim as integer _channel = asc(pvdata,7) and &H0F
            if asc(pvdata,9) = 0 then
                channels(_channel).bank=&H3C80
            else
                channels(_channel).bank=&H3C00
            end if
            channels(_channel).program=128*channels(_channel).bank
        end if
end sub

sub synthesizer.midi_event(event as integer, param1 as integer, param2 as integer)
        select case (event and &HF0)
        case &H80
            channels(event and &H0F).note_off(param1 and &H7F, param2 and &H7F)
        case &H90
            channels(event and &H0F).note_on(param1 and &H7F, param2 and &H7F)
        case &HA0
            channels(event and &H0F).polyphonic_key_pressure(param1 and &H7F, param2 and &H7F)
        case &HB0
            channels(event and &H0F).control_change(param1 and &H7F, param2 and &H7F)
        case &HC0
            channels(event and &H0F).program=(param1 and &H7F)+128*channels(event and &H0F).bank
        case &HD0
            channels(event and &H0F).channel_pressure(param1 and &H7F)
        case &HE0
            channels(event and &H0F).pitch_bend=((param2 and &H7F) shl 7) or (param1 and &H7F)
            channels(event and &H0F).update_frequency_multiplier()
        case &HFE
            active_sensing = 0.33
        case &HFF
            all_sound_off()
            reset_all_parameters()
        case else
        end select
end sub

sub synthesizer.set_system_mode(mode as integer)
        all_sound_off()
        reset_all_parameters()
        system_mode = mode
        for i as integer=0 to 15
            channels(i).system_mode=mode
        next
end sub

sub synthesizer.update_master_frequency_multiplier()
        dim as single value = 2^( (master_coarse_tuning - 8192) / (128.0 * 100.0 * 12.0)_
                                + (master_fine_tuning - 8192) / (8192.0 * 100.0 * 12.0))
        if master_frequency_multiplier <> value then
            master_frequency_multiplier = value
            for i as integer=0 to 15
                channels(i).master_frequency_multiplier=value
                channels(i).update_frequency_multiplier
            next
        end if
end sub

sub sine_wave_generator.set_cycle(cycle as single)
        if cycle<>0 then
            _step = cast(unsigned long, 4096.0 * 32768.0 / cycle)
        else
            _step = 0
        end if
end sub

sub sine_wave_generator.add_modulation(x as long)
        position += cast(long, cast(longint, _step) * x shr 16)
end sub

function sine_wave_generator.get_next() as integer
        position += _step
        return sine_table((position / 32768) mod 4096)
end function

function sine_wave_generator.get_next(modulation as long) as integer
        position += _step
        dim as long m = modulation * 4096 / 65536
        dim as ulong p = cast(ulong,(position  / 32768 + m)) mod 4096
        return sine_table(p)
end function

sub envelope_generator.set_rate(rate as single)
        if rate<>0 then this.rate = rate else this.rate=1
        update_parameters()
end sub

sub envelope_generator.set_hold(hold as single)
        if this.hold > hold orelse state <= SUSTAIN orelse current >= fSL then
            this.hold = hold
            update_parameters()
        end if
end sub

sub envelope_generator.set_freeze(freeze as single)
        if this.freeze > freeze orelse state <= SUSTAIN orelse current >= fSL then
            this.freeze = freeze
            update_parameters()
        end if
end sub

sub envelope_generator.update_parameters()
        dim as double fAR = envelope_table.AR(AR,TL) / rate
        dim as double fDR = envelope_table.RR(DR,TL) / rate
        dim as double fSR = envelope_table.RR(SR,TL) / rate
        dim as double fRR = envelope_table.RR(RR,TL) / rate

        if fRR < 1 then
            fRR = 1
        end if
        if hold > 0 then
            fRR = fSR * hold + fRR * (1 - hold)
        end if
        if freeze > 0 then
            fDR *= 1 - freeze
            fSR *= 1 - freeze
            fRR *= 1 - freeze
        end if
        if fAR < 1 then
            fAR = 1
        end if
        this.fAR = cast(unsigned long,fAR)
        this.fDR = cast(unsigned long,fDR)
        this.fSR = cast(unsigned long,fSR)
        this.fRR = cast(unsigned long,fRR)
        this._fOR = cast(unsigned long,envelope_table.RR(63,0) / rate)
        if this.fDR>fSL then this.fSS = this.fDR else this.fSS = fSL
        if this.fDR>this.fRR then this.fDRR = this.fDR else this.fDRR = this.fRR
        if this.fDRR>this.fSS then this.fDSS = this.fDRR else this.fDSS = this.fSS
end sub

sub envelope_generator.key_off()
        select case state
        case ATTACK
            state = ATTACK_RELEASE
        case DECAY
            state = DECAY_RELEASE
        case SUSTAIN
            state = RELEASE
        case else
        end select
end sub

sub envelope_generator.sound_off()
        select case state
        case ATTACK, ATTACK_RELEASE
            if current<>0 then
                current = 65536 * LOGTABLE_FACTOR * log(cast(double,current))/log(10)
            end if
        case else
        end select
        state = SOUNDOFF
end sub

function envelope_generator.get_next() as integer
        dim as unsigned long current = this.current
        select case state
        case ATTACK
            if current < fTL then
                this.current = current + fAR
                return this.current
            end if
            this.current = 65536 * LOGTABLE_FACTOR * log(cast(double,fTL))/log(10)
            state = DECAY
            return fTL
        case DECAY
            if current > fSS then
                current -= fDR
                this.current = current
                return log_table(current / 65536)
            end if
            current = fSL
            this.current = current
            state = SUSTAIN
            return log_table(current / 65536)
        case SUSTAIN
            if current > fSR then
                current -= fSR
                this.current = current
                dim n as integer = log_table(current / 65536)
                if n > 1 then
                    return n
                end if
            end if
            state = FINISHED
            return 0
        case ATTACK_RELEASE
            if current < fTL then
                this.current = current + fAR
                return this.current
            end if
            this.current = 65536 * LOGTABLE_FACTOR * log(cast(double,fTL))/log(10)
            state = DECAY_RELEASE
            return fTL
        case DECAY_RELEASE
            if current > fDSS then
                current -= fDRR
                this.current = current
                return log_table(current / 65536)
            end if
            current = fSL
            this.current = current 
            state = RELEASE
            return log_table(current / 65536)
        case RELEASE
            if current > fRR then
                current -= fRR
                this.current = current
                dim n as integer = log_table(current / 65536)
                if n > 1024 then
                    return n
                end if
                state = SOUNDOFF
                return n
            end if
            state = FINISHED
            return 0
        case SOUNDOFF
            if current > _fOR then
                current -= _fOR
                this.current = current
                dim n as integer = log_table(current / 65536)
                if n > 1 then
                    return n
                end if
            end if
            state = FINISHED
            return 0
        case else
            return 0
        end select
end function

dim shared as integer keyscale_table(3,127) = {_
            {_
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,_
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,_
                 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,_
                 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2,_
                 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,_
                 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,_
                 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,_
                 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3_
            }, {_
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,_
                 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1,_
                 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,_
                 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4,_
                 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5,_
                 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,_
                 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,_
                 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7_
            }, {_
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,_
                 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2,_
                 2, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5,_
                 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 8, 8, 8, 8,_
                 8, 8, 8, 8, 8, 9, 9, 9,10,10,10,10,10,10,10,10,_
                10,11,11,11,12,12,12,12,12,12,12,12,12,13,13,13,_
                14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,_
                15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15_
            }, {_
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,_
                 0, 0, 0, 1, 1, 2, 2, 3, 4, 4, 4, 4, 4, 4, 4, 5,_
                 5, 6, 6, 7, 8, 8, 8, 8, 8, 8, 8, 9, 9,10,10,11,_
                12,12,12,12,12,12,12,13,13,14,14,15,16,16,16,16,_
                16,16,16,17,17,18,18,19,20,20,20,20,20,20,20,21,_
                21,22,22,23,24,24,24,24,24,24,24,25,25,26,26,27,_
                28,28,28,28,28,28,28,29,29,30,30,31,31,31,31,31,_
                31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31_
            }}
dim shared as single detune_table(3,127) = {_
            { 0 },_
            {_
                0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,_
                0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,_
                0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,_
                0.053, 0.053, 0.053, 0.053, 0.053, 0.053, 0.053, 0.053,_
                0.053, 0.053, 0.053, 0.053, 0.053, 0.053, 0.053, 0.053,_
                0.053, 0.053, 0.053, 0.053, 0.053, 0.053, 0.053, 0.053,_
                0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106,_
                0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106,_
                0.106, 0.106, 0.106, 0.159, 0.159, 0.159, 0.159, 0.159,_
                0.212, 0.212, 0.212, 0.212, 0.212, 0.212, 0.212, 0.212,_
                0.212, 0.212, 0.212, 0.264, 0.264, 0.264, 0.264, 0.264,_
                0.264, 0.264, 0.264, 0.317, 0.317, 0.317, 0.317, 0.370,_
                0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423,_
                0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423,_
                0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423,_
                0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423_
            }, {_
                0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,_
                0.000, 0.000, 0.000, 0.000, 0.000, 0.053, 0.053, 0.053,_
                0.053, 0.053, 0.053, 0.053, 0.053, 0.053, 0.053, 0.053,_
                0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106,_
                0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106,_
                0.106, 0.106, 0.106, 0.106 ,0.106, 0.159, 0.159, 0.159,_
                0.212, 0.212, 0.212, 0.212, 0.212, 0.212, 0.212 ,0.212,_
                0.212, 0.212, 0.212, 0.264, 0.264, 0.264, 0.264, 0.264,_
                0.264, 0.264, 0.264, 0.317, 0.317, 0.317, 0.317, 0.370,_
                0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423, 0.423,_
                0.423, 0.476, 0.476, 0.529, 0.582, 0.582, 0.582, 0.582,_
                0.582, 0.582 ,0.582, 0.635, 0.635, 0.688, 0.688, 0.741,_
                0.846, 0.846, 0.846, 0.846, 0.846, 0.846, 0.846 ,0.846,_
                0.846, 0.846, 0.846, 0.846, 0.846, 0.846, 0.846, 0.846,_
                0.846, 0.846, 0.846, 0.846, 0.846, 0.846, 0.846, 0.846_
            }, {_
                0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000,_
                0.000, 0.000, 0.000, 0.000, 0.000, 0.106, 0.106, 0.106,_
                0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106,_
                0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.106, 0.159,_
                0.159, 0.159, 0.159, 0.159, 0.212, 0.212, 0.212, 0.212,_
                0.212, 0.212, 0.212, 0.212, 0.212, 0.212, 0.212, 0.264,_
                0.264, 0.264, 0.264, 0.264, 0.264, 0.264, 0.264, 0.317,_
                0.317, 0.317, 0.317, 0.370, 0.423, 0.423, 0.423, 0.423,_
                0.423, 0.423, 0.423, 0.423, 0.423, 0.476, 0.476, 0.529,_
                0.582, 0.582, 0.582, 0.582, 0.582, 0.582, 0.582, 0.635,_
                0.635, 0.688, 0.688, 0.741, 0.846, 0.846, 0.846, 0.846,_
                0.846, 0.846, 0.846, 0.899, 0.899, 1.005, 1.005, 1.058,_
                1.164, 1.164, 1.164, 1.164, 1.164, 1.164, 1.164, 1.164,_
                1.164, 1.164, 1.164, 1.164, 1.164, 1.164, 1.164, 1.164,_
                1.164, 1.164, 1.164, 1.164, 1.164, 1.164, 1.164, 1.164,_
                1.164, 1.164, 1.164, 1.164, 1.164, 1.164, 1.164, 1.164_
            }}
dim shared as unsigned long ams_table(3) = {_
            0,_
            128 - 128 * 10^(-1.44 / 10),_
            128 - 128 * 10^(-5.9 / 10),_
            128 - 128 * 10^(-11.8 / 10)_
        }

sub fm_operator.set_freq_rate(freq as single, rate as single)
        freq += DT
        freq *= ML
        swg.set_cycle(rate / freq)
        eg.set_rate(rate)
end sub

function fm_operator.get_next() as integer
        return cast(long,swg.get_next()) * eg.get_next() shr 15
end function

function fm_operator.get_next(modulate as integer) as integer
        return cast(long,swg.get_next(modulate)) * eg.get_next() shr 15
end function

function fm_operator.get_next(ams as integer, modulate as integer) as integer
        return (cast(long,swg.get_next(modulate)) * eg.get_next() shr 15) * (ams * ams_factor + ams_bias) shr 15
end function

sub fm_sound_generator.set_rate(rate as single)
        if this.rate <> rate then
            this.rate = rate
            ams_lfo.set_cycle(rate / ams_freq)
            vibrato_lfo.set_cycle(rate / vibrato_freq)
            tremolo_lfo.set_cycle(rate / tremolo_freq)
            dim as single f = freq * freq_mul
            op1.set_freq_rate(f, rate)
            op2.set_freq_rate(f, rate)
            op3.set_freq_rate(f, rate)
            op4.set_freq_rate(f, rate)
        end if
end sub

sub fm_sound_generator.set_frequency_multiplier(value as single)
        freq_mul = value
        dim as single f = freq * freq_mul
        op1.set_freq_rate(f, rate)
        op2.set_freq_rate(f, rate)
        op3.set_freq_rate(f, rate)
        op4.set_freq_rate(f, rate)
end sub

sub fm_sound_generator.set_damper(damper as integer)
        this.damper = damper
        dim as single value = 1.0 - (1.0 - damper / 127.0) * (1.0 - sostenute / 127.0)
        op1.eg.set_hold(value)
        op2.eg.set_hold(value)
        op3.eg.set_hold(value)
        op4.eg.set_hold(value)
end sub

sub fm_sound_generator.set_sostenute(sostenute as integer)
        this.sostenute = sostenute
        dim as single value = 1.0 - (1.0 - damper / 127.0) * (1.0 - sostenute / 127.0)
        op1.eg.set_hold(value)
        op2.eg.set_hold(value)
        op3.eg.set_hold(value)
        op4.eg.set_hold(value)
end sub

sub fm_sound_generator.set_freeze(freeze as integer)
        dim as single value = freeze / 127.0
        op1.eg.set_freeze(value)
        op2.eg.set_freeze(value)
        op3.eg.set_freeze(value)
        op4.eg.set_freeze(value)
end sub

sub fm_sound_generator.set_tremolo(depth as integer, frequency as single)
        tremolo_depth = depth
        tremolo_freq = frequency
        tremolo_lfo.set_cycle(rate / frequency)
end sub

sub fm_sound_generator.set_vibrato(depth as single, frequency as single)
        vibrato_depth = depth * (16384 / 256.0)
        vibrato_freq = frequency
        vibrato_lfo.set_cycle(rate / frequency)
end sub

sub fm_sound_generator.key_off()
        op1.eg.key_off()
        op2.eg.key_off()
        op3.eg.key_off()
        op4.eg.key_off()
end sub

sub fm_sound_generator.sound_off()
        op1.eg.sound_off()
        op2.eg.sound_off()
        op3.eg.sound_off()
        op4.eg.sound_off()
end sub

function fm_sound_generator.is_finished() as integer
        select case ALG
        case 0 to 3
            return op4.eg.state=FINISHED
        case 4
            return op2.eg.state=FINISHED andalso op4.eg.state=FINISHED
        case 5,6
            return op2.eg.state=FINISHED andalso op3.eg.state=FINISHED andalso op4.eg.state=FINISHED
        case 7
            return op1.eg.state=FINISHED andalso op2.eg.state=FINISHED andalso op3.eg.state=FINISHED andalso op4.eg.state=FINISHED
        case else
            return -1
        end select
end function

function fm_sound_generator.get_next() as integer
        if vibrato_depth<>0 then
            dim as integer x = cast(long,vibrato_lfo.get_next()) * vibrato_depth shr 15
            dim as long modulation = vibrato_table(x+16384/2)
            op1.swg.add_modulation(modulation)
            op2.swg.add_modulation(modulation)
            op3.swg.add_modulation(modulation)
            op4.swg.add_modulation(modulation)
        end if
        dim as integer feedback = (this.feedback shl 1) shr FB
        dim as integer ret
        if ams_enable then
            dim as integer ams = ams_lfo.get_next() shr 7
            select case ALG
            case 0
                this.feedback = op1.get_next(ams, feedback)
                ret = op4.get_next(ams, op3.get_next(ams, op2.get_next(ams, this.feedback)))
            case 1
                this.feedback = op1.get_next(ams, feedback)
                ret = op4.get_next(ams, op3.get_next(ams, op2.get_next(ams, 0) + this.feedback))
            case 2
                this.feedback = op1.get_next(ams, feedback)
                ret = op4.get_next(ams, op3.get_next(ams, op2.get_next(ams, 0)) + this.feedback)
            case 3
                this.feedback = op1.get_next(ams, feedback)
                ret = op4.get_next(ams, op3.get_next(ams, 0) + op2.get_next(ams, this.feedback))
            case 4
                this.feedback = op1.get_next(ams, feedback)
                ret = op4.get_next(ams, op3.get_next(ams, 0)) + op2.get_next(ams, this.feedback)
            case 5
                feedback = op1.get_next(ams, feedback)
                this.feedback = feedback
                ret = op4.get_next(ams, feedback) + op3.get_next(ams, feedback) + op2.get_next(ams, feedback)
            case 6:
                this.feedback = op1.get_next(ams, feedback)
                ret = op4.get_next(ams, 0) + op3.get_next(ams, 0) + op2.get_next(ams, this.feedback)
            case 7
                this.feedback = op1.get_next(ams, feedback)
                ret = op4.get_next(ams, 0) + op3.get_next(ams, 0) + op2.get_next(ams, 0) + this.feedback
            case else
                return 0
            end select
        else
            select case ALG
            case 0
                this.feedback = op1.get_next(feedback)
                ret = op4.get_next(op3.get_next(op2.get_next(this.feedback)))
            case 1
                this.feedback = op1.get_next(feedback)
                ret = op4.get_next(op3.get_next(op2.get_next() + this.feedback))
            case 2
                this.feedback = op1.get_next(feedback)
                ret = op4.get_next(op3.get_next(op2.get_next()) + this.feedback)
            case 3:
                this.feedback = op1.get_next(feedback)
                ret = op4.get_next(op3.get_next() + op2.get_next(this.feedback))
            case 4
                this.feedback = op1.get_next(feedback)
                ret = op4.get_next(op3.get_next()) + op2.get_next(this.feedback)
            case 5
                feedback = op1.get_next(feedback)
                this.feedback = feedback
                ret = op4.get_next(feedback) + op3.get_next(feedback) + op2.get_next(feedback)
            case 6
                this.feedback = op1.get_next(feedback)
                ret = op4.get_next() + op3.get_next() + op2.get_next(this.feedback)
            case 7
                this.feedback = op1.get_next(feedback)
                ret = op4.get_next() + op3.get_next() + op2.get_next() + this.feedback
            case else
                return 0
            end select
        end if
        if tremolo_depth then
            dim as long x = 4096 - (((cast(long,tremolo_lfo.get_next()) + 32768) * tremolo_depth) shr 11)
            ret = ret * x shr 12
        end if
        return ret
end function

function fm_note.synthesize(buf as long ptr, samples as uinteger, rate as single, _left as long, _right as long) as integer
        _left = (_left * velocity) shr 7
        _right = (_right * velocity) shr 7
        fm.set_rate(rate)
        for i as uinteger = 0 to samples
            dim as long sample = fm.get_next()
            buf[i * 2 + 0] += (sample * _left) shr 14
            buf[i * 2 + 1] += (sample * _right) shr 14
        next
        return not fm.is_finished()
end function

sub fm_note_factory.clear_
        static as FMPARAMETER param = (_
            7, 0, 0,_    ' ALG FB LFO
            _'AR DR SR RR SL  TL KS ML DT AMS
            ( 31, 0, 0,15, 0,  0, 0, 0, 0, 0 ),_
            (  0, 0, 0,15, 0,127, 0, 0, 0, 0 ),_
            (  0, 0, 0,15, 0,127, 0, 0, 0, 0 ),_
            (  0, 0, 0,15, 0,127, 0, 0, 0, 0 ))
        erase drums
        erase programs
        programs(128) = @param
end sub

function fm_note_factory.note_on(program as long, note as integer, velocity as integer, frequency_multiplier as single) as fm_note ptr
        dim as integer drum = (program shr 14) = 120
   dim as fm_note ptr new_note= new fm_note

        dim as integer feedbacks(7) = {31, 6, 5, 4, 3, 2, 1, 0}
        dim as single _ams_table(7) = {3.98, 5.56, 6.02, 6.37, 6.88, 9.63, 48.1, 72.2}

        if drum then 
            dim as DRUMPARAMETER ptr p=drums(note)
            new_note->assign=p->assign
            new_note->panpot=p->panpot
            new_note->velocity=velocity
            new_note->fm.freq_mul=1
            new_note->fm.freq=440 * 2.0^ ((p->key - 69) / 12.0)

            new_note->fm.tremolo_freq=1
            new_note->fm.vibrato_freq=1
            new_note->fm.ALG=p->ALG
            new_note->fm.FB = feedbacks(p->FB)
            new_note->fm.ams_freq = _ams_table(p->LFO)
            new_note->fm.ams_enable = (p->op1.AMS + p->op2.AMS + p->op3.AMS + p->op4.AMS) <> 0

            if p->op1.DT >= 4 then
                new_note->fm.OP1.DT = -detune_table(p->op1.DT - 4,p->key)
            else
                new_note->fm.OP1.DT = detune_table(p->op1.DT,p->key)
            end if
            if p->op1.ML = 0 then
                new_note->fm.OP1.ML = 0.5
            else
                new_note->fm.OP1.ML = p->op1.ML
            end if
            new_note->fm.OP1.ams_factor = ams_table(p->OP1.AMS) / 2
            new_note->fm.OP1.ams_bias = 32768 - new_note->fm.OP1.ams_factor * 256

            new_note->fm.OP1.eg.state=ATTACK
            new_note->fm.OP1.eg.rate=1
            new_note->fm.OP1.eg.AR=p->OP1.AR * 2 + keyscale_table(p->OP1.KS,p->key)
            new_note->fm.OP1.eg.DR=p->OP1.DR * 2 + keyscale_table(p->OP1.KS,p->key)
            new_note->fm.OP1.eg.SR=p->OP1.SR * 2 + keyscale_table(p->OP1.KS,p->key)
            new_note->fm.OP1.eg.RR=p->OP1.RR * 4 + keyscale_table(p->OP1.KS,p->key) + 2
            new_note->fm.OP1.eg.TL=p->OP1.TL
            new_note->fm.OP1.eg.fTL = envelope_table.TL(p->OP1.TL)

            if new_note->fm.OP1.eg.AR > 63 then new_note->fm.OP1.eg.AR = 63
            if new_note->fm.OP1.eg.DR > 63 then new_note->fm.OP1.eg.DR = 63
            if new_note->fm.OP1.eg.SR > 63 then new_note->fm.OP1.eg.SR = 63
            if new_note->fm.OP1.eg.RR > 63 then new_note->fm.OP1.eg.RR = 63

            new_note->fm.OP1.eg.fSL = envelope_table.SL(p->OP1.SL,p->OP1.TL)
            new_note->fm.OP1.eg.fSS = envelope_table.SL(p->OP1.SL,p->OP1.TL)


            if p->op2.DT >= 4 then
                new_note->fm.OP2.DT = -detune_table(p->op2.DT - 4,p->key)
            else
                new_note->fm.OP2.DT = detune_table(p->op2.DT,p->key)
            end if
            if p->op2.ML = 0 then
                new_note->fm.OP2.ML = 0.5
            else
                new_note->fm.OP2.ML = p->op2.ML
            end if
            new_note->fm.OP2.ams_factor = ams_table(p->OP2.AMS) / 2
            new_note->fm.OP2.ams_bias = 32768 - new_note->fm.OP2.ams_factor * 256

            new_note->fm.OP2.eg.state=ATTACK
            new_note->fm.OP2.eg.rate=1
            new_note->fm.OP2.eg.AR=p->OP2.AR * 2 + keyscale_table(p->OP2.KS,p->key)
            new_note->fm.OP2.eg.DR=p->OP2.DR * 2 + keyscale_table(p->OP2.KS,p->key)
            new_note->fm.OP2.eg.SR=p->OP2.SR * 2 + keyscale_table(p->OP2.KS,p->key)
            new_note->fm.OP2.eg.RR=p->OP2.RR * 4 + keyscale_table(p->OP2.KS,p->key) + 2
            new_note->fm.OP2.eg.TL=p->OP2.TL
            new_note->fm.OP2.eg.fTL = envelope_table.TL(p->OP2.TL)

            if new_note->fm.OP2.eg.AR > 63 then new_note->fm.OP2.eg.AR = 63
            if new_note->fm.OP2.eg.DR > 63 then new_note->fm.OP2.eg.DR = 63
            if new_note->fm.OP2.eg.SR > 63 then new_note->fm.OP2.eg.SR = 63
            if new_note->fm.OP2.eg.RR > 63 then new_note->fm.OP2.eg.RR = 63

            new_note->fm.OP2.eg.fSL = envelope_table.SL(p->OP2.SL,p->OP2.TL)
            new_note->fm.OP2.eg.fSS = envelope_table.SL(p->OP2.SL,p->OP2.TL)


            if p->op3.DT >= 4 then
                new_note->fm.OP3.DT = -detune_table(p->op3.DT - 4,p->key)
            else
                new_note->fm.OP3.DT = detune_table(p->op3.DT,p->key)
            end if
            if p->op3.ML = 0 then
                new_note->fm.OP3.ML = 0.5
            else
                new_note->fm.OP3.ML = p->op3.ML
            end if
            new_note->fm.OP3.ams_factor = ams_table(p->OP3.AMS) / 2
            new_note->fm.OP3.ams_bias = 32768 - new_note->fm.OP3.ams_factor * 256

            new_note->fm.OP3.eg.state=ATTACK
            new_note->fm.OP3.eg.rate=1
            new_note->fm.OP3.eg.AR=p->OP3.AR * 2 + keyscale_table(p->OP3.KS,p->key)
            new_note->fm.OP3.eg.DR=p->OP3.DR * 2 + keyscale_table(p->OP3.KS,p->key)
            new_note->fm.OP3.eg.SR=p->OP3.SR * 2 + keyscale_table(p->OP3.KS,p->key)
            new_note->fm.OP3.eg.RR=p->OP3.RR * 4 + keyscale_table(p->OP3.KS,p->key) + 2
            new_note->fm.OP3.eg.TL=p->OP3.TL
            new_note->fm.OP3.eg.fTL = envelope_table.TL(p->OP3.TL)

            if new_note->fm.OP3.eg.AR > 63 then new_note->fm.OP3.eg.AR = 63
            if new_note->fm.OP3.eg.DR > 63 then new_note->fm.OP3.eg.DR = 63
            if new_note->fm.OP3.eg.SR > 63 then new_note->fm.OP3.eg.SR = 63
            if new_note->fm.OP3.eg.RR > 63 then new_note->fm.OP3.eg.RR = 63

            new_note->fm.OP3.eg.fSL = envelope_table.SL(p->OP3.SL,p->OP3.TL)
            new_note->fm.OP3.eg.fSS = envelope_table.SL(p->OP3.SL,p->OP3.TL)


            if p->op4.DT >= 4 then
                new_note->fm.OP4.DT = -detune_table(p->op4.DT - 4,p->key)
            else
                new_note->fm.OP4.DT = detune_table(p->op4.DT,p->key)
            end if
            if p->op4.ML = 0 then
                new_note->fm.OP4.ML = 0.5
            else
                new_note->fm.OP4.ML = p->op4.ML
            end if
            new_note->fm.OP4.ams_factor = ams_table(p->OP4.AMS) / 2
            new_note->fm.OP4.ams_bias = 32768 - new_note->fm.OP4.ams_factor * 256

            new_note->fm.OP4.eg.state=ATTACK
            new_note->fm.OP4.eg.rate=1
            new_note->fm.OP4.eg.AR=p->OP4.AR * 2 + keyscale_table(p->OP4.KS,p->key)
            new_note->fm.OP4.eg.DR=p->OP4.DR * 2 + keyscale_table(p->OP4.KS,p->key)
            new_note->fm.OP4.eg.SR=p->OP4.SR * 2 + keyscale_table(p->OP4.KS,p->key)
            new_note->fm.OP4.eg.RR=p->OP4.RR * 4 + keyscale_table(p->OP4.KS,p->key) + 2
            new_note->fm.OP4.eg.TL=p->OP4.TL
            new_note->fm.OP4.eg.fTL = envelope_table.TL(p->OP4.TL)

            if new_note->fm.OP4.eg.AR > 63 then new_note->fm.OP4.eg.AR = 63
            if new_note->fm.OP4.eg.DR > 63 then new_note->fm.OP4.eg.DR = 63
            if new_note->fm.OP4.eg.SR > 63 then new_note->fm.OP4.eg.SR = 63
            if new_note->fm.OP4.eg.RR > 63 then new_note->fm.OP4.eg.RR = 63

            new_note->fm.OP4.eg.fSL = envelope_table.SL(p->OP4.SL,p->OP4.TL)
            new_note->fm.OP4.eg.fSS = envelope_table.SL(p->OP4.SL,p->OP4.TL)

            return new_note
        else
            dim as FMPARAMETER ptr p=programs(program)
            new_note->assign=0
            new_note->panpot=8192
            new_note->velocity=velocity
            new_note->fm.freq_mul=frequency_multiplier
            new_note->fm.freq=440 * 2.0^ ((note - 69) / 12.0)

            new_note->fm.tremolo_freq=1
            new_note->fm.vibrato_freq=1
            new_note->fm.ALG=p->ALG
            new_note->fm.FB = feedbacks(p->FB)
            new_note->fm.ams_freq = _ams_table(p->LFO)
            new_note->fm.ams_enable = (p->op1.AMS + p->op2.AMS + p->op3.AMS + p->op4.AMS) <> 0

            if p->op1.DT >= 4 then
                new_note->fm.OP1.DT = -detune_table(p->op1.DT - 4,note)
            else
                new_note->fm.OP1.DT = detune_table(p->op1.DT,note)
            end if
            if p->op1.ML = 0 then
                new_note->fm.OP1.ML = 0.5
            else
                new_note->fm.OP1.ML = p->op1.ML
            end if
            new_note->fm.OP1.ams_factor = ams_table(p->OP1.AMS) / 2
            new_note->fm.OP1.ams_bias = 32768 - new_note->fm.OP1.ams_factor * 256

            new_note->fm.OP1.eg.state=ATTACK
            new_note->fm.OP1.eg.rate=1
            new_note->fm.OP1.eg.AR=p->OP1.AR * 2 + keyscale_table(p->OP1.KS,note)
            new_note->fm.OP1.eg.DR=p->OP1.DR * 2 + keyscale_table(p->OP1.KS,note)
            new_note->fm.OP1.eg.SR=p->OP1.SR * 2 + keyscale_table(p->OP1.KS,note)
            new_note->fm.OP1.eg.RR=p->OP1.RR * 4 + keyscale_table(p->OP1.KS,note) + 2
            new_note->fm.OP1.eg.TL=p->OP1.TL
            new_note->fm.OP1.eg.fTL = envelope_table.TL(p->OP1.TL)

            if new_note->fm.OP1.eg.AR > 63 then new_note->fm.OP1.eg.AR = 63
            if new_note->fm.OP1.eg.DR > 63 then new_note->fm.OP1.eg.DR = 63
            if new_note->fm.OP1.eg.SR > 63 then new_note->fm.OP1.eg.SR = 63
            if new_note->fm.OP1.eg.RR > 63 then new_note->fm.OP1.eg.RR = 63

            new_note->fm.OP1.eg.fSL = envelope_table.SL(p->OP1.SL,p->OP1.TL)
            new_note->fm.OP1.eg.fSS = envelope_table.SL(p->OP1.SL,p->OP1.TL)


            if p->op2.DT >= 4 then
                new_note->fm.OP2.DT = -detune_table(p->op2.DT - 4,note)
            else
                new_note->fm.OP2.DT = detune_table(p->op2.DT,note)
            end if
            if p->op2.ML = 0 then
                new_note->fm.OP2.ML = 0.5
            else
                new_note->fm.OP2.ML = p->op2.ML
            end if
            new_note->fm.OP2.ams_factor = ams_table(p->OP2.AMS) / 2
            new_note->fm.OP2.ams_bias = 32768 - new_note->fm.OP2.ams_factor * 256

            new_note->fm.OP2.eg.state=ATTACK
            new_note->fm.OP2.eg.rate=1
            new_note->fm.OP2.eg.AR=p->OP2.AR * 2 + keyscale_table(p->OP2.KS,note)
            new_note->fm.OP2.eg.DR=p->OP2.DR * 2 + keyscale_table(p->OP2.KS,note)
            new_note->fm.OP2.eg.SR=p->OP2.SR * 2 + keyscale_table(p->OP2.KS,note)
            new_note->fm.OP2.eg.RR=p->OP2.RR * 4 + keyscale_table(p->OP2.KS,note) + 2
            new_note->fm.OP2.eg.TL=p->OP2.TL
            new_note->fm.OP2.eg.fTL = envelope_table.TL(p->OP2.TL)

            if new_note->fm.OP2.eg.AR > 63 then new_note->fm.OP2.eg.AR = 63
            if new_note->fm.OP2.eg.DR > 63 then new_note->fm.OP2.eg.DR = 63
            if new_note->fm.OP2.eg.SR > 63 then new_note->fm.OP2.eg.SR = 63
            if new_note->fm.OP2.eg.RR > 63 then new_note->fm.OP2.eg.RR = 63

            new_note->fm.OP2.eg.fSL = envelope_table.SL(p->OP2.SL,p->OP2.TL)
            new_note->fm.OP2.eg.fSS = envelope_table.SL(p->OP2.SL,p->OP2.TL)


            if p->op3.DT >= 4 then
                new_note->fm.OP3.DT = -detune_table(p->op3.DT - 4,note)
            else
                new_note->fm.OP3.DT = detune_table(p->op3.DT,note)
            end if
            if p->op3.ML = 0 then
                new_note->fm.OP3.ML = 0.5
            else
                new_note->fm.OP3.ML = p->op3.ML
            end if
            new_note->fm.OP3.ams_factor = ams_table(p->OP3.AMS) / 2
            new_note->fm.OP3.ams_bias = 32768 - new_note->fm.OP3.ams_factor * 256

            new_note->fm.OP3.eg.state=ATTACK
            new_note->fm.OP3.eg.rate=1
            new_note->fm.OP3.eg.AR=p->OP3.AR * 2 + keyscale_table(p->OP3.KS,note)
            new_note->fm.OP3.eg.DR=p->OP3.DR * 2 + keyscale_table(p->OP3.KS,note)
            new_note->fm.OP3.eg.SR=p->OP3.SR * 2 + keyscale_table(p->OP3.KS,note)
            new_note->fm.OP3.eg.RR=p->OP3.RR * 4 + keyscale_table(p->OP3.KS,note) + 2
            new_note->fm.OP3.eg.TL=p->OP3.TL
            new_note->fm.OP3.eg.fTL = envelope_table.TL(p->OP3.TL)

            if new_note->fm.OP3.eg.AR > 63 then new_note->fm.OP3.eg.AR = 63
            if new_note->fm.OP3.eg.DR > 63 then new_note->fm.OP3.eg.DR = 63
            if new_note->fm.OP3.eg.SR > 63 then new_note->fm.OP3.eg.SR = 63
            if new_note->fm.OP3.eg.RR > 63 then new_note->fm.OP3.eg.RR = 63

            new_note->fm.OP3.eg.fSL = envelope_table.SL(p->OP3.SL,p->OP3.TL)
            new_note->fm.OP3.eg.fSS = envelope_table.SL(p->OP3.SL,p->OP3.TL)


            if p->op4.DT >= 4 then
                new_note->fm.OP4.DT = -detune_table(p->op4.DT - 4,note)
            else
                new_note->fm.OP4.DT = detune_table(p->op4.DT,note)
            end if
            if p->op4.ML = 0 then
                new_note->fm.OP4.ML = 0.5
            else
                new_note->fm.OP4.ML = p->op4.ML
            end if
            new_note->fm.OP4.ams_factor = ams_table(p->OP4.AMS) / 2
            new_note->fm.OP4.ams_bias = 32768 - new_note->fm.OP4.ams_factor * 256

            new_note->fm.OP4.eg.state=ATTACK
            new_note->fm.OP4.eg.rate=1
            new_note->fm.OP4.eg.AR=p->OP4.AR * 2 + keyscale_table(p->OP4.KS,note)
            new_note->fm.OP4.eg.DR=p->OP4.DR * 2 + keyscale_table(p->OP4.KS,note)
            new_note->fm.OP4.eg.SR=p->OP4.SR * 2 + keyscale_table(p->OP4.KS,note)
            new_note->fm.OP4.eg.RR=p->OP4.RR * 4 + keyscale_table(p->OP4.KS,note) + 2
            new_note->fm.OP4.eg.TL=p->OP4.TL
            new_note->fm.OP4.eg.fTL = envelope_table.TL(p->OP4.TL)

            if new_note->fm.OP4.eg.AR > 63 then new_note->fm.OP4.eg.AR = 63
            if new_note->fm.OP4.eg.DR > 63 then new_note->fm.OP4.eg.DR = 63
            if new_note->fm.OP4.eg.SR > 63 then new_note->fm.OP4.eg.SR = 63
            if new_note->fm.OP4.eg.RR > 63 then new_note->fm.OP4.eg.RR = 63

            new_note->fm.OP4.eg.fSL = envelope_table.SL(p->OP4.SL,p->OP4.TL)
            new_note->fm.OP4.eg.fSS = envelope_table.SL(p->OP4.SL,p->OP4.TL)

            return new_note
        end if
end function