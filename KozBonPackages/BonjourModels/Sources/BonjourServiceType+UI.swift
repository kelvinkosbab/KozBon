//
//  BonjourServiceType+UI.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore

extension BonjourServiceType {

    /// An SF Symbols system image name representing this service type.
    ///
    /// Returns a contextually appropriate symbol based on the service's display name.
    /// Falls back to `Iconography.wifi` for unrecognized service types.
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

        /// AirPlay video/audio streaming
        case "airplay",
            "airplay 2 undocumented":
            Iconography.airplayVideo

        /// Remote Audio Output Protocol
        case "remote audio output protocol (raop)":
            Iconography.speaker

        /// Spotify wireless speaker streaming
        case "spotify connect":
            Iconography.speaker

        /// Sonos multi-room speaker system
        case "sonos speaker":
            Iconography.multiSpeaker

        /// iTunes/DAAP music library sharing
        case "digital audio access protocol (daap)":
            Iconography.musicNote

        /// Shared iTunes/Apple Music libraries
        case "apple shared itunes library",
            "itunes home sharing":
            Iconography.musicNoteList

        /// Real-time media streaming
        case "real time streaming protocol (rtsp)":
            Iconography.playTV

        // MARK: - Apple TV & Remotes
        // Apple TV devices, media remotes, and third-party streaming boxes.

        /// Apple TV set-top box (all generations)
        case "apple tv",
            "apple tv (2nd generation)",
            "apple tv (3rd generation)",
            "apple tv (4th generation)",
            "apple tv pairing",
            "apple tv discovery of itunes":
            Iconography.appleTV

        /// Apple TV Siri Remote control protocol
        case "apple tv media remote":
            Iconography.appleTVRemote

        /// Media Remote TV protocol
        case "mediaremotetv":
            Iconography.avRemote

        /// TouchAble remote control app
        case "touchable":
            Iconography.appleTVRemote

        /// Google Cast / Chromecast streaming
        case "google cast",
            "chromecast":
            Iconography.tv

        /// Roku streaming device control
        case "roku control protocol":
            Iconography.tv

        /// Android TV remote control
        case "android tv remote":
            Iconography.tv

        // MARK: - Apple Devices
        // Apple mobile devices, desktop sync, and cross-device features.

        /// Apple mobile device sync and management
        case "apple mobile device protocol",
            "apple mobile device protocol v2",
            "osx wi-fi sync":
            Iconography.mobileDevice

        /// Apple Continuity (Handoff, Universal Clipboard)
        case "apple continuity":
            Iconography.macAndIphone

        /// macOS device information broadcast
        case "osx device info":
            Iconography.desktop

        /// CarPlay vehicle integration
        case "carplay control":
            Iconography.car

        // MARK: - HomeKit & Smart Home
        // Home automation protocols and smart home platforms.

        /// Apple HomeKit accessory control
        case "apple homekit",
            "homekit accessory protocol (hap)":
            Iconography.homeKit

        /// Matter smart home interoperability protocol
        case "matter smart home protocol":
            Iconography.homeKit

        /// Home Assistant open-source home automation
        case "home assistant":
            Iconography.house

        // MARK: - Networking & Infrastructure
        // Network protocols, DNS, IoT, and wireless infrastructure.

        /// Bonjour sleep proxy for Wake-on-Demand
        case "bonjour sleep proxy":
            Iconography.bonjour

        /// Apple AirPort Wi-Fi base station
        case "airport base station":
            Iconography.airportExtreme

        /// Domain Name System resolution
        case "domain name service (dns)":
            Iconography.network

        /// Multicast DNS service discovery
        case "mdns service discovery (dns-sd)":
            Iconography.network

        /// Constrained Application Protocol (IoT)
        case "coap protocol":
            Iconography.network

        /// MQTT message broker protocol (IoT)
        case "mqtt protocol":
            Iconography.network

        /// Simple Service Discovery Protocol (UPnP)
        case "ssdp (upnp)":
            Iconography.network

        /// Wi-Fi Calling voice over Wi-Fi
        case "wi-fi calling":
            Iconography.phone

        // MARK: - Terminal & Remote Access
        // Secure shell, remote desktop, and server management protocols.

        /// SSH, SFTP, and secure login protocols
        case "remote login",
            "secure shell (ssh)",
            "secure sockets layer (ssl, or https)",
            "sftp (ssh file transfer)":
            Iconography.terminal

        /// Remote desktop and screen sharing
        case "remote desktop protocol (rdp)",
            "vnc remote access",
            "remote frame buffer (rfb)",
            "remote management":
            Iconography.desktop

        // MARK: - File Sharing & Storage
        // Network file systems, file transfer, and storage devices.

        /// Network file sharing protocols (SMB, AFP, NFS, WebDAV)
        case "smb file sharing",
            "smb windows sharing",
            "appletalk filing protocol (afp)",
            "network file system (nfs)",
            "webdav file system":
            Iconography.folder

        /// FTP file upload/download
        case "file transfer protocol (ftp)":
            Iconography.fileTransfer

        /// Time Capsule network backup storage
        case "time capsule backups":
            Iconography.externalDrive

        /// AirDrop peer-to-peer file transfer
        case "airdrop":
            Iconography.antenna

        /// Third-party NAS and file sharing apps
        case "es file share app",
            "es file share app 2",
            "netgear readynas":
            Iconography.externalDrive

        // MARK: - Printers & Scanners
        // Network printing and scanning protocols.

        /// Network printing protocols (LPD, IPP, PDL, USB)
        case "line printer daemon (lpd)",
            "internet printing protocol (ipp)",
            "pdl data stream (port 9100)",
            "remote io usb printer protocol",
            "ipp secure (ipps)":
            Iconography.printer

        /// Network document scanners
        case "scanners",
            "network scanner",
            "network scanner (secure)":
            Iconography.scanner

        // MARK: - Web & HTTP
        // Web server protocols.

        /// HTTP/HTTPS web servers
        case "http",
            "https (secure http)",
            "http alternate (port 8080)":
            Iconography.globe

        // MARK: - Development & CI
        // Developer tools, build systems, and version control.

        /// Jenkins CI/CD automation server
        case "jenkins app",
            "jenkins app 2":
            Iconography.build

        /// Distributed C/C++ compiler
        case "distributed compiler (distcc)":
            Iconography.gears

        /// Version control protocols (SVN, Git)
        case "subversion (svn)",
            "git protocol":
            Iconography.sourceControl

        // MARK: - Databases
        // Database server protocols.

        /// SQL database servers (PostgreSQL, MySQL)
        case "postgresql database",
            "mysql database":
            Iconography.database

        // MARK: - Messaging & Chat
        // Instant messaging and chat protocols.

        /// Instant messaging protocols (iChat, XMPP/Jabber)
        case "ichat instant messaging protocol",
            "ichat instant messaging (deprecated)",
            "xmpp client (jabber)":
            Iconography.chat

        // MARK: - Presentations
        // Keynote and presentation sharing.

        /// Apple Keynote presentation sharing
        case "osx keynote",
            "osx keynote 2",
            "keynote access",
            "keynote pairing":
            Iconography.playRectangle

        // MARK: - Camera & Photo
        // Photo sharing, image capture, and action cameras.

        /// Photo sharing and image capture protocols
        case "digital photo access protocol (dpap)",
            "image capture sharing",
            "picture transfer protocol":
            Iconography.camera

        /// GoPro action camera control
        case "gopro wake",
            "gopro web":
            Iconography.camera

        // MARK: - Gaming
        // Game streaming and gaming device protocols.

        /// NVIDIA Shield game streaming
        case "nvidia shield game streaming",
            "nvidia shield android tv":
            Iconography.gameController

        // MARK: - Monitoring
        // Server and infrastructure monitoring.

        /// Prometheus metrics and alerting
        case "prometheus monitoring":
            Iconography.chart

        // MARK: - Other Apple Services
        // Server administration, MIDI, debugging, and legacy Apple services.

        /// macOS Server administration tools
        case "workgroup manager",
            "server admin":
            Iconography.adminPanels

        /// Apple password and authentication server
        case "apple password server":
            Iconography.lock

        /// Apple MIDI network session protocol
        case "apple midi":
            Iconography.pianoKeys

        /// Apple remote debugging services
        case "apple remote debug services":
            Iconography.debug

        /// Xserve RAID storage array
        case "xserve raid":
            Iconography.xserve

        // MARK: - Third Party
        // Third-party apps and services.

        /// Sketch design app mirroring
        case "sketch app",
            "sketch app 2":
            Iconography.paintbrush

        /// Adobe Photoshop remote navigation
        case "adobe photoshop nav":
            Iconography.paintbrushPointed

        /// Amazon wireless playback devices
        case "amazon devices":
            Iconography.radioWaves

        /// AirDroid wireless device management
        case "airdroid app":
            Iconography.antenna

        /// Physical Web Eddystone beacons
        case "physical web":
            Iconography.link

        /// LDAP directory service
        case "ldap directory":
            Iconography.people

        // MARK: - Default

        /// Fallback for unrecognized service types
        default:
            Iconography.wifi
        }
    }
}
