//
//  BonjourServiceType+Library.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 1/1/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation

extension BonjourServiceType {
    
    // MARK: - TCP Service Types
    
    /// For a full list of all registered services: http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml
    /// More at https://support.apple.com/en-us/HT202944
    static var tcpServiceTypes: [BonjourServiceType] {
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
            self.iChatInstantMessagingProtocol,
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
            self.osxWiFiSync,
            self.appleSharediTunesLibrary,
            self.sketchApp,
            self.sketchApp2,
            self.airplay2Undocumented,
            self.cloudByDapile,
            self.osxDeviceInfo,
            self.remoteAppleEvents,
            self.esFileShareApp, 
            self.esFileShareApp2,
            self.appleHomeKit,
            self.iTunesHomeSharing,
            self.jenkinsApp,
            self.jenkinsApp2,
            self.iChatInstantMessagingProtocol2,
            self.osxKeynote,
            self.osxKeynote2,
            self.appleTVMediaRemote,
            self.nVIDIAShieldGameStreaming,
            self.nvidiaShieldAndroidTV,
            self.omniGroupOmniGraffleAndOtherApps,
            self.adobePhotoshopNav,
            self.netgearReadyNAS,
            self.physicalWeb,
            self.scanners,
            self.ubuntuRaspberryPiAdvertisement
        ]
    }
    
    static private let timeCapsuleBackups: BonjourServiceType = BonjourServiceType(
        name: "Time Capsule Backups", 
        type: "adisk", 
        transportLayer: .tcp
    )
    static private let airDroidApp: BonjourServiceType = BonjourServiceType(
        name: "AirDroid App", 
        type: "airdroid", 
        transportLayer: .tcp
    )
    static private let amazonDevices: BonjourServiceType = BonjourServiceType(
        name: "Amazon Devices", 
        type: "amzn-wplay", 
        transportLayer: .tcp
    )
    static private let osxWiFiSync: BonjourServiceType = BonjourServiceType(
        name: "OSX Wi-Fi Sync", 
        type: "apple-mobdev2", 
        transportLayer: .tcp
    )
    static private let appleSharediTunesLibrary: BonjourServiceType = BonjourServiceType(
        name: "Apple Shared iTunes Library", 
        type: "atc", 
        transportLayer: .tcp
    )
    static private let sketchApp: BonjourServiceType = BonjourServiceType(
        name: "Sketch App", 
        type: "sketchmirror", 
        transportLayer: .tcp
    )
    static private let sketchApp2: BonjourServiceType = BonjourServiceType(
        name: "Sketch App", 
        type: "bcbonjour", 
        transportLayer: .tcp
    )
    static private let airplay2Undocumented: BonjourServiceType = BonjourServiceType(
        name: "AirPlay 2 Undocumented", 
        type: "cloud", 
        transportLayer: .tcp
    )
    static private let cloudByDapile: BonjourServiceType = BonjourServiceType(
        name: "Cloud by Dapile", 
        type: "amzn-wplay", 
        transportLayer: .tcp
    )
    static private let osxDeviceInfo: BonjourServiceType = BonjourServiceType(
        name: "OSX Device Info", 
        type: "device-info", 
        transportLayer: .tcp
    )
    static private let esFileShareApp: BonjourServiceType = BonjourServiceType(
        name: "ES File Share App", 
        type: "esdevice", 
        transportLayer: .tcp
    )
    static private let esFileShareApp2: BonjourServiceType = BonjourServiceType(
        name: "ES File Share App", 
        type: "esfileshare", 
        transportLayer: .tcp
    )
    static private let appleHomeKit: BonjourServiceType = BonjourServiceType(
        name: "Apple HomeKit", 
        type: "homekit", 
        transportLayer: .tcp
    )
    static private let iTunesHomeSharing: BonjourServiceType = BonjourServiceType(
        name: "iTunes Home Sharing", 
        type: "home-sharing", 
        transportLayer: .tcp
    )
    static private let jenkinsApp: BonjourServiceType = BonjourServiceType(
        name: "Jenkins App", 
        type: "hudson", 
        transportLayer: .tcp
    )
    static private let jenkinsApp2: BonjourServiceType = BonjourServiceType(
        name: "Jenkins App", 
        type: "jenkins", 
        transportLayer: .tcp
    )
    static private let iChatInstantMessagingProtocol: BonjourServiceType = BonjourServiceType(
        name: "iChat Instant Messaging Protocol", 
        type: "ichat", 
        transportLayer: .tcp
    )
    static private let osxKeynote: BonjourServiceType = BonjourServiceType(
        name: "OSX Keynote", 
        type: "KeynoteControl", 
        transportLayer: .tcp
    )
    static private let osxKeynote2: BonjourServiceType = BonjourServiceType(
        name: "OSX Keynote", 
        type: "keynotepair", 
        transportLayer: .tcp
    )
    static private let appleTVMediaRemote: BonjourServiceType = BonjourServiceType(
        name: "Apple TV Media Remote", 
        type: "mediaremotetv", 
        transportLayer: .tcp
    )
    static private let nVIDIAShieldGameStreaming: BonjourServiceType = BonjourServiceType(
        name: "NVIDIA Shield Game Streaming", 
        type: "nvstream", 
        transportLayer: .tcp
    )
    static private let nvidiaShieldAndroidTV: BonjourServiceType = BonjourServiceType(
        name: "Nvidia Shield / Android TV", 
        type: "androidtvremote", 
        transportLayer: .tcp
    )
    static private let omniGroupOmniGraffleAndOtherApps: BonjourServiceType = BonjourServiceType(
        name: "OmniGroup (OmniGraffle and other apps)", 
        type: "omnistate", 
        transportLayer: .tcp
    )
    static private let adobePhotoshopNav: BonjourServiceType = BonjourServiceType(
        name: "Adobe Photoshop Nav", 
        type: "photoshopserver", 
        transportLayer: .tcp
    )
    static private let netgearReadyNAS: BonjourServiceType = BonjourServiceType(
        name: "Netgear ReadyNAS", 
        type: "readynas", 
        transportLayer: .tcp
    )
    static private let physicalWeb: BonjourServiceType = BonjourServiceType(
        name: "Physical Web", 
        type: "physicalweb", 
        transportLayer: .tcp
    )
    static private let scanners: BonjourServiceType = BonjourServiceType(
        name: "Scanners", 
        type: "scanner", 
        transportLayer: .tcp
    )
    static private let ubuntuRaspberryPiAdvertisement: BonjourServiceType = BonjourServiceType(
        name: "Ubuntu / Raspberry Pi Advertisement", 
        type: "udisks-ssh", 
        transportLayer: .tcp
    )
    static private let powerViewHubV2: BonjourServiceType = BonjourServiceType(
        name: "PowerView Hub 2.0", 
        type: "powerview", 
        transportLayer: .tcp
    )
    static private let spotifyConnect: BonjourServiceType = BonjourServiceType(
        name: "Spotify Connect", 
        type: "spotify-connect", 
        transportLayer: .tcp
    )
    static private let netBIOSSessionService: BonjourServiceType = BonjourServiceType(
        name: "NetBIOS Session Service", 
        type: "netbios-ssn", 
        transportLayer: .tcp
    )
    static private let rokuControlProtocol: BonjourServiceType = BonjourServiceType(
        name: "ROKU Control Protocol", 
        type: "roku-rcp", 
        transportLayer: .tcp
    )
    static private let beatsTransferProtocol: BonjourServiceType = BonjourServiceType(
        name: "Beats Transfer Protocol", 
        type: "btp", 
        transportLayer: .tcp,
        detail: "Beats Transfer Protocol allows for the discovery and control of devices"
    )
    static private let androidTvRemote: BonjourServiceType = BonjourServiceType(
        name: "Android TV Remote", 
        type: "androidtvremote", 
        transportLayer: .tcp
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
        detail: "airdrop"
    )
    static private let appleMobileDeviceProtocol: BonjourServiceType = BonjourServiceType(
        name: "Apple Mobile Device Protocol", 
        type: "apple-mobdev", 
        transportLayer: .tcp
    )
    static private let appleMobileDeviceProtocolV2: BonjourServiceType = BonjourServiceType(
        name: "Apple Mobile Device Protocol V2", 
        type: "apple-mobdev2", 
        transportLayer: .tcp
    )
    static private let appleMIDI: BonjourServiceType = BonjourServiceType(
        name: "Apple MIDI", 
        type: "apple-midi", 
        transportLayer: .tcp
    )
    static private let appleRemoteDebugServices: BonjourServiceType = BonjourServiceType(
        name: "Apple Remote Debug Services (OpenGL Profiler)", 
        type: "applerdbg", 
        transportLayer: .tcp
    )
    static private let appleTV: BonjourServiceType = BonjourServiceType(
        name: "Apple TV", 
        type: "appletv", 
        transportLayer: .tcp
    )
    static private let appleTVv2: BonjourServiceType = BonjourServiceType(
        name: "Apple TV (2nd Generation)", 
        type: "appletv-v2", 
        transportLayer: .tcp
    )
    static private let appleTVv3: BonjourServiceType = BonjourServiceType(
        name: "Apple TV (3rd Generation)", 
        type: "appletv-v3", 
        transportLayer: .tcp
    )
    static private let appleTVv4: BonjourServiceType = BonjourServiceType(
        name: "Apple TV (4th Generation)", 
        type: "appletv-v4", 
        transportLayer: .tcp
    )
    static private let appleTViTunes: BonjourServiceType = BonjourServiceType(
        name: "Apple TV Discovery of iTunes", 
        type: "appletv-itunes", 
        transportLayer: .tcp
    )
    static private let appleTVPairing: BonjourServiceType = BonjourServiceType(
        name: "Apple TV Pairing", 
        type: "appletv-pair", 
        transportLayer: .tcp
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
        transportLayer: .tcp
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
        detail: "TLS websites, iTunes Store, Software Update (OS X Mountain Lion and later), Spotlight Suggestions, Mac App Store, Maps, FaceTime, Game Center, iCloud authentication and DAV Services (Contacts, Calendars, Bookmarks), iCloud backup and apps (Calendars, Contacts, Find My iPhone, Find My Friends, Mail,  Documents & Photo Stream, iCloud Key Value Store (KVS), iPhoto Journals, AirPlay, macOS Internet Recovery, Profile Manager, Back to My Mac, Dictation, Siri (iOS), Xcode Server (hosted and remote Git HTTPS, remote SVN HTTPS, Apple Developer registration)"
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
    
    // MARK: - UDP Services (Unused)
    
    static var udpServiceTypes: [BonjourServiceType] {
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
            self.wifiCalling,
            self.rtspUdp
        ]
    }
    
    static private let netBIOSNameService: BonjourServiceType = BonjourServiceType(
        name: "NetBIOS Name Service", 
        type: "netbios-ns", 
        transportLayer: .udp
    )
    static private let netBIOSDatagramService: BonjourServiceType = BonjourServiceType(
        name: "NETBIOS Datagram Service", 
        type: "netbios-dgm", 
        transportLayer:   .udp
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
        detail: "GoPro proprietary protocol for devices"
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
        transportLayer: .udp
    )
    static private let wifiCalling: BonjourServiceType = BonjourServiceType(
        name: "Wi-Fi Calling", 
        type: "ssdp", 
        transportLayer: .udp
    )
    static private let rtspUdp: BonjourServiceType = BonjourServiceType(
        name: "Real Time Streaming Protocol (RTSP)", 
        type: "rtsp", 
        transportLayer: .udp,
        detail: "AirPlay, QuickTime Streaming Server (QTSS), streaming media players"
    )
}
