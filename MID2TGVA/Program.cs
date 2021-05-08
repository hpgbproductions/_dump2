using System;
using System.IO;
using System.Text;

namespace MID2TGVA
{
    class Program
    {
        static void Main(string[] args)
        {
            // BEGIN user settings

            const int MaxTempoEvents = 100;
            const int MaxEventsPerNote = 10000;

            const double NoteOnDelay = 0;
            const double NoteOffDelay = 0;
            const double FrequencyMultiplier = 0;
            const double AmplitudeMultiplier = 1;
            const double SpeedMultiplier = 1;

            // END user settings

            // ----------------------------------------------------------------

            string fp;
            BinaryReader reader;
            Stream fs;

            uint format = 0;
            uint ntracks = 0;    // Number of MTrk chunks
            uint tickdiv;        // The source two-byte value that provides timing resolution information

            TimingModes TimingMode;
            uint ppqn;
            uint fps;
            uint subfps;

            byte PreviousAction = 0xFF;    // For Running Status use
            bool MultiPacketMsg = false;

            uint CurrentTick = 0;
            uint CurrentTrack = 0;

            double TickTime = 1;    // Duration of a tick in seconds

            // ! --- Tempo calculation is only used for metrical timing
            int TempoEvents = 0;

            // ----------------------------------------------------------------
            // BEGIN Runtime Area

            Console.WriteLine("MIDI to Tone Generator Converter");
            Console.WriteLine("nataniasoft (hpgbproductions)");
            Console.WriteLine();
            Console.WriteLine("Enter MIDI file path>");
            fp = Console.ReadLine();
            Console.WriteLine();
            fs = File.OpenRead(fp);
            reader = new BinaryReader(fs);

            // Read the header chunk
            ReadChunk();

            // Read the track chunk(s)
            switch (format)
            {
                case 0:
                    ReadChunk();
                    break;

                case 1:
                    bool more = true;
                    while (more)
                    {
                        more = ReadChunk();
                    }
                    break;

                case 2:
                    long pos_store = fs.Position;
                    bool more2 = true;
                    while (more2)
                    {
                        more2 = ReadChunk(true);
                    }

                    Console.WriteLine(string.Format("{0} track chunks detected. Enter a number from 0 to {1}, inclusive>", ntracks, ntracks - 1));
                    int TargetTrack = int.Parse(Console.ReadLine());
                    if (TargetTrack >= CurrentTrack)
                    {
                        Console.WriteLine("A track of index " + TargetTrack + " does not exist.");
                        break;
                    }

                    CurrentTrack = 0;
                    fs.Position = pos_store;

                    while (CurrentTrack < TargetTrack)
                    {
                        ReadChunk(true);
                    }
                    ReadChunk();
                    break;

                default:
                    Console.WriteLine("This MIDI file format is not supported");
                    break;
            }

            return;

            // END Runtime Area
            // ----------------------------------------------------------------

            bool ByteArraysEqual(byte[] a, byte[] b)
            {
                if (a.Length != b.Length)
                {
                    return false;
                }

                for (int i = 0; i < a.Length; i++)
                {
                    if (a[i] != b[i])
                    {
                        return false;
                    }
                }

                return true;
            }

            uint ReadBigEndianUInt32()
            {
                byte[] data = reader.ReadBytes(4);
                Array.Reverse(data);
                return BitConverter.ToUInt32(data);
            }

            uint ReadBigEndianUInt24()
            {
                byte[] dnum = reader.ReadBytes(3);
                byte[] data = new byte[4] { dnum[2], dnum[1], dnum[0], (byte)0x00u };
                return BitConverter.ToUInt32(data);
            }

            ushort ReadBigEndianUInt16()
            {
                var data = reader.ReadBytes(2);
                Array.Reverse(data);
                return BitConverter.ToUInt16(data);
            }

            // Read variable length values used for delta times and event length
            uint ReadVariableLengthUInt()
            {
                uint number = 0;

                int bytecount = 0;
                bool readnext = true;

                while (readnext && bytecount < 4)
                {
                    byte b = reader.ReadByte();
                    bytecount++;
                    number = (number << 7) + (b & 0x7fu);
                    if (b >> 7 == 0)
                    {
                        readnext = false;
                    }
                }
                
                return number;
            }

            uint TestVariableLengthUInt(byte w, byte x, byte y, byte z)
            {
                uint number = 0;

                int bytecount = 0;
                bool readnext = true;

                byte[] bytes = new byte[4] { w, x, y, z };

                while (readnext && bytecount < 4)
                {
                    byte b = bytes[bytecount];
                    bytecount++;
                    number = (number << 7) + (b & 0x7fu);
                    if (b >> 7 == 0)
                    {
                        readnext = false;
                    }
                }

                return number;
            }

            // Returns the frequency associated with a given MIDI note number
            double NoteFrequency(uint note)
            {
                if (note > 127)
                {
                    return 0f;
                }

                double[] MiddleNotes = new double[] {
                261.625580, 277.182617, 293.664764, 311.126984,
                329.627583, 349.228241, 369.994415, 391.995422,
                415.304688, 440.000000, 466.163757, 493.883301 };

                int RelativeOctave = Convert.ToInt32(note) / 12 - 5;
                int NoteIndex = Convert.ToInt32(note) % 12;

                return MiddleNotes[NoteIndex] * MathF.Pow(2, RelativeOctave);
            }

            // Reads events and identifies them
            // Returns false if it hits End of Track, otherwise returns true
            bool ReadEvent()
            {
                byte bmain = reader.ReadByte();

                if (bmain >= 0x80u)
                {
                    PreviousAction = bmain;
                }
                else    // Running Status
                {
                    bmain = PreviousAction;
                    fs.Position--;
                }

                if (bmain >= 0x80u && bmain <= 0xEFu)    // MIDI Event
                {
                    byte bmainact = (byte)(bmain >> 4);
                    byte bmainch = (byte)(bmain & 0x0Fu);

                    if (bmainact == 0x8u || bmainact == 0x9u || bmainact == 0xAu)    // Key Actions
                    {
                        byte bkey = reader.ReadByte();
                        byte bprs = reader.ReadByte();

                        if (bmainact == 0x8u)
                        {
                            Console.WriteLine(string.Format("    {0}> Channel {1:X}: Turned OFF note 0x{2:X2} with pressure 0x{3:X2}", CurrentTick, bmainch, bkey, bprs));
                        }
                        else if (bmainact == 0x9u)
                        {
                            Console.WriteLine(string.Format("    {0}> Channel {1:X}: Turned {4} note 0x{2:X2} with pressure 0x{3:X2}", CurrentTick, bmainch, bkey, bprs, bprs == 0 ? "OFF" : "ON"));
                        }
                        else if (bmainact == 0xAu)
                        {
                            Console.WriteLine(string.Format("    {0}> Channel {1:X}: Applied aftertouch on note 0x{2:X2} with pressure 0x{3:X2}", CurrentTick, bmainch, bkey, bprs));
                        }
                    }
                    else if (bmainact == 0xBu)
                    {
                        byte bcon = reader.ReadByte();
                        byte bval = reader.ReadByte();
                        Console.WriteLine(string.Format("    {0}> Channel {1:X}: Set controller 0x{2:X2} to value 0x{3:X2}", CurrentTick, bmainch, bcon, bval));
                    }
                    else if (bmainact == 0xCu)
                    {
                        byte bprg = reader.ReadByte();
                        Console.WriteLine(string.Format("    {0}> Channel {1:X}: Changed to program {2:X2}", CurrentTick, bmainch, bprg));
                    }
                    else if (bmainact == 0xDu)
                    {
                        byte bprs = reader.ReadByte();
                        Console.WriteLine(string.Format("    {0}> Channel {1:X}: Applied aftertouch pressure {2:X2}", CurrentTick, bmainch, bprs));
                    }
                    else if (bmainact == 0xEu)
                    {
                        byte bmsb = reader.ReadByte();
                        byte blsb = reader.ReadByte();
                        Console.WriteLine(string.Format("    {0}> Channel {1:X}: Applied pitch bend {2:X2} {3:X2}", CurrentTick, bmainch, bmsb, blsb));
                    }

                    return true;
                }
                else if (bmain == 0xFFu)    // Meta Event
                {
                    byte bsec = reader.ReadByte();
                    uint blen = ReadVariableLengthUInt();

                    if (bsec == 0x00u)    // Sequence Number
                    {
                        ushort bsqn = ReadBigEndianUInt16();
                        Console.WriteLine(string.Format("    {0}> Sequence Number {1}", CurrentTick, bsqn));
                    }
                    else if (bsec <= 0x09u)    // Text Events
                    {
                        byte texttype = bsec;
                        
                        string text = Encoding.UTF8.GetString(reader.ReadBytes((int)blen));

                        string[] TextTypes = new string[] { "Sequence Name", "Text", "Copyright", "Track Name", "Instrument Name", "Lyric", "Marker", "Cue Point", "Program Name", "Device Name" };

                        if (texttype == 0x03u)    // Sequence | Track Name
                        {
                            if (CurrentTrack == 1 && format <= 1)    // Sequence Name
                            {
                                Console.WriteLine("    {0}> {1}: {2}", CurrentTick, TextTypes[0], text);
                            }
                            else    // Track Name
                            {
                                Console.WriteLine("    {0}> {1}: {2}", CurrentTick, TextTypes[3], text);
                            }
                        }
                        else
                        {
                            Console.WriteLine("    {0}> {1}: {2}", CurrentTick, TextTypes[texttype], text);
                        }
                    }
                    else if (bsec == 0x20u)
                    {
                        byte c = reader.ReadByte();
                        Console.WriteLine("    {0}> Selected Channel: {1:X}", CurrentTick, c);
                    }
                    else if (bsec == 0x21u)
                    {
                        byte p = reader.ReadByte();
                        Console.WriteLine("    {0}> Selected Port: {1:X}", CurrentTick, p);
                    }
                    else if (bsec == 0x2Fu)    // End of Track
                    {
                        Console.WriteLine("    {0}> End of Track", CurrentTick);
                        return false;
                    }
                    else if (bsec == 0x51u)    // Tempo
                    {
                        uint mpqn = ReadBigEndianUInt24();
                        uint bpm = 60000000u / mpqn;
                        Console.WriteLine(string.Format("    {0}> Tempo: {1} BPM ({2} us/beat)", CurrentTick, bpm, mpqn));
                    }
                    else if (bsec == 0x54u)    // SMPTE Offset Time
                    {
                        byte hr = reader.ReadByte();
                        byte r = (byte)(hr >> 5);
                        byte h = (byte)(hr & 0x1Fu);

                        byte m = reader.ReadByte();
                        byte s = reader.ReadByte();
                        byte fr = reader.ReadByte();
                        byte ff = reader.ReadByte();

                        char sep = ':';

                        double fps = 0;
                        switch (r)
                        {
                            case 0b00:
                                fps = 24;
                                break;
                            case 0b01:
                                fps = 25;
                                break;
                            case 0b10:
                                fps = 29.97;
                                sep = ';';
                                break;
                            case 0b11:
                                fps = 30;
                                break;
                            default:
                                fps = 0;
                                break;
                        }

                        double sec = h * 3600 + m * 60 + s + (fr + 0.01 * ff) / fps;
                        Console.WriteLine(string.Format("    {0}> SMPTE Offset: {1:D2}{6}{2:D2}{6}{3:D2}{6}{4:D2}.{5:D2} ({7} seconds)", CurrentTick, h, m, s, fr, ff, sep, sec));
                    }
                    else if (bsec == 0x58u)    // Time Signature
                    {
                        byte n = reader.ReadByte();
                        byte dd = reader.ReadByte();
                        byte d = 0x02;
                        byte c = reader.ReadByte();
                        byte b = reader.ReadByte();

                        for (int i = 1; i < dd; i++)
                        {
                            d *= d;
                        }

                        Console.WriteLine(string.Format("    {0}> Time Signature: {1}/{2}; metronome interval {3}; {4}x 32nd notes per quarter note", CurrentTick, n, d, c, b));
                    }
                    else if (bsec == 0x59u)
                    {
                        byte sf = reader.ReadByte();
                        byte s = (byte)(sf >> 4);
                        byte f = (byte)(sf & 0x0Fu);

                        byte mi = reader.ReadByte();

                        string[,] key = new string[,] { { "C", "G", "D", "A", "E", "B", "F-sharp", "C-sharp", "C-flat", "G-flat", "D-flat", "A-flat", "E-flat", "B-flat", "F" }, { "A", "E", "B", "F-sharp", "C-sharp", "G-sharp", "D-sharp", "A-sharp", "A-flat", "E-flat", "B-flat", "F", "C", "G", "D" } };
                        string[] mst = new string[] { "major", "minor" };

                        Console.WriteLine(string.Format("    {0}> Key Signature: {1} {2}", CurrentTick, key[s == 0 ? f : 15 + f, sf], mst[mi]));
                    }
                    else if (bsec == 0x7Fu)
                    {
                        byte[] bmsg = reader.ReadBytes((int)blen);
                        string bmss = BitConverter.ToString(bmsg);
                        Console.WriteLine("    {0}> Sequencer Specific Event: {1}", CurrentTick, bmss);
                    }

                    return true;
                }
                else if (bmain == 0xF0u || bmain == 0xF7u)    // SysEx Event | Escape Sequence
                {
                    byte blen = reader.ReadByte();
                    byte[] bmsg = reader.ReadBytes(blen);
                    string bmss = BitConverter.ToString(bmsg);

                    if (bmain == 0xF0u)    // SysEx Event
                    {
                        if (bmsg[bmsg.Length - 1] == 0xF7u)    // SysEx Termination Byte
                        {
                            MultiPacketMsg = false;
                        }
                        else
                        {
                            MultiPacketMsg = true;
                        }

                        Console.WriteLine("    {0}> System Exclusive Event: {1}", CurrentTick, bmss);
                    }
                    else    // Escape Sequence
                    {
                        if (MultiPacketMsg)
                        {
                            if (bmsg[bmsg.Length - 1] == 0xF7u)    // SysEx Termination Byte
                            {
                                MultiPacketMsg = false;
                            }

                            Console.WriteLine("    {0}> System Exclusive Event: {1}", CurrentTick, bmss);
                        }
                        else
                        {
                            Console.WriteLine("    {0}> Escape Sequence: {1}", CurrentTick, bmss);
                        }
                    }

                    return true;
                }

                // This should not occur
                Console.WriteLine(string.Format("Error: Unexpected first byte 0x{0:X2}", bmain));
                return false;
            }

            // Reads the next chunk
            // Returns true on a successful read, otherwise returns false
            bool ReadChunk(bool tryskip = false)
            {
                // Check if EOF
                if (reader.PeekChar() == -1)
                {
                    Console.WriteLine("No more chunks are available.");
                    return false;
                }

                byte[] ChunkId = new byte[4];    // Type of chunk
                uint ChunkLen = 0;               // Length of chunk
                uint Remaining = 0;              // Bytes remaining in the chunk (only used for header)

                ChunkId = reader.ReadBytes(4);
                ChunkLen = ReadBigEndianUInt32();
                Remaining = ChunkLen;

                if (ByteArraysEqual(ChunkId, new byte[] { 0x4D, 0x54, 0x68, 0x64 }))    // MThd
                {
                    Console.WriteLine(string.Format("Detected header chunk with length 0x{0:X8} ({1} bytes)", ChunkLen, ChunkLen));

                    format = ReadBigEndianUInt16();
                    Console.WriteLine("    Format: " + format);

                    ntracks = ReadBigEndianUInt16();
                    Console.WriteLine("    Tracks: " + ntracks);

                    tickdiv = ReadBigEndianUInt16();
                    if (tickdiv < 0x8000)    // Metrical
                    {
                        TimingMode = TimingModes.Metrical;
                        ppqn = tickdiv;
                        Console.WriteLine(string.Format("    Timing Mode: Metrical ({0} PPQN)", ppqn));
                    }
                    else    // Timecode
                    {
                        TimingMode = TimingModes.Timecode;
                        fps = (~(tickdiv >> 8) + 1) & 0x7f;
                        subfps = tickdiv & 0x7f;
                        Console.WriteLine(string.Format("    Timing Mode: Timecode ({0} FPS, {1} sub-frames)", fps, subfps));
                    }

                    Remaining -= 6;

                    // Advance to the end of the chunk, if not already there
                    if (Remaining > 0)
                    {
                        fs.Position += Remaining;
                    }

                    return true;
                }
                else if (ByteArraysEqual(ChunkId, new byte[] { 0x4D, 0x54, 0x72, 0x6B }))    // MTrk
                {
                    CurrentTick = 0;
                    MultiPacketMsg = false;

                    if (tryskip)
                    {
                        fs.Position += ChunkLen;
                        Console.WriteLine(string.Format("Detected track chunk {0} with length 0x{1:X8} ({1} bytes)", CurrentTrack, ChunkLen));
                        CurrentTrack++;
                        return true;
                    }

                    Console.WriteLine(string.Format("Detected track chunk {0} with length 0x{1:X8} ({1} bytes)", CurrentTrack, ChunkLen));

                    bool cont = true;
                    while (cont)
                    {
                        CurrentTick += ReadVariableLengthUInt();
                        cont = ReadEvent();
                    }

                    CurrentTrack++;
                    return true;
                }
                else
                {
                    Console.WriteLine("Error: This chunk type is not supported!");
                    return false;
                }
            }
        }

        enum TimingModes { Metrical, Timecode }
    }
}
