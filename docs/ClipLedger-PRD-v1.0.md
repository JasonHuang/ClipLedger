# ClipLedger PRD v1.0

Developer: CodeFern

Platform: macOS

Language: Swift

UI Framework: SwiftUI

Architecture: MVVM

Minimum macOS Version: 14.0

Storage: SwiftData

Distribution: Mac App Store

---

# Product Overview

ClipLedger is a lightweight macOS clipboard history manager.

The application automatically records copied text, allows users to browse clipboard history, restore previous clipboard entries, manage frequently used snippets, and keep everything stored locally.

The first version focuses on speed, simplicity, privacy, and reliability.

No AI features.

No cloud sync.

No account system.

No external servers.

---

# Product Goals

Users frequently lose copied content.

ClipLedger solves this by automatically recording clipboard history and making it instantly accessible from the menu bar.

Primary goals:

* Never lose copied text
* Quickly restore previous clipboard entries
* Automatically preserve frequently used content
* Keep all data local

---

# Core Features

## 1. Clipboard Monitoring

Monitor macOS clipboard continuously.

When clipboard content changes:

* Read plain text content
* Create history record
* Save locally
* Update UI immediately

Supported:

* Plain Text

Not Supported:

* Images
* Files
* Rich Text
* HTML

---

## 2. Clipboard History

Display clipboard history in reverse chronological order.

Newest items appear first.

Each history item contains:

* ID
* Content
* Created Time
* Character Count
* Usage Count
* Pin Status

---

## 3. Restore Clipboard Entry

When user clicks a history item:

* Copy selected content back to system clipboard

Workflow:

Copy Content

↓

ClipLedger Saves History

↓

User Selects History Item

↓

Content Restored To Clipboard

↓

User Presses Cmd + V

Automatic paste is NOT included in Version 1.

---

## 4. Delete History Entry

User can delete any history item.

Actions:

* Delete Single Item
* Clear Entire History

Clear History must show confirmation dialog.

---

## 5. Auto Pin

Frequently used clipboard entries should automatically become pinned.

Rule:

When a history item is restored 3 times or more:

* Mark as pinned
* Move into Pinned section

Pinned items remain available permanently until manually removed.

---

## 6. Manual Pin Management

User can:

* Pin Item
* Unpin Item

Pinned items appear above history items.

Pinned items are not affected by history limits.

---

# Data Rules

## Maximum History Count

Default:

100 records

Available Options:

* 50
* 100
* 200

When limit is exceeded:

Delete oldest non-pinned items first.

Pinned items must never be removed automatically.

---

## Duplicate Handling

If newly copied content is identical to the latest history record:

Do not create a new record.

Example:

Copy "Hello"

Copy "Hello"

Result:

Only one history record exists.

---

## Empty Content Handling

Ignore:

* Empty string
* Whitespace only

---

## Maximum Content Length

Maximum:

10000 characters

Content exceeding limit:

Ignore

---

# User Interface

## Application Type

Menu Bar Application

Requirements:

* Display icon in macOS menu bar
* No Dock icon
* Launch directly into menu bar

---

## Main Window Layout

Header

Pinned Section

History Section

Footer

---

## Header

Display:

* App Name
* Settings Button

Future Search Button placeholder may be added but disabled.

---

## Pinned Section

Title:

Pinned

Display:

* Content Preview
* Usage Count

Actions:

* Restore
* Unpin
* Delete

Pinned items always appear before history items.

---

## History Section

Title:

History

Display:

* Content Preview
* Relative Time
* Character Count

Actions:

* Restore
* Pin
* Delete

---

## Footer

Buttons:

* Clear History
* Settings

---

# Keyboard Shortcuts

Global Shortcut:

Control + Shift + V

Behavior:

Open ClipLedger window.

Navigation:

Up Arrow

Down Arrow

Enter

Workflow:

Open Window

↓

Select Item

↓

Press Enter

↓

Restore Clipboard

↓

Cmd + V

---

# Settings

## General

Launch At Login

Default:

Enabled

---

## History

Maximum Record Count

Options:

50

100

200

---

## Behavior

Remove Consecutive Duplicates

Default:

Enabled

---

## Auto Pin Threshold

Default:

3 Uses

Future versions may allow customization.

---

# Privacy Requirements

All clipboard history must remain on device.

Do not:

* Upload data
* Sync data
* Send analytics
* Track user behavior
* Contact external servers

Privacy Statement:

ClipLedger stores clipboard history locally on your Mac and never transmits clipboard data externally.

---

# Data Model

ClipboardItem

Fields:

id: UUID

content: String

createdAt: Date

characterCount: Int

usageCount: Int

isPinned: Bool

---

# Technical Requirements

Clipboard Monitoring:

NSPasteboard

Persistence:

SwiftData

UI:

SwiftUI

Architecture:

MVVM

Performance Requirements:

* Startup under 1 second
* Clipboard detection under 500ms
* Support at least 10,000 history operations without noticeable slowdown

---

# MVP Deliverables

Version 1.0 must include:

✓ Clipboard monitoring

✓ Clipboard history

✓ Local persistence

✓ Restore clipboard item

✓ Delete single item

✓ Clear history

✓ Menu bar application

✓ Global shortcut

✓ Auto pin

✓ Manual pin

✓ Settings page

✓ Launch at login

✓ SwiftData persistence

Anything not listed above is out of scope for Version 1.0.
