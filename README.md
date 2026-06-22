# ClipLedger

ClipLedger is a lightweight clipboard history manager for macOS. It runs from the menu bar, records copied plain text locally, and lets you quickly search, pin, tag, and restore previous clipboard entries.

ClipLedger is built for privacy: no accounts, no cloud sync, no analytics, and no external servers.

## Features

- Menu bar clipboard history for plain text
- Restore any saved item back to the system clipboard
- Search across clipboard history and pinned clips
- Pin important snippets above regular history
- Organize pinned snippets with tags
- Auto-pin frequently restored items
- Delete individual entries or clear non-pinned history
- Configurable history limit: 50, 100, or 200 records
- Launch at login setting
- Global shortcut: Control + Shift + V
- Local persistence with SwiftData

## Screenshots

App Store screenshots are available in [docs/app-store-screenshots](docs/app-store-screenshots).

## Privacy

ClipLedger stores clipboard history locally on your Mac and never transmits clipboard data externally.

See [Privacy Policy](docs/PRIVACY.md) for details.

## Requirements

- macOS 14.0 or later
- Xcode 15 or later
- SwiftUI
- SwiftData

## Development

Open the project in Xcode:

```sh
open ClipLedger.xcodeproj
```

Build from the command line:

```sh
xcodebuild -project ClipLedger.xcodeproj -scheme ClipLedger -configuration Debug build
```

Run tests:

```sh
xcodebuild -project ClipLedger.xcodeproj -scheme ClipLedger -destination 'platform=macOS' test
```

## Support

For support, bug reports, or feedback, open an issue in this repository or use the information in [Support](docs/SUPPORT.md).

## License

Copyright (c) 2026 CodeFern. All rights reserved.

This repository is public for product transparency and support. No license is granted to copy, modify, distribute, sublicense, or use this software for any purpose without explicit written permission from CodeFern.
