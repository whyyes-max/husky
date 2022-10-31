#!/usr/bin/env python3
# This program runs FFPlay to generate beeps.

from argparse import ArgumentParser, ArgumentError, Action
import re
import subprocess

# Custom action for note
class NoteToFrequencyAction(Action):
    _note = re.compile(r"([A-G])(bb|[bx#])?(\d+)")
    _note_factors = {
        "C": lambda x: x / (2 ** (9/12)),
        "D": lambda x: x / (2 ** (7/12)),
        "E": lambda x: x / (2 ** (5/12)),
        "F": lambda x: x / (2 ** (4/12)),
        "G": lambda x: x / (2 ** (2/12)),
        "A": lambda x: x,
        "B": lambda x: x * (2 ** (2/12)),
    }
    _accidental_factors = {
        "x" : lambda x: x * (2 ** (2/12)),
        "#" : lambda x: x * (2 ** (1/12)),
        None: lambda x: x,
        "b" : lambda x: x / (2 ** (1/12)),
        "bb": lambda x: x / (2 ** (2/12))
    }
    def __call__(self, parser, namespace, values, option_string) -> None:
        if not (isinstance(values, str)):
            raise ArgumentError("Should not have multiple values")
        
        parse = self._note.fullmatch(values);
        parts = parse.groups()

        freq = 440.0
        freq *= 2 ** (int(parts[2]) - 4)
        freq = self._note_factors[parts[0]](freq)
        freq = self._accidental_factors[parts[1]](freq)
        
        if not type(namespace.__dict__[self.dest]) == list:
            namespace.__dict__[self.dest] = []
        namespace.__dict__[self.dest].append(freq)


        

parser = ArgumentParser()

freq_group = parser.add_mutually_exclusive_group(required=True)
freq_group.add_argument("-f", "--frequency", type=float, action="append", dest="freqs",
    help="Can be specified more than once, specifies frequencies in Hz of the barked notes"
)
freq_group.add_argument("-n", "--note", action=NoteToFrequencyAction, dest="freqs",
    help="Can be specified more than once, specifies notes (e.g. A4). You can use b, #, x, bb for accidentals."
)

parser.add_argument("-d", "--duration", type=float, default=1, dest="time",
    help="The duration of the bark in seconds."
)
parser.add_argument("-v", "--volume", type=float, default=0.5,
    help="The volume of the bark, defaults to 0.5"
)

args = parser.parse_args()
del parser, freq_group

aevalsrc_waves = [f"sgn(sin({repr(f)}*2*PI*t))" for f in args.freqs]
aevalsrc_expr = "+".join(aevalsrc_waves)
ffplay_filter = f"aevalsrc=({aevalsrc_expr})/{len(args.freqs)}*{args.volume}:d={args.time}"
print("aevalsrc filter:")
print(ffplay_filter)

subprocess.run([
    "ffplay", "-f", "lavfi", "-i", ffplay_filter, "-autoexit", "-nodisp"
], stderr=subprocess.DEVNULL)
