//
//  BonjourServiceType+UI.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation

extension BonjourServiceType {

    /// An SF Symbols system image name representing this service type.
    ///
    /// Returns a contextually appropriate symbol based on the service's display name.
    /// Falls back to `"wifi"` for unrecognized service types.
    ///
    /// Mappings are matched case-insensitively against the service type's `name` property.
    /// When adding new service types to the library, consider adding a corresponding
    /// case here if a more specific symbol exists.
    ///
    /// ## Symbol Categories
    ///
    /// | Category | Symbol Examples |
    /// |----------|---------------|
    /// | AirPlay & Streaming | `airplayvideo`, `hifispeaker.fill`, `music.note` |
    /// | Apple TV & Remotes | `appletv`, `appletvremote.gen4.fill`, `tv` |
    /// | Apple Devices | `platter.2.filled.iphone`, `macbook.and.iphone` |
    /// | HomeKit & Smart Home | `homekit`, `house.fill` |
    /// | Networking | `network`, `bonjour`, `airport.extreme` |
    /// | Terminal & Remote Access | `greaterthan.square`, `desktopcomputer` |
    /// | File Sharing | `folder.fill`, `externaldrive.fill` |
    /// | Printers & Scanners | `printer.fill`, `scanner.fill` |
    /// | Web & HTTP | `globe` |
    /// | Development | `hammer.fill`, `chevron.left.forwardslash.chevron.right` |
    /// | Databases | `cylinder.split.1x2.fill` |
    /// | Default (unknown) | `wifi` |
    public var imageSystemName: String {
        switch name.lowercased() {

        // MARK: - AirPlay & Streaming
        // Audio/video streaming protocols and music sharing services.

        /// AirPlay video/audio streaming — `airplayvideo`
        case "airplay",
            "airplay 2 undocumented":
            "airplayvideo"

        /// Remote Audio Output Protocol — `hifispeaker.fill`
        case "remote audio output protocol (raop)":
            "hifispeaker.fill"

        /// Spotify wireless speaker streaming — `hifispeaker.fill`
        case "spotify connect":
            "hifispeaker.fill"

        /// Sonos multi-room speaker system — `hifispeaker.2.fill`
        case "sonos speaker":
            "hifispeaker.2.fill"

        /// iTunes/DAAP music library sharing — `music.note`
        case "digital audio access protocol (daap)":
            "music.note"

        /// Shared iTunes/Apple Music libraries — `music.note.list`
        case "apple shared itunes library",
            "itunes home sharing":
            "music.note.list"

        /// Real-time media streaming — `play.tv`
        case "real time streaming protocol (rtsp)":
            "play.tv"

        // MARK: - Apple TV & Remotes
        // Apple TV devices, media remotes, and third-party streaming boxes.

        /// Apple TV set-top box (all generations) — `appletv`
        case "apple tv",
            "apple tv (2nd generation)",
            "apple tv (3rd generation)",
            "apple tv (4th generation)",
            "apple tv pairing",
            "apple tv discovery of itunes":
            "appletv"

        /// Apple TV Siri Remote control protocol — `appletvremote.gen4.fill`
        case "apple tv media remote":
            "appletvremote.gen4.fill"

        /// Media Remote TV protocol — `av.remote`
        case "mediaremotetv":
            "av.remote"

        /// TouchAble remote control app — `appletvremote.gen4.fill`
        case "touchable":
            "appletvremote.gen4.fill"

        /// Google Cast / Chromecast streaming — `tv`
        case "google cast",
            "chromecast":
            "tv"

        /// Roku streaming device control — `tv`
        case "roku control protocol":
            "tv"

        /// Android TV remote control — `tv`
        case "android tv remote":
            "tv"

        // MARK: - Apple Devices
        // Apple mobile devices, desktop sync, and cross-device features.

        /// Apple mobile device sync and management — `platter.2.filled.iphone`
        case "apple mobile device protocol",
            "apple mobile device protocol v2",
            "osx wi-fi sync":
            "platter.2.filled.iphone"

        /// Apple Continuity (Handoff, Universal Clipboard) — `macbook.and.iphone`
        case "apple continuity":
            "macbook.and.iphone"

        /// macOS device information broadcast — `desktopcomputer`
        case "osx device info":
            "desktopcomputer"

        /// CarPlay vehicle integration — `car.fill`
        case "carplay control":
            "car.fill"

        // MARK: - HomeKit & Smart Home
        // Home automation protocols and smart home platforms.

        /// Apple HomeKit accessory control — `homekit`
        case "apple homekit",
            "homekit accessory protocol (hap)":
            "homekit"

        /// Matter smart home interoperability protocol — `homekit`
        case "matter smart home protocol":
            "homekit"

        /// Home Assistant open-source home automation — `house.fill`
        case "home assistant":
            "house.fill"

        // MARK: - Networking & Infrastructure
        // Network protocols, DNS, IoT, and wireless infrastructure.

        /// Bonjour sleep proxy for Wake-on-Demand — `bonjour`
        case "bonjour sleep proxy":
            "bonjour"

        /// Apple AirPort Wi-Fi base station — `airport.extreme`
        case "airport base station":
            "airport.extreme"

        /// Domain Name System resolution — `network`
        case "domain name service (dns)":
            "network"

        /// Multicast DNS service discovery — `network`
        case "mdns service discovery (dns-sd)":
            "network"

        /// Constrained Application Protocol (IoT) — `network`
        case "coap protocol":
            "network"

        /// MQTT message broker protocol (IoT) — `network`
        case "mqtt protocol":
            "network"

        /// Simple Service Discovery Protocol (UPnP) — `network`
        case "ssdp (upnp)":
            "network"

        /// Wi-Fi Calling voice over Wi-Fi — `phone.fill`
        case "wi-fi calling":
            "phone.fill"

        // MARK: - Terminal & Remote Access
        // Secure shell, remote desktop, and server management protocols.

        /// SSH, SFTP, and secure login protocols — `greaterthan.square`
        case "remote login",
            "secure shell (ssh)",
            "secure sockets layer (ssl, or https)",
            "sftp (ssh file transfer)":
            "greaterthan.square"

        /// Remote desktop and screen sharing — `desktopcomputer`
        case "remote desktop protocol (rdp)",
            "vnc remote access",
            "remote frame buffer (rfb)",
            "remote management":
            "desktopcomputer"

        // MARK: - File Sharing & Storage
        // Network file systems, file transfer, and storage devices.

        /// Network file sharing protocols (SMB, AFP, NFS, WebDAV) — `folder.fill`
        case "smb file sharing",
            "smb windows sharing",
            "appletalk filing protocol (afp)",
            "network file system (nfs)",
            "webdav file system":
            "folder.fill"

        /// FTP file upload/download — `arrow.up.arrow.down.square`
        case "file transfer protocol (ftp)":
            "arrow.up.arrow.down.square"

        /// Time Capsule network backup storage — `externaldrive.fill`
        case "time capsule backups":
            "externaldrive.fill"

        /// AirDrop peer-to-peer file transfer — `antenna.radiowaves.left.and.right`
        case "airdrop":
            "antenna.radiowaves.left.and.right"

        /// Third-party NAS and file sharing apps — `externaldrive.fill`
        case "es file share app",
            "es file share app 2",
            "netgear readynas":
            "externaldrive.fill"

        // MARK: - Printers & Scanners
        // Network printing and scanning protocols.

        /// Network printing protocols (LPD, IPP, PDL, USB) — `printer.fill`
        case "line printer daemon (lpd)",
            "internet printing protocol (ipp)",
            "pdl data stream (port 9100)",
            "remote io usb printer protocol",
            "ipp secure (ipps)":
            "printer.fill"

        /// Network document scanners — `scanner.fill`
        case "scanners",
            "network scanner",
            "network scanner (secure)":
            "scanner.fill"

        // MARK: - Web & HTTP
        // Web server protocols.

        /// HTTP/HTTPS web servers — `globe`
        case "http",
            "https (secure http)",
            "http alternate (port 8080)":
            "globe"

        // MARK: - Development & CI
        // Developer tools, build systems, and version control.

        /// Jenkins CI/CD automation server — `hammer.fill`
        case "jenkins app",
            "jenkins app 2":
            "hammer.fill"

        /// Distributed C/C++ compiler — `gearshape.2.fill`
        case "distributed compiler (distcc)":
            "gearshape.2.fill"

        /// Version control protocols (SVN, Git) — `chevron.left.forwardslash.chevron.right`
        case "subversion (svn)",
            "git protocol":
            "chevron.left.forwardslash.chevron.right"

        // MARK: - Databases
        // Database server protocols.

        /// SQL database servers (PostgreSQL, MySQL) — `cylinder.split.1x2.fill`
        case "postgresql database",
            "mysql database":
            "cylinder.split.1x2.fill"

        // MARK: - Messaging & Chat
        // Instant messaging and chat protocols.

        /// Instant messaging protocols (iChat, XMPP/Jabber) — `bubble.left.fill`
        case "ichat instant messaging protocol",
            "ichat instant messaging (deprecated)",
            "xmpp client (jabber)":
            "bubble.left.fill"

        // MARK: - Presentations
        // Keynote and presentation sharing.

        /// Apple Keynote presentation sharing — `play.rectangle.fill`
        case "osx keynote",
            "osx keynote 2",
            "keynote access",
            "keynote pairing":
            "play.rectangle.fill"

        // MARK: - Camera & Photo
        // Photo sharing, image capture, and action cameras.

        /// Photo sharing and image capture protocols — `camera.fill`
        case "digital photo access protocol (dpap)",
            "image capture sharing",
            "picture transfer protocol":
            "camera.fill"

        /// GoPro action camera control — `camera.fill`
        case "gopro wake",
            "gopro web":
            "camera.fill"

        // MARK: - Gaming
        // Game streaming and gaming device protocols.

        /// NVIDIA Shield game streaming — `gamecontroller.fill`
        case "nvidia shield game streaming",
            "nvidia shield android tv":
            "gamecontroller.fill"

        // MARK: - Monitoring
        // Server and infrastructure monitoring.

        /// Prometheus metrics and alerting — `chart.line.uptrend.xyaxis`
        case "prometheus monitoring":
            "chart.line.uptrend.xyaxis"

        // MARK: - Other Apple Services
        // Server administration, MIDI, debugging, and legacy Apple services.

        /// macOS Server administration tools — `squares.leading.rectangle`
        case "workgroup manager",
            "server admin":
            "squares.leading.rectangle"

        /// Apple password and authentication server — `lock.fill`
        case "apple password server":
            "lock.fill"

        /// Apple MIDI network session protocol — `pianokeys`
        case "apple midi":
            "pianokeys"

        /// Apple remote debugging services — `ant.fill`
        case "apple remote debug services":
            "ant.fill"

        /// Xserve RAID storage array — `xserve`
        case "xserve raid":
            "xserve"

        // MARK: - Third Party
        // Third-party apps and services.

        /// Sketch design app mirroring — `paintbrush.fill`
        case "sketch app",
            "sketch app 2":
            "paintbrush.fill"

        /// Adobe Photoshop remote navigation — `paintbrush.pointed.fill`
        case "adobe photoshop nav":
            "paintbrush.pointed.fill"

        /// Amazon wireless playback devices — `dot.radiowaves.right`
        case "amazon devices":
            "dot.radiowaves.right"

        /// AirDroid wireless device management — `antenna.radiowaves.left.and.right`
        case "airdroid app":
            "antenna.radiowaves.left.and.right"

        /// Physical Web Eddystone beacons — `link`
        case "physical web":
            "link"

        /// LDAP directory service — `person.2.fill`
        case "ldap directory":
            "person.2.fill"

        // MARK: - Default

        /// Fallback for unrecognized service types — `wifi`
        default:
            "wifi"
        }
    }
}
