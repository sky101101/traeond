//
//  HomeViewController.swift
//  nfcond
//
//  Created by zhouziyu on 2025/11/12.
//

import UIKit
import SnapKit

class HomeViewController: UIViewController, NFCNDEFReaderSessionDelegate, NFCTagReaderSessionDelegate {
    // MARK: - NFC Properties
    private var nfcSession: NFCNDEFReaderSession?
    private var nfcTagSession: NFCTagReaderSession?
    private let testNDEFData = "Hello, NFC!"
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0).cgColor, // 浅蓝色
            UIColor(red: 0.95, green: 0.85, blue: 0.95, alpha: 1.0).cgColor // 浅紫色
        ]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "NFC 助手"
        label.font = UIFont.boldSystemFont(ofSize: 36)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "智能NFC读写管理工具"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
        label.alpha = 0.9
        return label
    }()
    
    private let cardsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let topRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let middleRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let bottomRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCards()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(cardsStackView)
        
        cardsStackView.addArrangedSubview(topRowStackView)
        cardsStackView.addArrangedSubview(middleRowStackView)
        cardsStackView.addArrangedSubview(bottomRowStackView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(100)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        cardsStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(50)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        [topRowStackView, middleRowStackView, bottomRowStackView].forEach { stackView in
            stackView.snp.makeConstraints { make in
                make.height.equalTo(120)
            }
        }
    }
    
    private func setupCards() {
        // 读取数据 - 绿色（信号图标）
        let readCard = createCard(
            icon: "antenna.radiowaves.left.and.right",
            title: "读取数据",
            color: UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
        ) { [weak self] in
            self?.handleReadData()
        }
        
        // 写入数据 - 蓝色（笔图标）
        let writeCard = createCard(
            icon: "square.and.pencil",
            title: "写入数据",
            color: UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)
        ) { [weak self] in
            self?.handleWriteData()
        }
        
        // 删除 - 红色（垃圾桶图标）
        let deleteCard = createCard(
            icon: "trash.fill",
            title: "删除",
            color: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        ) { [weak self] in
            self?.handleDelete()
        }
        
 
        let passwordCard = createCard(
            icon: "lock.fill",
            title: "密码设置",
            color: UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        ) { [weak self] in
            self?.handlePasswordSettings()
        }
        
        // 空白卡片
        let emptyCard = UIView()
        emptyCard.backgroundColor = .white
        emptyCard.layer.cornerRadius = 16
        emptyCard.layer.shadowColor = UIColor.black.cgColor
        emptyCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        emptyCard.layer.shadowOpacity = 0.1
        emptyCard.layer.shadowRadius = 8
        

        let lockCard = createCard(
            icon: "lock.open.fill",
            title: "锁定",
            color: UIColor(red: 0.7, green: 0.3, blue: 0.9, alpha: 1.0)
        ) { [weak self] in
            self?.handleLock()
        }
        
        topRowStackView.addArrangedSubview(readCard)
        topRowStackView.addArrangedSubview(writeCard)
        
        middleRowStackView.addArrangedSubview(deleteCard)
        middleRowStackView.addArrangedSubview(passwordCard)
        
        bottomRowStackView.addArrangedSubview(emptyCard)
        bottomRowStackView.addArrangedSubview(lockCard)
    }
    
    private func createCard(icon: String, title: String, color: UIColor, action: @escaping () -> Void) -> UIView {
        let containerView = UIView()
        
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 8
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = color
        iconImageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        titleLabel.textAlignment = .center
        
        containerView.addSubview(cardView)
        cardView.addSubview(iconImageView)
        cardView.addSubview(titleLabel)
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(24)
            make.width.height.equalTo(44)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        
        // 添加点击手势
        let tapGesture = CardTapGestureRecognizer(action: action)
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        return containerView
    }
    
    // MARK: - Actions
    private func handleReadData() {
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "将NFC标签靠近设备"
        nfcSession?.begin()
    }
    
    private func handleWriteData() {
        nfcTagSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
        nfcTagSession?.alertMessage = "将NFC标签靠近设备以写入数据"
        nfcTagSession?.begin()
    }
    
    private func handleDelete() {
        showAlert(title: "删除功能", message: "该功能需要标签支持，请确保您的NFC标签支持删除操作")
    }
    
    private func handlePasswordSettings() {
        showAlert(title: "密码设置", message: "该功能需要标签支持，请确保您的NFC标签支持密码保护")
    }
    
    private func handleLock() {
        showAlert(title: "锁定功能", message: "该功能需要标签支持，请确保您的NFC标签支持锁定操作")
    }

// MARK: - NFCNDEFReaderSessionDelegate Methods
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // 处理检测到的NDEF消息
        for message in messages {
            for record in message.records {
                // 解析记录内容
                let payload = String(data: record.payload, encoding: .utf8)
                print("检测到NDEF记录: \(record.type) - \(payload ?? "无法解析")")
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "读取成功", message: "已成功读取NFC标签数据")
            session.invalidate()
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // 处理会话错误
        let nfcError = error as! NFCReaderError
        if nfcError.code != .readerSessionInvalidationErrorFirstNDEFTagRead && nfcError.code != .readerSessionInvalidationErrorUserCanceled {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "读取失败", message: "\(error.localizedDescription)")
            }
        }
        
        nfcSession = nil
    }
    
    // MARK: - NFCTagReaderSessionDelegate Methods
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "未检测到标签")
            return
        }
        
        // 将NFCTag转换为NFCNDEFTag
        guard case .ndef(let ndefTag) = tag else {
            session.invalidate(errorMessage: "标签不支持NDEF")
            return
        }
        
        session.connect(to: tag) { [weak self] error in
            guard error == nil else {
                session.invalidate(errorMessage: "无法连接到标签")
                return
            }
            
            ndefTag.queryNDEFStatus { [weak self] status, capacity, error in
                guard error == nil else {
                    session.invalidate(errorMessage: "无法查询标签状态")
                    return
                }
                
                switch status {
                case .notSupported:
                    session.invalidate(errorMessage: "标签不支持NDEF")
                case .readOnly:
                    session.invalidate(errorMessage: "标签是只读的")
                case .readWrite:
                    self?.writeNDEFData(to: ndefTag, in: session)
                @unknown default:
                    session.invalidate(errorMessage: "未知标签状态")
                }
            }
        }
    }
    
    private func writeNDEFData(to tag: NFCNDEFTag, in session: NFCTagReaderSession) {
        // 创建NDEF记录
        guard let payload = testNDEFData.data(using: .utf8) else {
            session.invalidate(errorMessage: "无法创建数据")
            return
        }
        
        let ndefMessage = NFCNDEFMessage(records: [NFCNDEFPayload.wellKnownTypeTextPayload(string: testNDEFData, locale: Locale.current)!])
        
        tag.writeNDEF(ndefMessage) { [weak self] error in
            guard error == nil else {
                session.invalidate(errorMessage: "写入失败: \(error!.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "写入成功", message: "已成功将数据写入NFC标签")
            }
            
            session.invalidate()
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as! NFCReaderError
        if nfcError.code != .readerSessionInvalidationErrorUserCanceled {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "写入失败", message: "\(error.localizedDescription)")
            }
        }
        
        nfcTagSession = nil
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Custom Tap Gesture Recognizer
class CardTapGestureRecognizer: UITapGestureRecognizer {
    private var action: (() -> Void)?
    
    convenience init(action: @escaping () -> Void) {
        self.init(target: nil, action: nil)
        self.action = action
        self.addTarget(self, action: #selector(executeAction))
    }
    
    @objc private func executeAction() {
        action?()
    }
}

