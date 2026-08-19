"""Make sure Cemu's settings.xml lists a game path, touching nothing else.

Every other emulator in emulation.nix pins its settings through a config layer
the program reads but never writes back to -- RetroArch's --appendconfig,
Dolphin's --config. Cemu has no equivalent: `Cemu --help` exposes nothing for
the game list (only -g/--game, which launches one title and exits), and
CemuConfig::Save rewrites settings.xml wholesale when the program closes, so a
settings.xml symlinked out of the store would make every setting the GUI can
change unsaveable.

Writing the one element at activation time and handing the file straight back
to Cemu is the closest thing that does not fight it. The entry is re-added if
it ever goes missing, everything else in the file stays Cemu's to own, and the
file Cemu writes on exit keeps the entry because it round-trips its own config.

Usage: cemu-game-path.py <path to settings.xml> <game path>
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

settings = Path(sys.argv[1])
game_path = sys.argv[2]

if settings.exists():
    try:
        tree = ET.parse(settings)
    except ET.ParseError as err:
        # Cemu killed mid-write leaves a truncated file. Rebuilding it here
        # would throw away real settings, so say so and leave it alone --
        # Cemu rewrites it from defaults on the next clean exit anyway.
        print(f"cemu: {settings} is not valid XML ({err}), leaving it alone")
        sys.exit(0)
    root = tree.getroot()
else:
    # Cemu fills in every other default on first run, so <content> holding
    # just the game path is a complete config as far as its parser cares.
    root = ET.Element("content")
    tree = ET.ElementTree(root)

paths = root.find("GamePaths")
if paths is None:
    paths = ET.SubElement(root, "GamePaths")

if any((entry.text or "") == game_path for entry in paths.findall("Entry")):
    sys.exit(0)

ET.SubElement(paths, "Entry").text = game_path
ET.indent(tree, space="\t")

settings.parent.mkdir(parents=True, exist_ok=True)
tree.write(settings, encoding="UTF-8", xml_declaration=True)
print(f"cemu: added game path {game_path} to {settings}")
