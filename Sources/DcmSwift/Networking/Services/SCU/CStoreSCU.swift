//
//  File.swift
//
//
//  Created by Rafael Warnault, OPALE on 23/07/2021.
//

import Foundation
import NIO

public class CStoreSCU: ServiceClassUser {
    var filePaths:[String] = []


    public init(_ filePaths:[String]) {
        self.filePaths = filePaths
    }


    public override var commandField:CommandField {
        .C_STORE_RQ
    }


    public override var abstractSyntaxes:[String] {
        DicomConstants.storageSOPClasses
    }


    /// Sequentially writes every file in `filePaths` to the association.
    ///
    /// The previous implementation discarded every intermediate write's
    /// future with `_ = association.write(...)` and only returned the
    /// last one. In debug-mode builds NIO's `EventLoopFuture.deinit`
    /// asserts when a future is deallocated before its associated
    /// promise is completed — which trips on real-device C-STORE runs
    /// inside `BaseStreamSocketChannel.readFromSocket` →
    /// `CStoreSCU.request`.
    ///
    /// Chain all writes through `flatMap` instead, so no in-flight
    /// promise's future ever gets dropped, and the returned future
    /// resolves only after the **last** write completes.
    public override func request(association:DicomAssociation, channel:Channel) -> EventLoopFuture<Void> {
        guard !filePaths.isEmpty else {
            return channel.eventLoop.makeSucceededVoidFuture()
        }

        var chain: EventLoopFuture<Void> = channel.eventLoop.makeSucceededVoidFuture()
        for fp in filePaths {
            guard let message = PDUEncoder.createDIMSEMessage(
                pduType: .dataTF,
                commandField: self.commandField,
                association: association
            ) as? CStoreRQ else { continue }

            message.dicomFile = DicomFile(forPath: fp)

            // Capture in a local so the closure doesn't capture the
            // enclosing loop variable.
            let messageRef = message
            chain = chain.flatMap { _ in
                let p = channel.eventLoop.makePromise(of: Void.self)
                return association.write(message: messageRef, promise: p)
            }
        }

        return chain
    }
}
