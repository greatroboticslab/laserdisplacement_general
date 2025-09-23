from moku.instruments import WaveformGenerator

class Ctrl_Moku():
    """
    This class will call Moku API to change the voltage of the piezo.
    Automatically detects connection type:
    - Tries USB first
    - Falls back to Wi-Fi if no USB device is found
    """

    def __init__(self, ip="192.168.73.1"):
        self.ip = ip

        # Desired waveform defaults (you can override from main)
        self.CHANNEL = 1
        self.WAVE    = "Sine"     # allowed: Off, Sine, Square, Ramp, Pulse, DC, Noise
        self.AMP_VPP = 5.0        # Vpp (0.004 .. 10 for Moku:Go)
        self.FREQ_HZ = 1.0        # Hz  (1e-3 .. 20e6 for Moku:Go)
        self.OFFSET  = 0.0        # V   (-5 .. +5)

        # Hard safety clamps from API limits (Moku:Go)
        self.AMP_MIN, self.AMP_MAX       = 0.004, 10.0
        self.FREQ_MIN, self.FREQ_MAX     = 1e-3, 20e6
        self.OFFSET_MIN, self.OFFSET_MAX = -5.0, 5.0

        self.try_connect = self.connect()

    def connect(self):
        """Try USB first, fall back to Wi-Fi."""
        try:
            print("Trying USB connection to Moku...")
            self.inst = WaveformGenerator()  # auto-detect USB
            print("Connected to Moku via USB")
        except Exception as usb_err:
            print(f"USB connection failed: {usb_err}")
            try:
                print(f"Trying Wi-Fi connection at {self.ip}...")
                self.inst = WaveformGenerator(self.ip, force_connect=True)
                print("Connected to Moku via Wi-Fi")
            except Exception as wifi_err:
                print(f"Wi-Fi connection failed: {wifi_err}")
                self.inst = None
                return

        # Initialize instrument if connection worked
        if self.inst:
            try:
                self.inst.set_defaults()
                self.inst.set_output_termination(channel=self.CHANNEL, termination="HiZ")
            except Exception as e:
                print(f"Warning: post-connect setup not applied: {e}")

    def _clamp(self, v, vmin, vmax):
        return max(vmin, min(vmax, float(v)))

    def set_waveform(self, channel=None, type_=None, amplitude=None, frequency=None, offset=None, phase=None):
        if self.inst is None:
            print("Moku not connected; skipping set_waveform.")
            return

        ch   = channel   if channel   is not None else self.CHANNEL
        typ  = type_     if type_     is not None else self.WAVE
        amp  = amplitude if amplitude is not None else self.AMP_VPP
        freq = frequency if frequency is not None else self.FREQ_HZ
        ofs  = offset    if offset    is not None else self.OFFSET

        amp  = self._clamp(amp,  self.AMP_MIN,  self.AMP_MAX)
        freq = self._clamp(freq, self.FREQ_MIN, self.FREQ_MAX)
        ofs  = self._clamp(ofs,  self.OFFSET_MIN, self.OFFSET_MAX)

        kwargs = dict(channel=ch, type=typ, amplitude=amp, frequency=freq, offset=ofs)
        if phase is not None:
            kwargs["phase"] = float(phase)

        try:
            self.inst.generate_waveform(**kwargs)
            print(f"Waveform set: ch={ch}, type={typ}, amp(Vpp)={amp}, freq(Hz)={freq}, offset(V)={ofs}" +
                  (f", phase={kwargs.get('phase')}" if "phase" in kwargs else ""))
        except Exception as e:
            print(f"Error in generate_waveform: {e}")

    def set_voltage(self, dc_level):
        """PID loop drives offset; only update offset within [-5, +5] V"""
        self.set_waveform(offset=dc_level)

    def disconnect(self):
        if self.inst:
            try:
                self.inst.close()
                print("Disconnected from Moku:Go")
            except Exception as e:
                print(f"Error during Moku disconnect: {e}")
            finally:
                self.inst = None


    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.disconnect()
