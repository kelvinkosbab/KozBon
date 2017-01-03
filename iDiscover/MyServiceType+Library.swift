//
//  MyServiceType+Library.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 1/1/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation

extension MyServiceType {
  
  // For a full list of all registered services: http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml
  // More at https://support.apple.com/en-us/HT202944
  
  // MARK: - TCP Service Types
  
  static var tcpServiceTypes: [MyServiceType] {
    return [ self.powerViewHubV2, self.spotifyConnect, self.netBIOSSessionService, self.rokuControlProtocol, self.beatsTransferProtocol, self.androidTvRemote, self.googleXpeditionsTcp, self.googleCast, self.mediaRemoteTv, self.airplayTcp, self.airdrop, self.appleMobileDeviceProtocol, self.appleMobileDeviceProtocolV2, self.appleMIDI, self.appleRemoteDebugServices, self.appleTV, self.appleTVv2, self.appleTVv3, self.appleTVv4, self.appleTViTunes, self.appleTVPairing, self.keynoteAccess, self.keynotePairing, self.homeKitAccessoryProtocol, self.appleTalkFilingProtocol, self.networkFileSystem, self.webDAVFileSystem, self.fileTransferProtocol, self.secureShell, self.remoteAppleEvents, self.http, self.https, self.remoteLogin, self.linePrinterDaemon, self.internetPrintingProtocol, self.pdlDataStream, self.remoteIOUSBPrinterProtocol, self.digitalAudioAccessProtocol, self.digitalPhotoAccessProtocol, self.iChatInstantMessagingProtocolDeprecated, self.iChatInstantMessagingProtocol, self.imageCaptureSharing, self.airPortBaseStation, self.xServeRAID, self.distributedCompiler, self.applePasswordServer, self.workgroupManager, self.serverAdmin, self.remoteAudioOutputProtocol, self.touchAble, self.remoteFrameBuffer, self.rtspTcp ]
  }
  
  static private let powerViewHubV2: MyServiceType = MyServiceType(name: "PowerView Hub 2.0", type: "powerview")
  
  static private let spotifyConnect: MyServiceType = MyServiceType(name: "Spotify Connect", type: "spotify-connect")
  static private let netBIOSSessionService: MyServiceType = MyServiceType(name: "NetBIOS Session Service", type: "netbios-ssn")
  static private let rokuControlProtocol: MyServiceType = MyServiceType(name: "ROKU Control Protocol", type: "roku-rcp")
  static private let beatsTransferProtocol: MyServiceType = MyServiceType(name: "Beats Transfer Protocol", type: "btp", detail: "Beats Transfer Protocol allows for the discovery and control of devices")
  static private let androidTvRemote: MyServiceType = MyServiceType(name: "Android TV Remote", type: "androidtvremote")
  static private let googleXpeditionsTcp: MyServiceType = MyServiceType(name: "Google Expeditions", type: "googlexpeditions", detail: "Service related to Google Expeditions which is a technology for enabling multi-participant virtual fieldtrip experiences over a local wireless network. See http://g.co/expeditions for more details")
  static private let googleCast: MyServiceType = MyServiceType(name: "Google Cast", type: "googlecast", detail: "Service related to Google Cast which is a technology for enabling multi-screen experiences. See developers.google.com/cast for more details")
  static private let mediaRemoteTv: MyServiceType = MyServiceType(name: "MediaRemoteTV", type: "mediaremotetv", detail: "MediaRemoteTV is a TCP based protocol which uses length prefixed protobuf encoded messages to communicate between the client and server. The Apple TV acts as the server and clients can connect to it in order to issue various commands (playback, keyboard, voice, game controller, etc). All messages are encrypted after negotiating the pairing between the client and the Apple TV. For more information visit https://github.com/jeanregisser/mediaremotetv-protocol/tree/master/communication.")
  static private let airplayTcp: MyServiceType = MyServiceType(name: "Airplay", type: "airplay", detail: "Protocol for streaming audio / video content")
  static private let airdrop: MyServiceType = MyServiceType(name: "Airdrop", type: "airdrop", detail: "airdrop")
  static private let appleMobileDeviceProtocol: MyServiceType = MyServiceType(name: "Apple Mobile Device Protocol", type: "apple-mobdev")
  static private let appleMobileDeviceProtocolV2: MyServiceType = MyServiceType(name: "Apple Mobile Device Protocol V2", type: "apple-mobdev2")
  static private let appleMIDI: MyServiceType = MyServiceType(name: "Apple MIDI", type: "apple-midi")
  static private let appleRemoteDebugServices: MyServiceType = MyServiceType(name: "Apple Remote Debug Services (OpenGL Profiler)", type: "applerdbg")
  static private let appleTV: MyServiceType = MyServiceType(name: "Apple TV", type: "appletv")
  static private let appleTVv2: MyServiceType = MyServiceType(name: "Apple TV (2nd Generation)", type: "appletv-v2")
  static private let appleTVv3: MyServiceType = MyServiceType(name: "Apple TV (3rd Generation)", type: "appletv-v3")
  static private let appleTVv4: MyServiceType = MyServiceType(name: "Apple TV (4th Generation)", type: "appletv-v4")
  static private let appleTViTunes: MyServiceType = MyServiceType(name: "Apple TV Discovery of iTunes", type: "appletv-itunes")
  static private let appleTVPairing: MyServiceType = MyServiceType(name: "Apple TV Pairing", type: "appletv-pair")
  static private let keynoteAccess: MyServiceType = MyServiceType(name: "KeynoteAccess", type: "keynoteaccess", detail: "KeynoteAccess is used for sending remote requests/responses when controlling a slideshow with Keynote Remote")
  static private let keynotePairing: MyServiceType = MyServiceType(name: "KeynotePairing", type: "keynotepairing", detail: "KeynotePairing is used to pair Keynote Remote with Keynote")
  static private let homeKitAccessoryProtocol: MyServiceType = MyServiceType(name: "HomeKit Accessory Protocol (HAP)", type: "hap", detail: "HomeKit speaks HomeKit Accessory Protocol (HAP), which runs on top of a BLE/Bluetooth Smart or an HTTP/TCP/IP stack.  If an accessory does not support HAP directly a gateway is needed.")
  static private let touchAble: MyServiceType = MyServiceType(name: "Touchable", type: "touch-able")
  static private let remoteFrameBuffer: MyServiceType = MyServiceType(name: "Remote Frame Buffer", type: "rfb", detail: "RFB (remote framebuffer) is a simple protocol for remote access to graphical user interfaces. Because it works at the framebuffer level it is applicable to all windowing systems and applications, including Microsoft Windows, macOS and the X Window System. RFB is the protocol used in Virtual Network Computing (VNC) and its derivatives.")
  static private let rtspTcp: MyServiceType = MyServiceType(name: "Real Time Streaming Protocol (RTSP)", type: "rtsp", detail: "AirPlay, QuickTime Streaming Server (QTSS), streaming media players")
  static private let appleTalkFilingProtocol: MyServiceType = MyServiceType(name: "AppleTalk Filing Protocol (AFP)", type: "afpovertcp", detail: "Used by Personal File Sharing in the Sharing preference panel starting in Mac OS X 10.2. The Finder browses for AFP servers starting in Mac OS X 10.2.")
  static private let networkFileSystem: MyServiceType = MyServiceType(name: "Network File System (NFS)", type: "nfs", detail: "The Finder browses for NFS servers starting in Mac OS X 10.2.")
  static private let webDAVFileSystem: MyServiceType = MyServiceType(name: "WebDAV File System (WEBDAV)", type: "webdav", detail: "The Finder browses for WebDAV servers but because of a bug (r. 3171023), double-clicking a discovered server fails to connect.")
  static private let fileTransferProtocol: MyServiceType = MyServiceType(name: "File Transfer Protocol (FTP)", type: "ftp", detail: "Used by FTP Access in the Sharing preference panel starting in Mac OS X 10.2.2. The Finder browses for FTP servers starting in Mac OS X 10.3. The Terminal application also browses for FTP servers starting in Mac OS X 10.3.")
  static private let secureShell: MyServiceType = MyServiceType(name: "Secure Shell (SSH)", type: "ssh", detail: "Used by Remote Login in the Sharing preference panel starting in Mac OS X 10.3. The Terminal application browses for SSH servers starting in Mac OS X 10.3.")
  static private let remoteAppleEvents: MyServiceType = MyServiceType(name: "Remote AppleEvents", type: "eppc", detail: "Used by Remote AppleEvents in the Sharing preference panel starting in Mac OS X 10.2.")
  static private let http: MyServiceType = MyServiceType(name: "Hypertext Transfer Protocol (HTTP)", type: "http", detail: "Used by Personal Web Sharing in the Sharing preference panel to advertise the User's Sites folders starting in Mac OS X 10.2.4. Safari can be used to browse for web servers.")
  static private let https: MyServiceType = MyServiceType(name: "Secure Sockets Layer (SSL, or HTTPS)", type: "https", detail: "TLS websites, iTunes Store, Software Update (OS X Mountain Lion and later), Spotlight Suggestions, Mac App Store, Maps, FaceTime, Game Center, iCloud authentication and DAV Services (Contacts, Calendars, Bookmarks), iCloud backup and apps (Calendars, Contacts, Find My iPhone, Find My Friends, Mail,  Documents & Photo Stream, iCloud Key Value Store (KVS), iPhoto Journals, AirPlay, macOS Internet Recovery, Profile Manager, Back to My Mac, Dictation, Siri (iOS), Xcode Server (hosted and remote Git HTTPS, remote SVN HTTPS, Apple Developer registration)")
  static private let remoteLogin: MyServiceType = MyServiceType(name: "Remote Login", type: "telnet", detail: "If Telnet is enabled, xinetd will advertise it via Bonjour starting in Mac OS X 10.3. The Terminal application browses for Telnet servers starting in Mac OS X 10.3.")
  static private let linePrinterDaemon: MyServiceType = MyServiceType(name: "Line Printer Daemon (LPD/LPR)", type: "printer", detail: "Print Center browses for LPR printers starting in Mac OS X 10.2. For more information on creating a Bonjour printer, please see the Bonjour Printing Specification.")
  static private let internetPrintingProtocol: MyServiceType = MyServiceType(name: "Internet Printing Protocol (IPP)", type: "ipp", detail: "Print Center browses for IPP printers starting in Mac OS X 10.2. For more information on creating a Bonjour printer, please see the Bonjour Printing Specification.")
  static private let pdlDataStream: MyServiceType = MyServiceType(name: "PDL Data Stream (Port 9100)", type: "pdl-datastream", detail: "Print Center browses for PDL Data Stream printers starting in Mac OS X 10.2. For more information on creating a Bonjour printer, please see the Bonjour Printing Specification.")
  static private let remoteIOUSBPrinterProtocol: MyServiceType = MyServiceType(name: "Remote I/O USB Printer Protocol", type: "riousbprint", detail: "Used by the AirPort Extreme Base Station to share USB printers. Printer Setup Utility browses for AirPort Extreme shared USB printers which use the Remote I/O USB Printer Protocol starting in Mac OS X 10.3.")
  static private let digitalAudioAccessProtocol: MyServiceType = MyServiceType(name: "Digital Audio Access Protocol (DAAP)", type: "daap", detail: "Also known as iTunes Music Sharing. iTunes advertises and browses for DAAP servers starting in iTunes 4.0.")
  static private let digitalPhotoAccessProtocol: MyServiceType = MyServiceType(name: "Digital Photo Access Protocol (DPAP)", type: "dpap", detail: "Also known as iPhoto Photo Sharing. iPhoto advertises and browses for DPAP servers starting in iPhoto 4.0.")
  static private let iChatInstantMessagingProtocolDeprecated: MyServiceType = MyServiceType(name: "iChat Instant Messaging Protocol", type: "ichat", detail: "Used by iChat 1.0 which shipped with Mac OS X 10.2. This service is now deprecated with the introduction of the \"presence\" service in iChat AV. See below.")
  static private let iChatInstantMessagingProtocol: MyServiceType = MyServiceType(name: "iChat Instant Messaging Protocol", type: "presence", detail: "Used by iChat AV which shipped with Mac OS X 10.3.")
  static private let imageCaptureSharing: MyServiceType = MyServiceType(name: "Image Capture Sharing", type: "ica-networking", detail: "Used by the Image Capture application to share cameras in Mac OS X 10.3.")
  static private let airPortBaseStation: MyServiceType = MyServiceType(name: "AirPort Base Station", type: "airport", detail: "Used by the AirPort Admin Utility starting in Mac OS X 10.2 in order to locate and configure the AirPort Base Station (Dual Ethernet) and the AirPort Extreme Base Station.")
  static private let xServeRAID: MyServiceType = MyServiceType(name: "Xserve RAID", type: "xserveraid", detail: "Used by the Xserve RAID Admin Utility to locate and configure Xserve RAID hardware.")
  static private let distributedCompiler: MyServiceType = MyServiceType(name: "Distributed Compiler", type: "distcc", detail: "Used by Xcode in its Distributed Builds feature.")
  static private let applePasswordServer: MyServiceType = MyServiceType(name: "Apple Password Server", type: "apple-sasl", detail: "Used by Open Directory Password Server starting in Mac OS X Server 10.3.")
  static private let workgroupManager: MyServiceType = MyServiceType(name: "Workgroup Manager", type: "workstation", detail: "Open Directory advertises this service starting in Mac OS X 10.2. Workgroup Manager browses for this service starting in Mac OS X Server 10.2.")
  static private let serverAdmin: MyServiceType = MyServiceType(name: "Server Admin", type: "servermgr", detail: "Mac OS X Server machines advertise this service starting in Mac OS X 10.3. Server Admin browses for this service starting in Mac OS X Server 10.3.")
  static private let remoteAudioOutputProtocol: MyServiceType = MyServiceType(name: "Remote Audio Output Protocol (RAOP)", type: "raop", detail: "Also known as AirTunes. The AirPort Express Base Station advertises this service. iTunes browses for this service starting in iTunes 4.6.")
  
  // MARK: - UDP Services (Unused)
  
  static var udpServiceTypes: [MyServiceType] {
    return [ self.netBIOSNameService, self.netBIOSDatagramService, self.googleXpeditionsUdp, self.goProWake, self.goProWeb, self.airplayUdp, self.bonjourSleepProxy, self.netAssistant, self.ssdp, self.wifiCalling, self.rtspUdp ]
  }
  
  static private let netBIOSNameService: MyServiceType = MyServiceType(name: "NetBIOS Name Service", type: "netbios-ns", transportLayer: .udp)
  static private let netBIOSDatagramService: MyServiceType = MyServiceType(name: "NETBIOS Datagram Service", type: "netbios-dgm", transportLayer: .udp)
  static private let googleXpeditionsUdp: MyServiceType = MyServiceType(name: "Google Expeditions", type: "googlexpeditions", transportLayer: .udp, detail: "Service related to Google Expeditions which is a technology for enabling multi-participant virtual fieldtrip experiences over a local wireless network. See http://g.co/expeditions for more details")
  static private let goProWake: MyServiceType = MyServiceType(name: "GoPro Wake", type: "gopro-wake", transportLayer: .udp, detail: "GoPro proprietary protocol to wake devices")
  static private let goProWeb: MyServiceType = MyServiceType(name: "GoPro Web", type: "gopro-web", transportLayer: .udp, detail: "GoPro proprietary protocol for devices")
  static private let airplayUdp: MyServiceType = MyServiceType(name: "Airplay", type: "airplay", transportLayer: .udp, detail: "Protocol for streaming audio / video content")
  static private let bonjourSleepProxy: MyServiceType = MyServiceType(name: "Bonjour Sleep Proxy", type: "sleep-proxy", transportLayer: .udp, detail: "Apple's Bonjour Sleep Proxy service is an open source[1] component of zero configuration networking, designed to assist in reducing power consumption of networked electronic devices.[2] A device acting as a sleep proxy server will respond to Multicast DNS queries for another, compatible device which has gone into low power mode. The low-power-mode device remains asleep while the sleep proxy server responds to any Multicast DNS queries.")
  static private let netAssistant: MyServiceType = MyServiceType(name: "Net Assistant", type: "net-assistant", transportLayer: .udp, detail: "Apple Remote Desktop 2.0 or later")
  static private let ssdp: MyServiceType = MyServiceType(name: "SSDP", type: "ssdp", transportLayer: .udp)
  static private let wifiCalling: MyServiceType = MyServiceType(name: "Wi-Fi Calling", type: "ssdp", transportLayer: .udp)
  static private let rtspUdp: MyServiceType = MyServiceType(name: "Real Time Streaming Protocol (RTSP)", type: "rtsp", transportLayer: .udp, detail: "AirPlay, QuickTime Streaming Server (QTSS), streaming media players")
}
