#!/usr/bin/env python3
"""Extract the final visible frame used by fast Quickshell overlays."""

import subprocess
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: ext_last_fr.py <wave_reveal.mp4>", file=sys.stderr)
        return 1

    video = Path(sys.argv[1]).expanduser().resolve()
    if not video.is_file():
        print(f"Video not found: {video}", file=sys.stderr)
        return 1

    output = video.with_name("wave_last_frame.png")
    subprocess.run(
        [
            "ffmpeg",
            "-loglevel",
            "error",
            "-y",
            "-sseof",
            "-0.1",
            "-i",
            str(video),
            "-frames:v",
            "1",
            str(output),
        ],
        check=True,
    )
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
