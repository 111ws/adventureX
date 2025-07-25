import SwiftUI
import PencilKit
import CoreGraphics

struct WhiteboardCanvasView: View {
    @State var canvasView = PKCanvasView()
    @State var toolPicker: PKToolPicker = {
        let toolPicker = PKToolPicker(toolItems: [
            PKToolPickerInkingItem(type: .pen),
            PKToolPickerEraserItem(type: .fixedWidthBitmap),
            PKToolPickerLassoItem(),
        ])
        return toolPicker
    }()
    
    @State private var showSidebar = false
    @State private var textNotes: [String] = ["笔记 1", "笔记 2", "笔记 3"]
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 主画布
                CanvasRepresentable(
                    canvasView: $canvasView,
                    toolPicker: $toolPicker
                )
                .clipped()
                .onAppear {
                    setupToolPicker()
                    setupInfiniteCanvas()
                }
                
                // 侧边栏
                HStack {
                    if showSidebar {
                        ZStack {
                            // 阴影矩形 - 放在底部
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.2))
                                .frame(width: (geometry.size.width / 3) + 10, height: nil)
                                .offset(x: 10, y: 10) // 稍微偏移产生阴影效果
                            
                            // 侧边栏主体
                            SidebarView(
                                showSidebar: $showSidebar,
                                screenWidth: geometry.size.width
                            )
                        }
                        .frame(width: geometry.size.width / 3)
                        .zIndex(2)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    
                    Spacer()
                }
                .padding(.leading,20)
                .padding(.top,20)
                .padding(.bottom,20)
               
                // 侧边栏切换按钮
                if !showSidebar {
                    VStack {
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    showSidebar.toggle()
                                }
                            }) {
                                Image(systemName: "text.alignleft")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .padding(.leading, 20)
                            .padding(.top, 20)
                            .zIndex(3)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    func setupToolPicker() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
    
    func setupInfiniteCanvas() {
        // 设置一个非常大的画布尺寸
        let largeSize = CGSize(width: 50000, height: 50000)
        canvasView.contentSize = largeSize
        
        // 启用滚动
        canvasView.isScrollEnabled = true
        canvasView.maximumZoomScale = 3.0
        canvasView.minimumZoomScale = 0.1
        canvasView.bouncesZoom = true
        
        // 设置初始位置在画布中心
        let centerOffset = CGPoint(
            x: (largeSize.width - canvasView.bounds.width) / 2,
            y: (largeSize.height - canvasView.bounds.height) / 2
        )
        canvasView.contentOffset = centerOffset
    }
}

// MARK: - Canvas Representable
struct CanvasRepresentable: UIViewRepresentable {
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        
    }
    
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker

    
    // makeUIView 方法中恢复工具设置
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 15)  // 恢复这行
        canvasView.backgroundColor = UIColor.systemBackground
        return canvasView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: CanvasRepresentable
        private var captureTimer: Timer?
        private var lastDrawingTime: Date?
        
        init(_ parent: CanvasRepresentable) {
            self.parent = parent
            print("[调试] 协调器已初始化")
        }
        
        // 当绘制发生变化时调用
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            print("[调试] 检测到绘制变化")
            expandCanvasIfNeeded(canvasView)
            
            // 记录最后绘制时间
            lastDrawingTime = Date()
            print("[调试] 最后绘制时间已更新: \(lastDrawingTime!)")
            
            // 取消之前的定时器
            if captureTimer != nil {
                print("[调试] 正在取消之前的定时器")
                captureTimer?.invalidate()
            }
            
            // 设置新的定时器，1秒后捕获图像
            print("[调试] 设置新的捕获定时器，1秒后执行")
            captureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                print("[调试] 定时器触发 - 开始图像捕获")
                self?.captureAndSendImage(canvasView)
            }
        }
        
        // 扩展画布尺寸（如果需要）
        private func expandCanvasIfNeeded(_ canvasView: PKCanvasView) {
            let drawing = canvasView.drawing
            let bounds = drawing.bounds
            
            print("[调试] 检查画布扩展 - 边界: \(bounds)")
            
            // 检查是否为空边界
            guard !bounds.isEmpty && bounds.width > 0 && bounds.height > 0 else {
                print("[调试] 边界为空或无效，跳过扩展")
                return
            }
            
            let currentSize = canvasView.contentSize
            let margin: CGFloat = 1000
            
            let newWidth = max(currentSize.width, bounds.maxX + margin)
            let newHeight = max(currentSize.height, bounds.maxY + margin)
            let newSize = CGSize(width: newWidth, height: newHeight)
            
            print("[调试] 当前尺寸: \(currentSize)，新尺寸: \(newSize)")
            
            // 验证新尺寸的合理性
            guard newSize.width <= 100000 && newSize.height <= 100000 else {
                print("[调试] 新尺寸超出最大限制，跳过扩展")
                return
            }
            
            if newSize != currentSize {
                print("[调试] 正在将画布扩展到新尺寸: \(newSize)")
                DispatchQueue.main.async {
                    canvasView.contentSize = newSize
                    print("[调试] 画布尺寸更新成功")
                }
            } else {
                print("[调试] 画布尺寸未变化，无需扩展")
            }
        }
        
        // 捕获画布图像并发送到后端
        private func captureAndSendImage(_ canvasView: PKCanvasView) {
            print("[调试] 开始图像捕获过程")
            
            // 获取画布的可见区域
            let visibleRect = canvasView.bounds
            print("[调试] 可见区域: \(visibleRect)")
            
            // 创建图像渲染器
            let renderer = UIGraphicsImageRenderer(bounds: visibleRect)
            print("[调试] 图像渲染器已创建")
            
            let image = renderer.image { context in
                print("[调试] 正在渲染图像...")
                // 设置背景色
                UIColor.systemBackground.setFill()
                context.fill(visibleRect)
                
                // 渲染画布内容
                canvasView.drawing.image(from: visibleRect, scale: 1.0).draw(in: visibleRect)
                print("[调试] 图像渲染完成")
            }
            
            print("[调试] 图像尺寸: \(image.size)")
            
            // 将图像转换为PNG数据
            guard let imageData = image.pngData() else {
                print("[错误] 无法将图像转换为PNG数据")
                return
            }
            
            print("[调试] 图像已转换为PNG数据，大小: \(imageData.count) 字节")
            
            // 发送图像到后端
            sendImageToBackend(imageData: imageData)
        }
        
        // 发送图像数据到后端
        private func sendImageToBackend(imageData: Data) {
            print("[调试] 准备发送图像到后端")
            
            guard let url = URL(string: "http://localhost:9999/ocr") else {
                print("[错误] 无效的URL: http://localhost:900/ocr")
                return
            }
            
            print("[调试] 后端URL: \(url)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            print("[调试] 请求边界: \(boundary)")
            
            var body = Data()
            
            // 添加图像数据
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"canvas.png\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            print("[调试] 请求体大小: \(body.count) 字节")
            print("[调试] 正在发送HTTP请求...")
            
            // 发送请求
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("[错误] 网络错误: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[调试] 收到HTTP响应 - 状态码: \(httpResponse.statusCode)")
                    print("[调试] 响应头: \(httpResponse.allHeaderFields)")
                    
                    if httpResponse.statusCode == 200 {
                        print("[成功] 图像发送成功！")
                    } else {
                        print("[警告] 意外的状态码: \(httpResponse.statusCode)")
                    }
                }
                
                if let data = data {
                    print("[调试] 响应数据大小: \(data.count) 字节")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("[调试] 后端响应: \(responseString)")
                    } else {
                        print("[调试] 响应数据不是有效的UTF-8字符串")
                    }
                } else {
                    print("[调试] 未收到响应数据")
                }
            }.resume()
            
            print("[调试] HTTP请求已发起")
        }
        
        deinit {
            print("[调试] 协调器正在销毁")
            captureTimer?.invalidate()
        }
    }
}

#Preview {
    WhiteboardCanvasView()
}
