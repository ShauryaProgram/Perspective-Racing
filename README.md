# Perspective Racing

**Perspective Racing** is a next-generation sailing performance dashboard and NMEA 0183 data visualizer for iOS, designed for competitive sailors and sailing teams seeking real-time, actionable insights. The app combines high-fidelity data parsing, live TCP streaming, and an intuitive SwiftUI interface to deliver precise metrics and tactical recommendations on the water.

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Connecting to an NMEA Server](#connecting-to-an-nmea-server)
  - [Black Page: VMG & Sail Selection](#black-page-vmg--sail-selection)
- [Architecture](#architecture)
  - [Core Components](#core-components)
  - [NMEA Sentence Support](#nmea-sentence-support)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## Features

- **Live NMEA 0183 TCP Client:** Connects to any NMEA 0183 data source over Wi-Fi.
- **Robust Sentence Parsing:** Supports RMC, GGA, VTG, GLL, DBT, HDT, MWV, VWR, VWT, VHW, HDG, MWD, and more.
- **Real-Time Dashboard:** Displays Apparent Wind Speed (AWS), Apparent Wind Angle (AWA), Speed Through Water (STW), True Wind Speed (TWS), True Wind Angle (TWA), and Heading.
- **Black Page for Racing:** Presents VMG (Velocity Made Good) performance as a percentage of target polars, and recommends the optimal jib based on live wind conditions.
- **Persistent Settings:** Remembers last-used server IP and port.
- **Modern UI:** Built with SwiftUI and UIKit for a seamless, adaptive experience.
- **Debugging Tools:** Raw NMEA output display, extensive debug logging, and error feedback.

---

## Screenshots

*Coming soon: screenshots of the main dashboard, Black Page, and connection screens.*

---

## Getting Started

### Prerequisites

- **Xcode 15** or later
- **iOS 16** or later (Simulator or physical device)
- Access to an NMEA 0183 TCP data stream (e.g., from a marine electronics multiplexer or simulator)

### Installation

1. **Clone the Repository:**
   ```sh
   git clone https://github.com/ShauryaProgram/Perspective-Racing.git
   cd Perspective-Racing
   ```

2. **Open in Xcode:**
   - Double-click `Perspective.xcodeproj` or open via Xcode’s “Open Project” dialog.

3. **Build & Run:**
   - Select your target device or simulator.
   - Click **Run** (▶️) to build and launch the app.

---

## Usage

### Connecting to an NMEA Server

1. **Connect your iOS device** to the same Wi-Fi network as your NMEA data source.
2. **Launch the app.**
3. **Enter the server’s IP address and port** in the provided fields.
4. **Tap “Connect”.** The connection status will update in real time.
5. **View live data** in the dashboard grid and raw NMEA output below.

### Black Page: VMG & Sail Selection

- Tap the black square button to open the “Black Page.”
- View your current VMG (Velocity Made Good) as a percentage of target polars.
- See recommended jib based on true wind speed, with color-coded urgency.
- Tap the back arrow to return to the main dashboard.

---

## Architecture

### Core Components

- **NMEA_Client_ViewController:** Main dashboard controller; manages TCP connection, UI updates, and data flow.
- **NMEAManager:** ObservableObject handling connection state, parsing, data storage, and VMG/TWS calculations.
- **NMEAParser:** Robust parser for a wide range of NMEA 0183 sentences, with extensible data structures.
- **TCPClient:** Handles low-level TCP networking using Apple’s Network framework.
- **SwiftUI Views:** Used for app entry point, dashboard embedding, and Black Page performance view.

### NMEA Sentence Support

- **Supported Sentences:** RMC, GGA, VTG, GLL, DBT, HDT, MWV, VWR, VWT, VHW, HDG, MWD, and more.
- **Extensible:** Easily add new sentence types by extending `NMEAParser`.

---

## Customization

- **Polars & Sails:** Update polar data and sail inventory in `BlackPageViewController.swift` to match your boat or fleet.
- **UI Colors & Layout:** Tweak colors, gradients, and layout constraints in view files for your team’s branding.
- **Additional Metrics:** Add new dashboard items by extending `DataGridView` and updating `NMEAManager`.

---

## Troubleshooting

- **Cannot Connect:** Ensure your device is on the correct Wi-Fi and the server IP/port are correct.
- **No Data:** Check that your NMEA source is actively sending data; inspect raw output for malformed sentences.
- **App Crash/Freeze:** Review Xcode logs for parsing errors or connection issues.
- **Debug Prints:** Enable Xcode console to see detailed debug output for sentence parsing and state changes.

---

## Contributing

Contributions are welcome! To propose a feature or bugfix:

1. Fork the repository.
2. Create a new branch (`feature/my-feature` or `bugfix/my-bug`).
3. Commit your changes with clear messages.
4. Open a Pull Request with a detailed description.

---

## License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## Contact

**Author:** ShauryaProgram  
**Repository:** [Perspective-Racing](https://github.com/ShauryaProgram/Perspective-Racing)  
For questions or collaboration requests, open an issue or contact the maintainer directly.
---
