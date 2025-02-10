import Foundation
@preconcurrency import MultipeerConnectivity
@preconcurrency import Combine

public final class Multipeer: Sendable {
    public static let defaultServiceName = "sacn" // add "_sacn._udp" to Info.plist
    public let serviceType: String
    public let peerID: MCPeerID
    public let session: MCSession
    public let advertiser: MCNearbyServiceAdvertiser
    public let browser: MCNearbyServiceBrowser
    public var receivedData: any Publisher<Data, Never> {sessionDelegate.receivedDataSubject.compactMap {$0}}

    private let sessionDelegate: SessionDelegate = .init()
    final class SessionDelegate: NSObject, MCSessionDelegate, Sendable {
        let receivedDataSubject: CurrentValueSubject<Data?, Never> = .init(nil)

        func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
            NSLog("%@", "\(#function): state = \(state)")
        }

        func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
            // NSLog("%@", "\(#function)")
            receivedDataSubject.send(data)
        }

        func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
            NSLog("%@", "\(#function)")
        }

        func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
            NSLog("%@", "\(#function)")
        }

        func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
            NSLog("%@", "\(#function)")
        }
    }

    private let advertiserDelegate: AdvertiserDelegate
    final class AdvertiserDelegate: NSObject, MCNearbyServiceAdvertiserDelegate, Sendable {
        let session: MCSession
        init(session: MCSession) {self.session = session}
        func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
            NSLog("%@", "\(#function): fromPeer = \(peerID)")
            invitationHandler(true, session) // TODO: more control, a away other than auto-connect
        }
    }

    private let browserDelegate: BrowserDelegate
    @MainActor final class BrowserDelegate: NSObject, @preconcurrency MCNearbyServiceBrowserDelegate {
        let session: MCSession
        init(session: MCSession) {self.session = session}
        func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
            NSLog("%@", "\(#function): foundPeer = \(peerID)")
            guard session.myPeerID.displayName < peerID.displayName else { return } // prioritize by same value for both peers
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)  // TODO: more control, a away other than auto-connect
        }
        func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
            NSLog("%@", "\(#function): lostPeer = \(peerID)")
        }
    }

    @MainActor public init(serviceType: String = defaultServiceName, displayName: String = ProcessInfo().hostName + " " + ProcessInfo().processName + " " + String(ProcessInfo().processIdentifier)) {
        self.serviceType = serviceType
        peerID = .init(displayName: String(displayName.prefix(63)))
        session = .init(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = sessionDelegate
        advertiser = .init(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiserDelegate = .init(session: session)
        advertiser.delegate = advertiserDelegate
        browser = .init(peer: peerID, serviceType: serviceType)
        browserDelegate = .init(session: session)
        browser.delegate = browserDelegate
    }

    public func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    public func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
}
