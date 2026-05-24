#!/usr/bin/env python3
"""Extract CanalAttachment options from the WW2v5 1942 2nd Edition XML
into a JSON sidecar consumed by the snapshot harness's json_loader.odin.

Canal attachments are static map metadata (canalName, landTerritories)
that lives in the game XML and is loaded by Java's GameParser at
startup. The Odin snapshot harness has no XML parser, so this script
bakes the relevant attachment fields into a JSON file the harness loads
alongside each snap. Without these, MoveValidator.canAnyUnitsPassCanal
sees zero canal attachments on canal-bordering sea zones (17 SZ, 34 SZ,
18 SZ, 19 SZ) and incorrectly allows naval units to pass through
unowned canals.

Output shape:
  {
    "17 Sea Zone": [
      {"name": "canalAttachmentSuez_Canal",
       "canalName": "Suez Canal",
       "landTerritories": "Egypt:Trans-Jordan"},
      ...
    ],
    ...
  }
"""
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

XML_PATH = Path(
    "triplea/game-app/smoke-testing/src/test/resources/map-xmls/WW2v5_1942_2nd.xml"
)
OUT_PATH = Path(
    "triplea/conversion/odin_tests/test_common/ww2v5_canal_attachments.json"
)


def main() -> int:
    root = ET.parse(XML_PATH).getroot()
    out: dict[str, list[dict[str, str]]] = {}
    for att in root.iter("attachment"):
        name = att.get("name", "")
        if not name.startswith("canalAttachment"):
            continue
        if att.get("javaClass") != "games.strategy.triplea.attachments.CanalAttachment":
            continue
        target = att.get("attachTo")
        if not target:
            continue
        entry: dict[str, str] = {"name": name}
        for opt in att.findall("option"):
            entry[opt.get("name", "")] = opt.get("value", "")
        out.setdefault(target, []).append(entry)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(out, indent=2, sort_keys=True))
    total = sum(len(v) for v in out.values())
    print(f"wrote {total} canalAttachment entries across {len(out)} territories to {OUT_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
