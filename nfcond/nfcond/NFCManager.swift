import UIKit
import CoreNFC

// MARK: - NFCManagerDelegate
protocol NFCManagerDelegate: AnyObject {
    /// 读取NFC数据成功
    /// - Parameters:
    ///   - manager: NFC管理器
    ///   - data: 读取到的数据
    func nfcManager(_ manager: NFCManager, didReadData data: String)
    
    /// 读取NFC数据失败
    /// - Parameters:
    ///   - manager: NFC管理器
    ///   - error: 失败原因
    func nfcManager(_ manager: NFCManager, didFailToReadDataWithError error: Error)
    
    /// 写入NFC数据成功
    /// - Parameter manager: NFC管理器
    func nfcManagerDidWriteDataSuccessfully(_ manager: NFCManager)
    
    /// 写入NFC数据失败
    /// - Parameters:
    ///   - manager: NFC管理器
    ///   - error: 失败原因
    func nfcManager(_ manager: NFCManager, didFailToWriteDataWithError error: Error)
    
    /// NFC操作取消
    /// - Parameter manager: NFC管理器
    func nfcManagerDidCancelOperation(_ manager: NFCManager)
}

// MARK: - NFCManager
class NFCManager: NSObject {
    // MARK: - Singleton
    static let shared = NFCManager()
    
    // MARK: - Properties
    weak var delegate: NFCManagerDelegate?
    
    private var nfcSession: NFCNDEFReaderSession?
    private var nfcTagSession: NFCTagReaderSession?
    private let testNDEFData = "Hello, NFC!"
    
    // MARK: - Private Initializer
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    /// 检查设备是否支持NFC
    /// - Returns: 是否支持NFC
    func isNFCAvailable() -> Bool {
        return NFCNDEFReaderSession.readingAvailable
    }
    
    /// 开始读取NFC数据
    func startReadingNFC() {
        guard isNFCAvailable() else {
            delegate?.nfcManager(self, didFailToReadDataWithError: NSError(domain: "NFCManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "当前设备不支持NFC功能"]))
            return
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "将NFC标签靠近设备"
        nfcSession?.begin()
    }
    
    /// 开始写入NFC数据
    func startWritingNFC() {
        guard isNFCAvailable() else {
            delegate?.nfcManager(self, didFailToWriteDataWithError: NSError(domain: "NFCManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "当前设备不支持NFC功能"]))
            return
        }
        
        nfcTagSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
        nfcTagSession?.alertMessage = "将NFC标签靠近设备以写入数据"
        nfcTagSession?.begin()
    }
    
    /// 取消NFC操作
    func cancelNFCOperation() {
        nfcSession?.invalidate()
        nfcTagSession?.invalidate()
        
        nfcSession = nil
        nfcTagSession = nil
        
        delegate?.nfcManagerDidCancelOperation(self)
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCManager: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        var detectedText = ""
        for message in messages {
            for record in message.records {
                // 确保是文本类型记录
                if record.typeNameFormat == .nfcWellKnown && record.type == Data([0x54]) { // "T"表示文本类型
                    // 解析文本记录
                    let textRecord = NFCNDEFPayload.wellKnownTypeTextPayload(from: record)
                    if let text = textRecord?.0 { 
                        detectedText += text + "\n"
                        print("检测到NDEF文本记录: \(text)")
                    } else {
                        detectedText += "无法解析文本\n"
                    }
                } else {
                    // 其他类型记录
                    let type = String(data: record.type, encoding: .utf8) ?? "未知类型"
                    detectedText += "非文本类型记录: \(type)\n"
                    print("检测到NDEF记录: \(type)")
                }
            }
        }
        
        DispatchQueue.main.async {
            let message = detectedText.isEmpty ? "未检测到可识别的文本记录" : detectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            self.delegate?.nfcManager(self, didReadData: message)
            session.invalidate()
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as! NFCReaderError
        if nfcError.code != .readerSessionInvalidationErrorFirstNDEFTagRead && nfcError.code != .readerSessionInvalidationErrorUserCanceled {
            DispatchQueue.main.async {
                self.delegate?.nfcManager(self, didFailToReadDataWithError: error)
            }
        } else if nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            DispatchQueue.main.async {
                self.delegate?.nfcManagerDidCancelOperation(self)
            }
        }
        
        nfcSession = nil
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension NFCManager: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Session became active
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "未检测到标签")
            return
        }
        
        // 处理不同类型的NFC标签
        guard let ndefTag = tag as? NFCNDEFTag else {
            session.invalidate(errorMessage: "不支持的标签类型")
            return
        }
        
        // 连接到NDEF标签并执行写入操作
        session.connect(to: tag) { [weak self] error in
            if let error = error {
                session.invalidate(errorMessage: "连接失败：\(error.localizedDescription)")
                return
            }
            self?.writeNDEFData(to: ndefTag, in: session)
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as! NFCReaderError
        if nfcError.code != .readerSessionInvalidationErrorUserCanceled {
            DispatchQueue.main.async {
                self.delegate?.nfcManager(self, didFailToWriteDataWithError: error)
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.nfcManagerDidCancelOperation(self)
            }
        }
        nfcTagSession = nil
    }
    
    private func writeNDEFData(to tag: NFCNDEFTag, in session: NFCTagReaderSession) {
        // 创建NDEF记录
        guard let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(string: testNDEFData, locale: Locale.current) else {
            session.invalidate(errorMessage: "无法创建NDEF文本记录")
            return
        }
        
        let ndefMessage = NFCNDEFMessage(records: [textPayload])
        
        tag.writeNDEF(ndefMessage) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                session.invalidate(errorMessage: "写入失败: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self.delegate?.nfcManagerDidWriteDataSuccessfully(self)
            }
            
            session.invalidate()
        }
    }
}