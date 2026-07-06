# Yet Another Anime Game Launcher iOS

This is an iOS SwiftUI recreation of the desktop YAAGL launcher flow.

The first implementation intentionally runs in simulation mode:

- no game resource downloads
- no Wine, aria2, Sophon, patching, hosts edits, or process launch
- install, update, launch, pre-download, and integrity checks emit local progress events only

The goal is to preserve the launcher state machine, configuration surface, task progress model, and user-facing launcher experience before any platform-specific capability is considered.

