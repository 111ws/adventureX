import Foundation
import Network

class SSHTunnelClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "ssh.tunnel.client")
    
    func connectThroughTunnel(port: UInt16 = 9999) {
        // 连接到本地端口（通过SSH隧道连接到Windows）
        let endpoint = NWEndpoint.hostPort(
            host: "localhost",  // 通过SSH隧道，连接本地端口
            port: NWEndpoint.Port(rawValue: port)!
        )
        
        connection = NWConnection(to: endpoint, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✅ 通过SSH隧道连接到Windows服务器")
                self?.startReceiving()
            case .failed(let error):
                print("❌ 隧道连接失败: \(error)")
            case .cancelled:
                print("🔌 隧道连接已取消")
            default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }
    
    private func startReceiving() {
        receiveMessage()
    }
    
    private func receiveMessage() {
        // 接收消息长度
        connection?.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, _, error in
            
            if let error = error {
                print("接收长度出错: \(error)")
                return
            }
            
            guard let data = data, data.count == 4 else {
                print("长度数据无效")
                return
            }
            
            let messageLength = data.withUnsafeBytes { bytes in
                return bytes.load(as: UInt32.self).bigEndian
            }
            
            // 接收消息内容
            self?.connection?.receive(minimumIncompleteLength: Int(messageLength), maximumLength: Int(messageLength)) { messageData, _, _, error in
                
                if let error = error {
                    print("接收消息出错: \(error)")
                    return
                }
                
            