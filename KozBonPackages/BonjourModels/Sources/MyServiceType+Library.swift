//
//  MyServiceType+Library.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import Foundation
import BonjourCore

// Service type library — long detail strings are expected
// swiftlint:disable line_length file_length

extension BonjourServiceType {

    // MARK: - TCP Service Types

    /// For a full list of all registered services: http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml
    /// More at https://support.apple.com/en-us/HT202944
    public static var tcpServiceTypes: [BonjourServiceType] {
        return [
            self.powerViewHubV2,
            self.spotifyConnect,
            self.netBIOSSessionService,
            self.rokuControlProtocol,
            self.beatsTransferProtocol,
            self.androidTvRemote,
            self.googleXpeditionsTcp,
            self.googleCast,
            self.mediaRemoteTv,
            self.airplayTcp,
            self.airdrop,
            self.appleMobileDeviceProtocol,
            self.appleMobileDeviceProtocolV2,
            self.appleMIDI,
            self.appleRemoteDebugServices,
            self.appleTV,
            self.appleTVv2,
            self.appleTVv3,
            self.appleTVv4,
            self.appleTViTunes,
            self.appleTVPairing,
            self.keynoteAccess,
            self.keynotePairing,
            self.homeKitAccessoryProtocol,
            self.appleTalkFilingProtocol,
            self.networkFileSystem,
            self.webDAVFileSystem,
            self.fileTransferProtocol,
            self.secureShell,
            self.remoteAppleEvents,
            self.http,
            self.https,
            self.remoteLogin,
            self.linePrinterDaemon,
            self.internetPrintingProtocol,
            self.pdlDataStream,
            self.remoteIOUSBPrinterProtocol,
            self.digitalAudioAccessProtocol,
            self.digitalPhotoAccessProtocol,
            self.iChatInstantMessagingProtocolDeprecated,
            self.imageCaptureSharing,
            self.airPortBaseStation,
            self.xServeRAID,
            self.distributedCompiler,
            self.applePasswordServer,
            self.workgroupManager,
            self.serverAdmin,
            self.remoteAudioOutputProtocol,
            self.touchAble,
            self.remoteFrameBuffer,
            self.rtspTcp,
            self.timeCapsuleBackups,
            self.airDroidApp,
            self.amazonDevices,
            self.appleSharediTunesLibrary,
            self.sketchApp,
            self.sketchApp2,
            self.airplay2Undocumented,
            self.osxDeviceInfo,
            self.esFileShareApp,
            self.esFileShareApp2,
            self.appleHomeKit,
            self.iTunesHomeSharing,
            self.jenkinsApp,
            self.jenkinsApp2,
            self.iChatInstantMessagingProtocol2,
            self.osxKeynote,
            self.osxKeynote2,
            self.nVIDIAShieldGameStreaming,
            self.omniGroupOmniGraffleAndOtherApps,
            self.adobePhotoshopNav,
            self.netgearReadyNAS,
            self.physicalWeb,
            self.scanners,
            self.ubuntuRaspberryPiAdvertisement,
            self.smbFileSharing,
            self.ippSecure,
            self.companionLink,
            self.remoteDesktopProtocol,
            self.sftpSSH,
            self.httpAlternate,
            self.networkScanner,
            self.networkScannerSecure,
            self.carPlayControl,
            self.matterSmartHome,
            self.sonosSpeaker,
            self.remoteManagement,
            self.pictureTransferProtocol,
            self.chromecast,
            self.mqttProtocol,
            self.appleContinuity,
            self.smbWindowsSharing,
            self.subversion,
            self.gitProtocol,
            self.domainNameService,
            self.xmppClient,
            self.ldapDirectory,
            self.postgreSQLDatabase,
            self.mySQLDatabase,
            self.homeAssistant,
            self.vncRemoteAccess,
            self.prometheusMonitoring,
            // MARK: Tier 1 additions — media servers, smart home, mail/calendar, modern dev
            self.plexMediaServer,
            self.jellyfinMediaServer,
            self.kodiMediaCenter,
            self.philipsHueBridge,
            self.ecobeeThermostat,
            self.octoPrint,
            self.calDAV,
            self.calDAVSecure,
            self.cardDAV,
            self.cardDAVSecure,
            self.imap,
            self.imapSecure,
            self.smtp,
            self.smtpSecure,
            self.smtpSubmission,
            self.pop3,
            self.pop3Secure,
            self.syncthing,
            self.warpinator,
            self.redisDatabase,
            self.gRPC,
            self.hashiCorpConsul,
            self.appleMobileDeviceProtocolV3,
            // MARK: Tier 2 additions
            self.embyMediaServer,
            self.steamLink,
            self.minecraftLAN,
            self.sipTcp,
            self.piHole,
            self.klipper3DPrinter,
            self.tasmotaIoT,
            // MARK: Tier 3 additions — encrypted DNS, enterprise auth, audio
            self.dnsOverTls,
            self.dnsOverHttps,
            self.kerberosTcp,
            self.pulseAudioServer
        ]
    }

    static private let timeCapsuleBackups: BonjourServiceType = BonjourServiceType(
        name: "Time Capsule Backups",
        type: "adisk",
        transportLayer: .tcp,
        detail: "Apple Time Capsule network backup appliance for wireless Time Machine backups."
    )
    static private let airDroidApp: BonjourServiceType = BonjourServiceType(
        name: "AirDroid App",
        type: "airdroid",
        transportLayer: .tcp,
        detail: "AirDroid wireless device management app for file transfer and remote access between mobile devices and computers."
    )
    static private let amazonDevices: BonjourServiceType = BonjourServiceType(
        name: "Amazon Devices",
        type: "amzn-wplay",
        transportLayer: .tcp,
        detail: "Amazon wireless playback service for discovering and streaming to Amazon Echo, Fire TV, and other Alexa-enabled devices."
    )
    static private let osxWiFiSync: BonjourServiceType = BonjourServiceType(
        name: "OSX Wi-Fi Sync",
        type: "apple-mobdev2",
        transportLayer: .tcp,
        detail: "Apple Wi-Fi Sync for wirelessly syncing iOS devices with iTunes or Finder on macOS."
    )
    static private let appleSharediTunesLibrary: BonjourServiceType = BonjourServiceType(
        name: "Apple Shared iTunes Library",
        type: "atc",
        transportLayer: .tcp,
        detail: "Apple shared iTunes/Music library for discovering shared media libraries on the local network."
    )
    static private let sketchApp: BonjourServiceType = BonjourServiceType(
        name: "Sketch App",
        type: "sketchmirror",
        transportLayer: .tcp,
        detail: "Sketch design app mirror service for previewing designs on iOS devices in real time."
    )
    static private let sketchApp2: BonjourServiceType = BonjourServiceType(
        name: "Sketch App",
        type: "bcbonjour",
        transportLayer: .tcp,
        detail: "Sketch design app mirror service for previewing designs on iOS devices in real time."
    )
    static private let airplay2Undocumented: BonjourServiceType = BonjourServiceType(
        name: "AirPlay 2 Undocumented",
        type: "cloud",
        transportLayer: .tcp,
        detail: "Undocumented AirPlay 2 service type used by Apple devices for enhanced audio streaming and multi-room playback."
    )
    static private let cloudByDapile: BonjourServiceType = BonjourServiceType(
        name: "Cloud by Dapile",
        type: "amzn-wplay",
        transportLayer: .tcp
    )
    static private let osxDeviceInfo: BonjourServiceType = BonjourServiceType(
        name: "OSX Device Info",
        type: "device-info",
        transportLayer: .tcp,
        detail: "macOS device information broadcast for identifying Mac computers on the local network."
    )
    static private let esFileShareApp: BonjourServiceType = BonjourServiceType(
        name: "ES File Share App",
        type: "esdevice",
        transportLayer: .tcp,
        detail: "ES File Explorer file sharing service for wireless file transfer between mobile devices and computers."
    )
    static private let esFileShareApp2: BonjourServiceType = BonjourServiceType(
        name: "ES File Share App",
        type: "esfileshare",
        transportLayer: .tcp,
        detail: "ES File Explorer file sharing service for wireless file transfer between mobile devices and computers."
    )
    static private let appleHomeKit: BonjourServiceType = BonjourServiceType(
        name: "Apple HomeKit",
        type: "homekit",
        transportLayer: .tcp,
        detail: "Apple HomeKit service for discovering and controlling smart home accessories on the local network."
    )
    static private let iTunesHomeSharing: BonjourServiceType = BonjourServiceType(
        name: "iTunes Home Sharing",
        type: "home-sharing",
        transportLayer: .tcp,
        detail: "iTunes Home Sharing for streaming music, movies, and TV shows between authorized computers and Apple devices on the same network."
    )
    static private let jenkinsApp: BonjourServiceType = BonjourServiceType(
        name: "Jenkins App",
        type: "hudson",
        transportLayer: .tcp,
        detail: "Jenkins CI/CD automation server for continuous integration and continuous delivery of software projects."
    )
    static private let jenkinsApp2: BonjourServiceType = BonjourServiceType(
        name: "Jenkins App",
        type: "jenkins",
        transportLayer: .tcp,
        detail: "Jenkins CI/CD automation server for continuous integration and continuous delivery of software projects."
    )
    static private let iChatInstantMessagingProtocol: BonjourServiceType = BonjourServiceType(
        name: "iChat Instant Messaging Protocol",
        type: "ichat",
        transportLayer: .tcp
    )
    static private let osxKeynote: BonjourServiceType = BonjourServiceType(
        name: "OSX Keynote",
        type: "KeynoteControl",
        transportLayer: .tcp,
        detail: "Apple Keynote presentation sharing and remote control service."
    )
    static private let osxKeynote2: BonjourServiceType = BonjourServiceType(
        name: "OSX Keynote",
        type: "keynotepair",
        transportLayer: .tcp,
        detail: "Apple Keynote presentation sharing and remote control service."
    )
    static private let appleTVMediaRemote: BonjourServiceType = BonjourServiceType(
        name: "Apple TV Media Remote",
        type: "mediaremotetv",
        transportLayer: .tcp,
        detail: "Apple TV Media Remote protocol for controlling Apple TV playback, navigation, and input from iOS devices and Macs."
    )
    static private let nVIDIAShieldGameStreaming: BonjourServiceType = BonjourServiceType(
        name: "NVIDIA Shield Game Streaming",
        type: "nvstream",
        transportLayer: .tcp,
        detail: "NVIDIA Shield GameStream service for streaming PC games to NVIDIA Shield devices over the local network."
    )
    static private let nvidiaShieldAndroidTV: BonjourServiceType = BonjourServiceType(
        name: "Nvidia Shield / Android TV",
        type: "androidtvremote",
        transportLayer: .tcp,
        detail: "NVIDIA Shield Android TV discovery service for identifying Shield TV devices on the local network."
    )
    static private let omniGroupOmniGraffleAndOtherApps: BonjourServiceType = BonjourServiceType(
        name: "OmniGroup (OmniGraffle and other apps)",
        type: "omnistate",
        transportLayer: .tcp,
        detail: "OmniGroup app sync service used by OmniGraffle, OmniOutliner, and other OmniGroup productivity apps."
    )
    static private let adobePhotoshopNav: BonjourServiceType = BonjourServiceType(
        name: "Adobe Photoshop Nav",
        type: "photoshopserver",
        transportLayer: .tcp,
        detail: "Adobe Photoshop remote navigation service for controlling Photoshop from a tablet or mobile device."
    )
    static private let netgearReadyNAS: BonjourServiceType = BonjourServiceType(
        name: "Netgear ReadyNAS",
        type: "readynas",
        transportLayer: .tcp,
        detail: "Netgear ReadyNAS network-attached storage device discovery and management."
    )
    static private let physicalWeb: BonjourServiceType = BonjourServiceType(
        name: "Physical Web",
        type: "physicalweb",
        transportLayer: .tcp,
        detail: "Physical Web (Eddystone) beacon discovery service for interacting with nearby Bluetooth LE beacons broadcasting URLs."
    )
    static private let scanners: BonjourServiceType = BonjourServiceType(
        name: "Scanners",
        type: "scanner",
        transportLayer: .tcp,
        detail: "Network scanner discovery service for locating scanners and multifunction devices on the local network."
    )
    static private let ubuntuRaspberryPiAdvertisement: BonjourServiceType = BonjourServiceType(
        name: "Ubuntu / Raspberry Pi Advertisement",
        type: "udisks-ssh",
        transportLayer: .tcp,
        detail: "Linux device advertisement service commonly used by Ubuntu and Raspberry Pi devices to announce their presence on the network."
    )
    static private let powerViewHubV2: BonjourServiceType = BonjourServiceType(
        name: "PowerView Hub 2.0",
        type: "powerview",
        transportLayer: .tcp,
        detail: "Hunter Douglas PowerView Hub 2.0 for controlling motorized window blinds and shades over the local network."
    )
    static private let spotifyConnect: BonjourServiceType = BonjourServiceType(
        name: "Spotify Connect",
        type: "spotify-connect",
        transportLayer: .tcp,
        detail: "Spotify Connect service for discovering and streaming music to Spotify-enabled speakers, TVs, and other devices."
    )
    static private let netBIOSSessionService: BonjourServiceType = BonjourServiceType(
        name: "NetBIOS Session Service",
        type: "netbios-ssn",
        transportLayer: .tcp,
        detail: "NetBIOS Session Service for legacy Windows file and printer sharing over TCP/IP networks."
    )
    static private let rokuControlProtocol: BonjourServiceType = BonjourServiceType(
        name: "ROKU Control Protocol",
        type: "roku-rcp",
        transportLayer: .tcp,
        detail: "Roku External Control Protocol (ECP) for discovering and controlling Roku streaming devices on the local network."
    )
    static private let beatsTransferProtocol: BonjourServiceType = BonjourServiceType(
        name: "Beats Transfer Protocol",
        type: "btp",
        transportLayer: .tcp,
        detail: "Beats Transfer Protocol for discovering and configuring Beats audio products including headphones, earbuds, and speakers."
    )
    static private let androidTvRemote: BonjourServiceType = BonjourServiceType(
        name: "Android TV Remote",
        type: "androidtvremote",
        transportLayer: .tcp,
        detail: "Android TV Remote Service for discovering and controlling Android TV devices from mobile phones and tablets."
    )
    static private let googleXpeditionsTcp: BonjourServiceType = BonjourServiceType(
        name: "Google Expeditions",
        type: "googlexpeditions",
        transportLayer: .tcp,
        detail: "Service related to Google Expeditions which is a technology for enabling multi-participant virtual fieldtrip experiences over a local wireless network. See http://g.co/expeditions for more details"
    )
    static private let googleCast: BonjourServiceType = BonjourServiceType(
        name: "Google Cast",
        type: "googlecast",
        transportLayer: .tcp,
        detail: "Service related to Google Cast which is a technology for enabling multi-screen experiences. See developers.google.com/cast for more details"
    )
    static private let mediaRemoteTv: BonjourServiceType = BonjourServiceType(
        name: "MediaRemoteTV",
        type: "mediaremotetv",
        transportLayer: .tcp,
        detail: "MediaRemoteTV is a TCP based protocol which uses length prefixed protobuf encoded messages to communicate between the client and server. The Apple TV acts as the server and clients can connect to it in order to issue various commands (playback, keyboard, voice, game controller, etc). All messages are encrypted after negotiating the pairing between the client and the Apple TV. For more information visit https://github.com/jeanregisser/mediaremotetv-protocol/tree/master/communication."
    )
    static private let airplayTcp: BonjourServiceType = BonjourServiceType(
        name: "Airplay",
        type: "airplay",
        transportLayer: .tcp,
        detail: "Protocol for streaming audio / video content"
    )
    static private let airdrop: BonjourServiceType = BonjourServiceType(
        name: "Airdrop",
        type: "airdrop",
        transportLayer: .tcp,
        detail: "Apple AirDrop peer-to-peer file sharing service for wirelessly transferring files, photos, and links between nearby Apple devices."
    )
    static private let appleMobileDeviceProtocol: BonjourServiceType = BonjourServiceType(
        name: "Apple Mobile Device Protocol",
        type: "apple-mobdev",
        transportLayer: .tcp,
        detail: "Apple Mobile Device Protocol for communication between iOS devices and macOS for syncing, debugging, and management."
    )
    static private let appleMobileDeviceProtocolV2: BonjourServiceType = BonjourServiceType(
        name: "Apple Mobile Device Protocol V2",
        type: "apple-mobdev2",
        transportLayer: .tcp,
        detail: "Apple Mobile Device Protocol version 2 for enhanced communication between iOS devices and macOS."
    )
    static private let appleMIDI: BonjourServiceType = BonjourServiceType(
        name: "Apple MIDI",
        type: "apple-midi",
        transportLayer: .tcp,
        detail: "Apple MIDI Network Session protocol for sending MIDI messages between devices over a local network, used by music production apps and instruments."
    )
    static private let appleRemoteDebugServices: BonjourServiceType = BonjourServiceType(
        name: "Apple Remote Debug Services (OpenGL Profiler)",
        type: "applerdbg",
        transportLayer: .tcp,
        detail: "Apple Remote Debug Services including OpenGL Profiler for remote GPU debugging and performance analysis of graphics applications."
    )
    static private let appleTV: BonjourServiceType = BonjourServiceType(
        name: "Apple TV",
        type: "appletv",
        transportLayer: .tcp,
        detail: "Original Apple TV discovery service for identifying first-generation Apple TV devices on the local network."
    )
    static private let appleTVv2: BonjourServiceType = BonjourServiceType(
        name: "Apple TV (2nd Generation)",
        type: "appletv-v2",
        transportLayer: .tcp,
        detail: "Apple TV (2nd generation) discovery service with support for AirPlay and Netflix streaming."
    )
    static private let appleTVv3: BonjourServiceType = BonjourServiceType(
        name: "Apple TV (3rd Generation)",
        type: "appletv-v3",
        transportLayer: .tcp,
        detail: "Apple TV (3rd generation) discovery service with 1080p video support."
    )
    static private let appleTVv4: BonjourServiceType = BonjourServiceType(
        name: "Apple TV (4th Generation)",
        type: "appletv-v4",
        transportLayer: .tcp,
        detail: "Apple TV (4th generation) discovery service with tvOS app support and Siri Remote."
    )
    static private let appleTViTunes: BonjourServiceType = BonjourServiceType(
        name: "Apple TV Discovery of iTunes",
        type: "appletv-itunes",
        transportLayer: .tcp,
        detail: "Apple TV iTunes Store discovery for browsing and purchasing content directly on Apple TV."
    )
    static private let appleTVPairing: BonjourServiceType = BonjourServiceType(
        name: "Apple TV Pairing",
        type: "appletv-pair",
        transportLayer: .tcp,
        detail: "Apple TV pairing service for establishing secure connections between Apple TV and remote control devices."
    )
    static private let keynoteAccess: BonjourServiceType = BonjourServiceType(
        name: "KeynoteAccess",
        type: "keynoteaccess",
        transportLayer: .tcp,
        detail: "KeynoteAccess is used for sending remote requests/responses when controlling a slideshow with Keynote Remote"
    )
    static private let keynotePairing: BonjourServiceType = BonjourServiceType(
        name: "KeynotePairing",
        type: "keynotepairing",
        transportLayer: .tcp,
        detail: "KeynotePairing is used to pair Keynote Remote with Keynote"
    )
    static private let homeKitAccessoryProtocol: BonjourServiceType = BonjourServiceType(
        name: "HomeKit Accessory Protocol (HAP)",
        type: "hap",
        transportLayer: .tcp,
        detail: "HomeKit speaks HomeKit Accessory Protocol (HAP), which runs on top of a BLE/Bluetooth Smart or an HTTP/TCP/IP stack.  If an accessory does not support HAP directly a gateway is needed."
    )
    static private let touchAble: BonjourServiceType = BonjourServiceType(
        name: "Touchable",
        type: "touch-able",
        transportLayer: .tcp,
        detail: "Touchable app service for using an iOS device as a remote control for music production software like Ableton Live."
    )
    static private let remoteFrameBuffer: BonjourServiceType = BonjourServiceType(
        name: "Remote Frame Buffer",
        type: "rfb",
        transportLayer: .tcp,
        detail: "RFB (remote framebuffer) is a simple protocol for remote access to graphical user interfaces. Because it works at the framebuffer level it is applicable to all windowing systems and applications, including Microsoft Windows, macOS and the X Window System. RFB is the protocol used in Virtual Network Computing (VNC) and its derivatives."
    )
    static private let rtspTcp: BonjourServiceType = BonjourServiceType(
        name: "Real Time Streaming Protocol (RTSP)",
        type: "rtsp",
        transportLayer: .tcp,
        detail: "AirPlay, QuickTime Streaming Server (QTSS), streaming media players"
    )
    static private let appleTalkFilingProtocol: BonjourServiceType = BonjourServiceType(
        name: "AppleTalk Filing Protocol (AFP)",
        type: "afpovertcp",
        transportLayer: .tcp,
        detail: "Used by Personal File Sharing in the Sharing preference panel starting in Mac OS X 10.2. The Finder browses for AFP servers starting in Mac OS X 10.2."
    )
    static private let networkFileSystem: BonjourServiceType = BonjourServiceType(
        name: "Network File System (NFS)",
        type: "nfs",
        transportLayer: .tcp,
        detail: "The Finder browses for NFS servers starting in Mac OS X 10.2."
    )
    static private let webDAVFileSystem: BonjourServiceType = BonjourServiceType(
        name: "WebDAV File System (WEBDAV)",
        type: "webdav",
        transportLayer: .tcp,
        detail: "The Finder browses for WebDAV servers but because of a bug (r. 3171023), double-clicking a discovered server fails to connect."
    )
    static private let fileTransferProtocol: BonjourServiceType = BonjourServiceType(
        name: "File Transfer Protocol (FTP)",
        type: "ftp",
        transportLayer: .tcp,
        detail: "Used by FTP Access in the Sharing preference panel starting in Mac OS X 10.2.2. The Finder browses for FTP servers starting in Mac OS X 10.3. The Terminal application also browses for FTP servers starting in Mac OS X 10.3."
    )
    static private let secureShell: BonjourServiceType = BonjourServiceType(
        name: "Secure Shell (SSH)",
        type: "ssh",
        transportLayer: .tcp,
        detail: "Used by Remote Login in the Sharing preference panel starting in Mac OS X 10.3. The Terminal application browses for SSH servers starting in Mac OS X 10.3."
    )
    static private let remoteAppleEvents: BonjourServiceType = BonjourServiceType(
        name: "Remote AppleEvents",
        type: "eppc",
        transportLayer: .tcp,
        detail: "Used by Remote AppleEvents in the Sharing preference panel starting in Mac OS X 10.2."
    )
    static private let http: BonjourServiceType = BonjourServiceType(
        name: "Hypertext Transfer Protocol (HTTP)",
        type: "http",
        transportLayer: .tcp,
        detail: "Used by Personal Web Sharing in the Sharing preference panel to advertise the User's Sites folders starting in Mac OS X 10.2.4. Safari can be used to browse for web servers."
    )
    static private let https: BonjourServiceType = BonjourServiceType(
        name: "Secure Sockets Layer (SSL, or HTTPS)",
        type: "https",
        transportLayer: .tcp,
        detail: "HTTPS (HTTP over TLS) for secure web communication. Used by web browsers, App Store, iCloud, FaceTime, and most Apple services requiring encrypted connections."
    )
    static private let remoteLogin: BonjourServiceType = BonjourServiceType(
        name: "Remote Login",
        type: "telnet",
        transportLayer: .tcp,
        detail: "If Telnet is enabled, xinetd will advertise it via Bonjour starting in Mac OS X 10.3. The Terminal application browses for Telnet servers starting in Mac OS X 10.3."
    )
    static private let linePrinterDaemon: BonjourServiceType = BonjourServiceType(
        name: "Line Printer Daemon (LPD/LPR)",
        type: "printer",
        transportLayer: .tcp,
        detail: "Print Center browses for LPR printers starting in Mac OS X 10.2. For more information on creating a Bonjour printer, please see the Bonjour Printing Specification."
    )
    static private let internetPrintingProtocol: BonjourServiceType = BonjourServiceType(
        name: "Internet Printing Protocol (IPP)",
        type: "ipp",
        transportLayer: .tcp,
        detail: "Print Center browses for IPP printers starting in Mac OS X 10.2. For more information on creating a Bonjour printer, please see the Bonjour Printing Specification."
    )
    static private let pdlDataStream: BonjourServiceType = BonjourServiceType(
        name: "PDL Data Stream (Port 9100)",
        type: "pdl-datastream",
        transportLayer: .tcp,
        detail: "Print Center browses for PDL Data Stream printers starting in Mac OS X 10.2. For more information on creating a Bonjour printer, please see the Bonjour Printing Specification."
    )
    static private let remoteIOUSBPrinterProtocol: BonjourServiceType = BonjourServiceType(
        name: "Remote I/O USB Printer Protocol",
        type: "riousbprint",
        transportLayer: .tcp,
        detail: "Used by the AirPort Extreme Base Station to share USB printers. Printer Setup Utility browses for AirPort Extreme shared USB printers which use the Remote I/O USB Printer Protocol starting in Mac OS X 10.3."
    )
    static private let digitalAudioAccessProtocol: BonjourServiceType = BonjourServiceType(
        name: "Digital Audio Access Protocol (DAAP)",
        type: "daap",
        transportLayer: .tcp,
        detail: "Also known as iTunes Music Sharing. iTunes advertises and browses for DAAP servers starting in iTunes 4.0."
    )
    static private let digitalPhotoAccessProtocol: BonjourServiceType = BonjourServiceType(
        name: "Digital Photo Access Protocol (DPAP)",
        type: "dpap",
        transportLayer: .tcp,
        detail: "Also known as iPhoto Photo Sharing. iPhoto advertises and browses for DPAP servers starting in iPhoto 4.0."
    )
    static private let iChatInstantMessagingProtocolDeprecated: BonjourServiceType = BonjourServiceType(
        name: "iChat Instant Messaging Protocol",
        type: "ichat",
        transportLayer: .tcp,
        detail: "Used by iChat 1.0 which shipped with Mac OS X 10.2. This service is now deprecated with the introduction of the \"presence\" service in iChat AV. See below."
    )
    static private let iChatInstantMessagingProtocol2: BonjourServiceType = BonjourServiceType(
        name: "iChat Instant Messaging Protocol",
        type: "presence",
        transportLayer: .tcp,
        detail: "Used by iChat AV which shipped with Mac OS X 10.3."
    )
    static private let imageCaptureSharing: BonjourServiceType = BonjourServiceType(
        name: "Image Capture Sharing",
        type: "ica-networking",
        transportLayer: .tcp,
        detail: "Used by the Image Capture application to share cameras in Mac OS X 10.3."
    )
    static private let airPortBaseStation: BonjourServiceType = BonjourServiceType(
        name: "AirPort Base Station",
        type: "airport",
        transportLayer: .tcp,
        detail: "Used by the AirPort Admin Utility starting in Mac OS X 10.2 in order to locate and configure the AirPort Base Station (Dual Ethernet) and the AirPort Extreme Base Station."
    )
    static private let xServeRAID: BonjourServiceType = BonjourServiceType(
        name: "Xserve RAID",
        type: "xserveraid",
        transportLayer: .tcp,
        detail: "Used by the Xserve RAID Admin Utility to locate and configure Xserve RAID hardware."
    )
    static private let distributedCompiler: BonjourServiceType = BonjourServiceType(
        name: "Distributed Compiler",
        type: "distcc",
        transportLayer: .tcp,
        detail: "Used by Xcode in its Distributed Builds feature."
    )
    static private let applePasswordServer: BonjourServiceType = BonjourServiceType(
        name: "Apple Password Server",
        type: "apple-sasl",
        transportLayer: .tcp,
        detail: "Used by Open Directory Password Server starting in Mac OS X Server 10.3."
    )
    static private let workgroupManager: BonjourServiceType = BonjourServiceType(
        name: "Workgroup Manager",
        type: "workstation",
        transportLayer: .tcp,
        detail: "Open Directory advertises this service starting in Mac OS X 10.2. Workgroup Manager browses for this service starting in Mac OS X Server 10.2."
    )
    static private let serverAdmin: BonjourServiceType = BonjourServiceType(
        name: "Server Admin",
        type: "servermgr",
        transportLayer: .tcp,
        detail: "Mac OS X Server machines advertise this service starting in Mac OS X 10.3. Server Admin browses for this service starting in Mac OS X Server 10.3."
    )
    static private let remoteAudioOutputProtocol: BonjourServiceType = BonjourServiceType(
        name: "Remote Audio Output Protocol (RAOP)",
        type: "raop",
        transportLayer: .tcp,
        detail: "Also known as AirTunes. The AirPort Express Base Station advertises this service. iTunes browses for this service starting in iTunes 4.6."
    )

    static private let smbFileSharing: BonjourServiceType = BonjourServiceType(
        name: "SMB/CIFS File Sharing",
        type: "smb",
        transportLayer: .tcp,
        detail: "Server Message Block (SMB) is the default file sharing protocol on macOS since OS X 10.9 Mavericks, replacing AFP. Also used by Windows and Linux/Samba for network file sharing."
    )
    static private let ippSecure: BonjourServiceType = BonjourServiceType(
        name: "Internet Printing Protocol Secure (IPPS)",
        type: "ipps",
        transportLayer: .tcp,
        detail: "IPP over HTTPS for secure network printing. Most modern network printers advertise this service alongside standard IPP."
    )
    static private let companionLink: BonjourServiceType = BonjourServiceType(
        name: "Apple Companion Link",
        type: "companion-link",
        transportLayer: .tcp,
        detail: "Used by Apple devices for Continuity features including Handoff, Universal Clipboard, and Auto Unlock between iPhone, iPad, Mac, and Apple Watch."
    )
    static private let remoteDesktopProtocol: BonjourServiceType = BonjourServiceType(
        name: "Remote Desktop Protocol (RDP)",
        type: "rdp",
        transportLayer: .tcp,
        detail: "Microsoft Remote Desktop Protocol for remote access to Windows desktops and servers."
    )
    static private let sftpSSH: BonjourServiceType = BonjourServiceType(
        name: "Secure File Transfer Protocol (SFTP)",
        type: "sftp-ssh",
        transportLayer: .tcp,
        detail: "SSH File Transfer Protocol for secure file transfers over an SSH connection."
    )
    static private let httpAlternate: BonjourServiceType = BonjourServiceType(
        name: "HTTP Alternate",
        type: "http-alt",
        transportLayer: .tcp,
        detail: "HTTP service running on an alternate port (commonly 8080). Used by many web applications, development servers, and IoT devices."
    )
    static private let networkScanner: BonjourServiceType = BonjourServiceType(
        name: "Network Scanner (eSCL)",
        type: "uscan",
        transportLayer: .tcp,
        detail: "eSCL (AirScan) scanner protocol for driverless network scanning. Supported by most modern network-attached scanners and multifunction printers."
    )
    static private let networkScannerSecure: BonjourServiceType = BonjourServiceType(
        name: "Network Scanner Secure (eSCL over HTTPS)",
        type: "uscans",
        transportLayer: .tcp,
        detail: "Secure eSCL (AirScan) scanner protocol over HTTPS for driverless network scanning."
    )
    static private let carPlayControl: BonjourServiceType = BonjourServiceType(
        name: "CarPlay Control",
        type: "carplay_ctrl",
        transportLayer: .tcp,
        detail: "Apple CarPlay control protocol for wireless CarPlay connections between iPhone and compatible vehicle head units."
    )
    static private let matterSmartHome: BonjourServiceType = BonjourServiceType(
        name: "Matter Smart Home",
        type: "matter",
        transportLayer: .tcp,
        detail: "Matter (formerly Project CHIP) is a unified smart home connectivity standard supported by Apple, Google, Amazon, and Samsung for interoperable IoT devices."
    )
    static private let sonosSpeaker: BonjourServiceType = BonjourServiceType(
        name: "Sonos Speaker",
        type: "sonos",
        transportLayer: .tcp,
        detail: "Sonos wireless speaker discovery and control protocol."
    )
    static private let remoteManagement: BonjourServiceType = BonjourServiceType(
        name: "Remote Management (ARD)",
        type: "net-assistant",
        transportLayer: .tcp,
        detail: "Apple Remote Desktop management service for remote control and administration of Mac computers."
    )
    static private let pictureTransferProtocol: BonjourServiceType = BonjourServiceType(
        name: "Picture Transfer Protocol (PTP)",
        type: "ptp",
        transportLayer: .tcp,
        detail: "Picture Transfer Protocol for transferring images from digital cameras and other imaging devices over a network."
    )
    static private let chromecast: BonjourServiceType = BonjourServiceType(
        name: "Chromecast",
        type: "googlezone",
        transportLayer: .tcp,
        detail: "Google Chromecast device discovery for setup and configuration."
    )
    static private let mqttProtocol: BonjourServiceType = BonjourServiceType(
        name: "MQTT Protocol",
        type: "mqtt",
        transportLayer: .tcp,
        detail: "Message Queuing Telemetry Transport (MQTT) is a lightweight messaging protocol widely used in IoT and home automation systems."
    )
    static private let appleContinuity: BonjourServiceType = BonjourServiceType(
        name: "Apple Continuity",
        type: "continuity",
        transportLayer: .tcp,
        detail: "Apple Continuity service for seamless transitions between Apple devices, including Handoff and Universal Control."
    )
    static private let smbWindowsSharing: BonjourServiceType = BonjourServiceType(
        name: "Microsoft Windows Network (SMB2)",
        type: "smb2",
        transportLayer: .tcp,
        detail: "SMB2/SMB3 file sharing protocol used by modern Windows systems for improved performance and security over the original SMB protocol."
    )
    static private let subversion: BonjourServiceType = BonjourServiceType(
        name: "Subversion (SVN)",
        type: "svn",
        transportLayer: .tcp,
        detail: "Apache Subversion version control system for tracking changes in files and directories."
    )
    static private let gitProtocol: BonjourServiceType = BonjourServiceType(
        name: "Git Version Control",
        type: "git",
        transportLayer: .tcp,
        detail: "Git protocol for distributed version control repository access."
    )
    static private let domainNameService: BonjourServiceType = BonjourServiceType(
        name: "Domain Name Service (DNS)",
        type: "domain",
        transportLayer: .tcp,
        detail: "Domain Name System service for resolving hostnames to IP addresses."
    )
    static private let xmppClient: BonjourServiceType = BonjourServiceType(
        name: "XMPP Client (Jabber)",
        type: "xmpp-client",
        transportLayer: .tcp,
        detail: "Extensible Messaging and Presence Protocol (XMPP) for instant messaging and presence information. Formerly known as Jabber."
    )
    static private let ldapDirectory: BonjourServiceType = BonjourServiceType(
        name: "LDAP Directory Service",
        type: "ldap",
        transportLayer: .tcp,
        detail: "Lightweight Directory Access Protocol for accessing and maintaining distributed directory information services over a network."
    )
    static private let postgreSQLDatabase: BonjourServiceType = BonjourServiceType(
        name: "PostgreSQL Database",
        type: "postgresql",
        transportLayer: .tcp,
        detail: "PostgreSQL relational database server. PostgreSQL supports Bonjour-based service discovery when configured with bonjour = on."
    )
    static private let mySQLDatabase: BonjourServiceType = BonjourServiceType(
        name: "MySQL Database",
        type: "mysql",
        transportLayer: .tcp,
        detail: "MySQL relational database server for network-accessible database services."
    )
    static private let homeAssistant: BonjourServiceType = BonjourServiceType(
        name: "Home Assistant",
        type: "home-assistant",
        transportLayer: .tcp,
        detail: "Home Assistant open-source home automation platform for local smart home control and monitoring."
    )
    static private let vncRemoteAccess: BonjourServiceType = BonjourServiceType(
        name: "Virtual Network Computing (VNC)",
        type: "vnc",
        transportLayer: .tcp,
        detail: "VNC remote desktop access protocol. An alternative service type to RFB, commonly advertised by VNC server implementations."
    )
    static private let prometheusMonitoring: BonjourServiceType = BonjourServiceType(
        name: "Prometheus Monitoring",
        type: "prometheus",
        transportLayer: .tcp,
        detail: "Prometheus systems monitoring and alerting toolkit for collecting and querying metrics from configured targets."
    )

    // MARK: - UDP Services

    public static var udpServiceTypes: [BonjourServiceType] {
        return [
            self.netBIOSNameService,
            self.netBIOSDatagramService,
            self.googleXpeditionsUdp,
            self.goProWake,
            self.goProWeb,
            self.airplayUdp,
            self.bonjourSleepProxy,
            self.netAssistant,
            self.ssdp,
            self.rtspUdp,
            self.mdnsServiceDiscovery,
            self.coapProtocol,
            self.threadBorderRouter,
            self.matterCommissionable,
            self.matterCommissioner,
            // MARK: Tier 1–3 UDP additions
            self.lifxLighting,
            self.kdeConnect,
            self.sipUdp,
            self.networkTimeProtocol,
            self.appleMobileDeviceProtocolV2Udp,
            self.snmpProtocol,
            self.kerberosUdp
        ]
    }

    static private let netBIOSNameService: BonjourServiceType = BonjourServiceType(
        name: "NetBIOS Name Service",
        type: "netbios-ns",
        transportLayer: .udp,
        detail: "NetBIOS Name Service for resolving NetBIOS names to IP addresses on local networks."
    )
    static private let netBIOSDatagramService: BonjourServiceType = BonjourServiceType(
        name: "NETBIOS Datagram Service",
        type: "netbios-dgm",
        transportLayer: .udp,
        detail: "NetBIOS Datagram Service for connectionless messaging between devices on local networks."
    )
    static private let googleXpeditionsUdp: BonjourServiceType = BonjourServiceType(
        name: "Google Expeditions",
        type: "googlexpeditions",
        transportLayer: .udp,
        detail: "Service related to Google Expeditions which is a technology for enabling multi-participant virtual fieldtrip experiences over a local wireless network. See http://g.co/expeditions for more details"
    )
    static private let goProWake: BonjourServiceType = BonjourServiceType(
        name: "GoPro Wake",
        type: "gopro-wake",
        transportLayer: .udp,
        detail: "GoPro proprietary protocol to wake devices"
    )
    static private let goProWeb: BonjourServiceType = BonjourServiceType(
        name: "GoPro Web",
        type: "gopro-web",
        transportLayer: .udp,
        detail: "GoPro proprietary web protocol for device configuration, firmware updates, and media management over the local network."
    )
    static private let airplayUdp: BonjourServiceType = BonjourServiceType(
        name: "Airplay",
        type: "airplay",
        transportLayer: .udp,
        detail: "Protocol for streaming audio / video content"
    )
    static private let bonjourSleepProxy: BonjourServiceType = BonjourServiceType(
        name: "Bonjour Sleep Proxy",
        type: "sleep-proxy",
        transportLayer: .udp,
        detail: "Apple's Bonjour Sleep Proxy service is an open source[1] component of zero configuration networking, designed to assist in reducing power consumption of networked electronic devices.[2] A device acting as a sleep proxy server will respond to Multicast DNS queries for another, compatible device which has gone into low power mode. The low-power-mode device remains asleep while the sleep proxy server responds to any Multicast DNS queries."
    )
    static private let netAssistant: BonjourServiceType = BonjourServiceType(
        name: "Net Assistant",
        type: "net-assistant",
        transportLayer: .udp,
        detail: "Apple Remote Desktop 2.0 or later"
    )
    static private let ssdp: BonjourServiceType = BonjourServiceType(
        name: "SSDP",
        type: "ssdp",
        transportLayer: .udp,
        detail: "Simple Service Discovery Protocol used by UPnP devices to announce and discover services on the local network."
    )
    static private let wifiCalling: BonjourServiceType = BonjourServiceType(
        name: "Wi-Fi Calling",
        type: "ssdp",
        transportLayer: .udp,
        detail: "Wi-Fi Calling service for making and receiving phone calls over a Wi-Fi network instead of cellular."
    )
    static private let rtspUdp: BonjourServiceType = BonjourServiceType(
        name: "Real Time Streaming Protocol (RTSP)",
        type: "rtsp",
        transportLayer: .udp,
        detail: "AirPlay, QuickTime Streaming Server (QTSS), streaming media players"
    )
    static private let mdnsServiceDiscovery: BonjourServiceType = BonjourServiceType(
        name: "DNS Service Discovery",
        type: "dns-sd",
        transportLayer: .udp,
        detail: "DNS-based Service Discovery (DNS-SD) is the meta-query protocol used to enumerate available Bonjour service types on the network."
    )
    static private let coapProtocol: BonjourServiceType = BonjourServiceType(
        name: "Constrained Application Protocol (CoAP)",
        type: "coap",
        transportLayer: .udp,
        detail: "CoAP is a lightweight protocol designed for constrained IoT devices and low-power networks, similar to HTTP but optimized for machine-to-machine communication."
    )
    static private let threadBorderRouter: BonjourServiceType = BonjourServiceType(
        name: "Thread Border Router",
        type: "meshcop",
        transportLayer: .udp,
        detail: "Thread Mesh Commissioning Protocol for Thread border routers such as Apple TV and HomePod. TXT records expose the Thread network name, channel, and PAN ID."
    )
    static private let matterCommissionable: BonjourServiceType = BonjourServiceType(
        name: "Matter Commissionable Device",
        type: "matterc",
        transportLayer: .udp,
        detail: "A Matter device in commissioning mode, actively advertising its availability for pairing and setup on the local network."
    )
    static private let matterCommissioner: BonjourServiceType = BonjourServiceType(
        name: "Matter Commissioner",
        type: "matterd",
        transportLayer: .udp,
        detail: "A Matter commissioner device capable of onboarding new Matter accessories onto the smart home network."
    )

    // MARK: - Tier 1 Additions — Media Servers

    static private let plexMediaServer: BonjourServiceType = BonjourServiceType(
        name: "Plex Media Server",
        type: "plex",
        transportLayer: .tcp,
        detail: "Plex Media Server, a self-hosted media library that streams movies, TV, music, and photos to clients on the local network and beyond. Plex also uses a separate UDP-based group discovery protocol on the LAN."
    )
    static private let jellyfinMediaServer: BonjourServiceType = BonjourServiceType(
        name: "Jellyfin Media Server",
        type: "jellyfin",
        transportLayer: .tcp,
        detail: "Jellyfin, an open-source media server for streaming personal video, music, and photo libraries to clients on the local network. The free, community-run alternative to Plex and Emby."
    )
    static private let kodiMediaCenter: BonjourServiceType = BonjourServiceType(
        name: "Kodi (XBMC) Media Center",
        type: "xbmc",
        transportLayer: .tcp,
        detail: "Kodi (formerly XBMC), an open-source media center for playing local and streamed media. Commonly seen on Raspberry Pi, Apple TV jailbreaks, and dedicated home-theater PCs."
    )
    static private let embyMediaServer: BonjourServiceType = BonjourServiceType(
        name: "Emby Media Server",
        type: "emby",
        transportLayer: .tcp,
        detail: "Emby Media Server, a personal media server for streaming videos, music, and live TV to apps on phones, TVs, and game consoles."
    )

    // MARK: - Tier 1 Additions — Smart Home & IoT

    static private let philipsHueBridge: BonjourServiceType = BonjourServiceType(
        name: "Philips Hue Bridge",
        type: "hue",
        transportLayer: .tcp,
        detail: "Philips Hue smart-lighting bridge, the hub that connects Philips Hue bulbs and accessories to the local Wi-Fi network and lets apps control them. Often the most-deployed smart-home hub in a household."
    )
    static private let ecobeeThermostat: BonjourServiceType = BonjourServiceType(
        name: "Ecobee Thermostat",
        type: "ecobee",
        transportLayer: .tcp,
        detail: "Ecobee smart thermostat, a connected HVAC controller that integrates with Apple Home, Amazon Alexa, and Google Home for remote temperature scheduling and energy monitoring."
    )
    static private let octoPrint: BonjourServiceType = BonjourServiceType(
        name: "OctoPrint",
        type: "octoprint",
        transportLayer: .tcp,
        detail: "OctoPrint, a web-based controller for desktop 3D printers — typically a Raspberry Pi running the OctoPrint server attached to the printer over USB. Lets the user start prints, monitor progress, and stream camera video."
    )
    static private let lifxLighting: BonjourServiceType = BonjourServiceType(
        name: "LIFX Smart Lighting",
        type: "lifx",
        transportLayer: .udp,
        detail: "LIFX smart bulbs, Wi-Fi-connected color-changing lights that announce themselves on the local network for control by the LIFX app and smart-home hubs."
    )
    static private let klipper3DPrinter: BonjourServiceType = BonjourServiceType(
        name: "Klipper 3D Printer",
        type: "klipper",
        transportLayer: .tcp,
        detail: "Klipper, a high-performance 3D-printer firmware that runs on a Raspberry Pi alongside the printer's microcontroller. Often paired with the Mainsail or Fluidd web UIs."
    )
    static private let tasmotaIoT: BonjourServiceType = BonjourServiceType(
        name: "Tasmota IoT Firmware",
        type: "tasmota",
        transportLayer: .tcp,
        detail: "Tasmota, an open-source firmware for ESP8266/ESP32-based smart-home devices (Sonoff, Shelly, etc.). Commonly used to flash off-the-shelf smart plugs, switches, and bulbs for local-only control."
    )

    // MARK: - Tier 1 Additions — Mail, Calendar, Contacts (RFC 6186 / RFC 6764)

    static private let calDAV: BonjourServiceType = BonjourServiceType(
        name: "CalDAV (Calendar)",
        type: "caldav",
        transportLayer: .tcp,
        detail: "CalDAV, the standard calendar-sharing protocol used by Apple Calendar, Fastmail, Nextcloud, and most other calendar services. Defined for service discovery in RFC 6764."
    )
    static private let calDAVSecure: BonjourServiceType = BonjourServiceType(
        name: "CalDAV over TLS",
        type: "caldavs",
        transportLayer: .tcp,
        detail: "CalDAV calendar sharing over TLS — the modern, encrypted variant of CalDAV. Mail-and-calendar clients prefer this when both endpoints are advertised."
    )
    static private let cardDAV: BonjourServiceType = BonjourServiceType(
        name: "CardDAV (Contacts)",
        type: "carddav",
        transportLayer: .tcp,
        detail: "CardDAV, the standard contacts-sharing protocol used by Apple Contacts, Fastmail, Nextcloud, and most other address-book services. Defined for service discovery in RFC 6764."
    )
    static private let cardDAVSecure: BonjourServiceType = BonjourServiceType(
        name: "CardDAV over TLS",
        type: "carddavs",
        transportLayer: .tcp,
        detail: "CardDAV contacts sharing over TLS — the modern, encrypted variant of CardDAV. Mail-and-calendar clients prefer this when both endpoints are advertised."
    )
    static private let imap: BonjourServiceType = BonjourServiceType(
        name: "IMAP (Mail)",
        type: "imap",
        transportLayer: .tcp,
        detail: "Internet Message Access Protocol — the standard mail-retrieval protocol that keeps the messages on the server. Defined for service discovery in RFC 6186."
    )
    static private let imapSecure: BonjourServiceType = BonjourServiceType(
        name: "IMAP over TLS",
        type: "imaps",
        transportLayer: .tcp,
        detail: "IMAP over TLS — the encrypted variant of IMAP. Mail clients (Apple Mail, Thunderbird, etc.) prefer this when discovered."
    )
    static private let smtp: BonjourServiceType = BonjourServiceType(
        name: "SMTP (Mail Send)",
        type: "smtp",
        transportLayer: .tcp,
        detail: "Simple Mail Transfer Protocol — used for sending outgoing mail. Mail clients typically use the `submission` variant for authenticated user-originated mail."
    )
    static private let smtpSecure: BonjourServiceType = BonjourServiceType(
        name: "SMTP over TLS",
        type: "smtps",
        transportLayer: .tcp,
        detail: "SMTP over TLS — the encrypted variant of SMTP for sending mail. Less common today than the `submission` flow, but still seen on some mail servers."
    )
    static private let smtpSubmission: BonjourServiceType = BonjourServiceType(
        name: "SMTP Submission",
        type: "submission",
        transportLayer: .tcp,
        detail: "SMTP Submission — the authenticated mail-submission protocol used by mail clients to send messages through their provider. Defined for service discovery in RFC 6186."
    )
    static private let pop3: BonjourServiceType = BonjourServiceType(
        name: "POP3 (Mail)",
        type: "pop3",
        transportLayer: .tcp,
        detail: "Post Office Protocol v3 — a legacy mail-retrieval protocol that downloads messages and (typically) deletes them from the server. Largely superseded by IMAP, but still defined in RFC 6186 for service discovery."
    )
    static private let pop3Secure: BonjourServiceType = BonjourServiceType(
        name: "POP3 over TLS",
        type: "pop3s",
        transportLayer: .tcp,
        detail: "POP3 over TLS — the encrypted variant of POP3 for retrieving mail."
    )

    // MARK: - Tier 1 Additions — Modern Dev & Cross-Platform Sharing

    static private let syncthing: BonjourServiceType = BonjourServiceType(
        name: "Syncthing",
        type: "syncthing",
        transportLayer: .tcp,
        detail: "Syncthing, an open-source peer-to-peer file-sync tool that mirrors folders between devices over the local network and the internet. Often used as a self-hosted alternative to Dropbox or iCloud Drive."
    )
    static private let warpinator: BonjourServiceType = BonjourServiceType(
        name: "Warpinator",
        type: "warpinator",
        transportLayer: .tcp,
        detail: "Warpinator, the cross-platform file-sharing tool from Linux Mint. Inspired by AirDrop and works between Linux, Windows, macOS, and Android over the local network."
    )
    static private let redisDatabase: BonjourServiceType = BonjourServiceType(
        name: "Redis Database",
        type: "redis",
        transportLayer: .tcp,
        detail: "Redis, an in-memory key-value data store widely used as a cache, message broker, and ephemeral database in modern application stacks."
    )
    static private let gRPC: BonjourServiceType = BonjourServiceType(
        name: "gRPC",
        type: "grpc",
        transportLayer: .tcp,
        detail: "gRPC, a modern remote-procedure-call framework built on HTTP/2. Microservices and developer tools occasionally advertise gRPC endpoints over Bonjour during local development."
    )
    static private let hashiCorpConsul: BonjourServiceType = BonjourServiceType(
        name: "HashiCorp Consul",
        type: "consul",
        transportLayer: .tcp,
        detail: "HashiCorp Consul, a service-mesh and service-discovery platform. Some Consul deployments register agent endpoints via mDNS so clients can find them without static configuration."
    )
    static private let appleMobileDeviceProtocolV3: BonjourServiceType = BonjourServiceType(
        name: "Apple Mobile Device v3",
        type: "apple-mobdev3",
        transportLayer: .tcp,
        detail: "Newer variant of Apple's iOS-device sync protocol seen on iOS 17+ devices. Used alongside the v1 (`_apple-mobdev._tcp`) and v2 (`_apple-mobdev2._tcp`) services for Wi-Fi sync with Finder/iTunes."
    )

    // MARK: - Tier 2 Additions

    static private let steamLink: BonjourServiceType = BonjourServiceType(
        name: "Steam Link / In-Home Streaming",
        type: "steam",
        transportLayer: .tcp,
        detail: "Valve's Steam in-home streaming service used by Steam Link clients (and the Steam app on phones, tablets, and Apple TV) to stream PC games over the LAN."
    )
    static private let minecraftLAN: BonjourServiceType = BonjourServiceType(
        name: "Minecraft LAN Game",
        type: "minecraft",
        transportLayer: .tcp,
        detail: "Minecraft LAN-game advertisement. When a player opens their world to LAN, the game broadcasts its presence so other Minecraft instances on the same network can join without typing an IP."
    )
    static private let sipTcp: BonjourServiceType = BonjourServiceType(
        name: "SIP (VoIP)",
        type: "sip",
        transportLayer: .tcp,
        detail: "Session Initiation Protocol — the signaling protocol that negotiates voice and video calls. Used by VoIP phones, Apple FaceTime audio fallbacks, and corporate calling systems."
    )
    static private let sipUdp: BonjourServiceType = BonjourServiceType(
        name: "SIP (VoIP)",
        type: "sip",
        transportLayer: .udp,
        detail: "Session Initiation Protocol over UDP — the original transport for SIP signaling, still widely used by VoIP phones and PBX systems on the local network."
    )
    static private let networkTimeProtocol: BonjourServiceType = BonjourServiceType(
        name: "Network Time Protocol (NTP)",
        type: "ntp",
        transportLayer: .udp,
        detail: "Network Time Protocol — used to keep clocks synchronized across networked devices. Some local NTP servers (router-based, AppleTV-based) advertise themselves over Bonjour."
    )
    static private let appleMobileDeviceProtocolV2Udp: BonjourServiceType = BonjourServiceType(
        name: "Apple Mobile Device v2 (UDP)",
        type: "apple-mobdev2",
        transportLayer: .udp,
        detail: "UDP companion to Apple's iOS Wi-Fi-sync protocol. Some iOS devices advertise both the TCP and UDP variants while pairing with macOS Finder."
    )
    static private let piHole: BonjourServiceType = BonjourServiceType(
        name: "Pi-hole DNS Sinkhole",
        type: "pi-hole",
        transportLayer: .tcp,
        detail: "Pi-hole, a network-level DNS-based ad blocker that runs on a Raspberry Pi or similar. Some installations advertise their admin endpoint via mDNS for easy discovery."
    )

    // MARK: - Tier 3 Additions — Encrypted DNS, Enterprise Auth, Linux Audio

    static private let dnsOverTls: BonjourServiceType = BonjourServiceType(
        name: "DNS over TLS",
        type: "dot",
        transportLayer: .tcp,
        detail: "DNS over TLS, an encrypted variant of DNS that protects queries from eavesdropping on the local network and ISP. Used by privacy-conscious resolvers and some home routers."
    )
    static private let dnsOverHttps: BonjourServiceType = BonjourServiceType(
        name: "DNS over HTTPS",
        type: "doh",
        transportLayer: .tcp,
        detail: "DNS over HTTPS, an encrypted DNS variant that wraps queries in HTTPS so they're indistinguishable from regular web traffic. Used by Apple Private Relay, Firefox, and some local resolvers."
    )
    static private let kerberosTcp: BonjourServiceType = BonjourServiceType(
        name: "Kerberos Authentication",
        type: "kerberos",
        transportLayer: .tcp,
        detail: "Kerberos, the network authentication protocol used by macOS, Active Directory, and many enterprise login systems. Defined in RFC 4120 with mDNS service discovery in RFC 4120/6763."
    )
    static private let kerberosUdp: BonjourServiceType = BonjourServiceType(
        name: "Kerberos Authentication",
        type: "kerberos",
        transportLayer: .udp,
        detail: "Kerberos authentication over UDP — the original Kerberos transport, still used by some KDCs alongside the TCP variant."
    )
    static private let snmpProtocol: BonjourServiceType = BonjourServiceType(
        name: "SNMP (Network Monitoring)",
        type: "snmp",
        transportLayer: .udp,
        detail: "Simple Network Management Protocol — the long-standing protocol for monitoring and configuring network devices like switches, printers, and UPSes. Most often seen in business networks."
    )
    static private let pulseAudioServer: BonjourServiceType = BonjourServiceType(
        name: "PulseAudio Server",
        type: "pulse-server",
        transportLayer: .tcp,
        detail: "PulseAudio, the Linux audio server. Some Linux systems advertise their PulseAudio server over Bonjour so other machines can route audio to or from them over the local network."
    )

    // MARK: - KDE Connect

    static private let kdeConnect: BonjourServiceType = BonjourServiceType(
        name: "KDE Connect",
        type: "kdeconnect",
        transportLayer: .udp,
        detail: "KDE Connect, the cross-platform pairing protocol that links phones (Android, iOS) with Linux/Windows/macOS desktops for shared clipboards, notification mirroring, and file transfer."
    )
}
