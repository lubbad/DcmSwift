//
//  EchoRSP.swift
//  DcmSwift
//
//  Created by Rafael Warnault, OPALE on 03/05/2019.
//  Copyright © 2019 OPALE. All rights reserved.
//

import Foundation

/**
 The `CEchoRSP` class represents a C-ECHO-RSP message of the DICOM standard.
 
 It inherits most of its behavior from `DataTF` and `PDUMessage` and their
 related protocols (`PDUResponsable`, `PDUDecodable`, `PDUEncodable`).
 
 http://dicom.nema.org/medical/dicom/current/output/chtml/part07/sect_9.3.5.2.html
 */
public class CEchoRSP: DataTF {
    public override func messageName() -> String {
        return "C-ECHO-RSP"
    }
    
    
    public override func messageInfos() -> String {
        // `dimseStatus` is declared as `DIMSEStatus!` on the base class
        // and is populated by `DataTF.decodeData`. The association's log
        // path calls `messageInfos()` for every inbound message — at
        // points where `decodeData` hasn't finished yet (or finished
        // unsuccessfully and left `dimseStatus` nil) the original
        // `"\(dimseStatus.status)"` form crashed the NIO event-loop
        // thread with an implicit-unwrap trap. Guard it.
        guard let status = dimseStatus?.status else { return "" }
        return "\(status)"
    }
    
    
    public override func data() -> Data? {
        if let pc = self.association.acceptedPresentationContexts.values.first,
           let transferSyntax = TransferSyntax(TransferSyntax.implicitVRLittleEndian) {
            let commandDataset = DataSet()
            _ = commandDataset.set(value: CommandField.C_ECHO_RSP.rawValue.bigEndian, forTagName: "CommandField")
            _ = commandDataset.set(value: pc.abstractSyntax as Any, forTagName: "AffectedSOPClassUID")
            
            if let request = self.requestMessage {
                _ = commandDataset.set(value: request.messageID, forTagName: "MessageIDBeingRespondedTo")
            }
            _ = commandDataset.set(value: UInt16(257).bigEndian, forTagName: "CommandDataSetType")
            _ = commandDataset.set(value: UInt16(0).bigEndian, forTagName: "Status")
            
            let pduData = PDUData(
                pduType: self.pduType,
                commandDataset: commandDataset,
                abstractSyntax: pc.abstractSyntax,
                transferSyntax: transferSyntax,
                pcID: pc.contextID, flags: 0x03)
            
            return pduData.data()
        }
        
        return nil
    }
    

    public override func decodeData(data: Data) -> DIMSEStatus.Status {
        let status = super.decodeData(data: data)
        
        return status
    }
}

