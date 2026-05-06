#!/usr/bin/env python3
"""Extract TerritoryAttachment options from the WW2v5 1942 2nd Edition XML
into a JSON sidecar consumed by the snapshot harness's json_loader.odin.

The snapshot before/after.json files only carry dynamic per-step state;
static map metadata (production values, capital flags, isImpassable, etc.)
lives in the game XML and is loaded by Java's GameParser at startup. The
Odin snapshot harness has no XML parser, so this script bakes the relevant
attachment fields into a JSON file the harness loads alongside each snap.
"""
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

XML_PATH = Path(
    "triplea/game-app/smoke-testing/src/test/resources/map-xmls/WW2v5_1942_2nd.xml"
)
OUT_PATH = Path(
    "triplea/conversion/odin_tests/test_common/ww2v5_territory_attachments.json"
)


def main() -> int:
    root = ET.parse(XML_PATH).getroot()
    out = {}
    for att in root.iter("attachment"):
        if att.get("name") != "territoryAttachment":
            continue
        if att.get("javaClass") != "games.strategy.triplea.attachments.TerritoryAttachment":
            continue
        target = att.get("attachTo")
        if not target:
            continue
        opts = {}
        for opt in att.findall("option"):
            opts[opt.get("name")] = opt.get("value")
        out[target] = opts
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(out, indent=2, sort_keys=True))
    print(f"wrote {len(out)} territoryAttachment entries to {OUT_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
