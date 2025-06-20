import SwiftUI

struct RetryableView<Content: View, LoadingView: View, ErrorView: View>: View {
    let content: () -> Content
    let loadingView: () -> LoadingView
    let errorView: (WQError, @escaping () -> Void) -> ErrorView
    let retryAction: () async throws -> Void
    
    @State private var isLoading = false
    @State private var error: WQError?
    @State private var retryCount = 0
    @State private var lastRetryTime: Date?
    
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    
    var body: some View {
        Group {
            if isLoading {
                loadingView()
            } else if let error = error {
                errorView(error) {
                    Task {
                        await performRetry()
                    }
                }
            } else {
                content()
            }
        }
        .onAppear {
            if error != nil {
                Task {
                    await performInitialLoad()
                }
            }
        }
    }
    
    private func performInitialLoad() async {
        await performAction()
    }
    
    private func performRetry() async {
        guard retryCount < maxRetryAttempts else {
            error = .system(.resourceUnavailable("Max retry attempts reached"))
            return
        }
        
        // Implement exponential backoff
        if let lastTime = lastRetryTime {
            let timeSinceLastRetry = Date().timeIntervalSince(lastTime)
            let requiredDelay = retryDelay * pow(2.0, Double(retryCount))
            
            if timeSinceLastRetry < requiredDelay {
                let remainingDelay = requiredDelay - timeSinceLastRetry
                try? await Task.sleep(nanoseconds: UInt64(remainingDelay * 1_000_000_000))
            }
        }
        
        retryCount += 1
        lastRetryTime = Date()
        await performAction()
    }
    
    private func performAction() async {
        isLoading = true
        error = nil
        
        do {
            try await retryAction()
            // Success - reset retry state
            retryCount = 0
            lastRetryTime = nil
        } catch let wqError as WQError {
            error = wqError
        } catch let retryError {
            error = WQError.system(.resourceUnavailable(retryError.localizedDescription))
        }
        
        isLoading = false
    }
}

// MARK: - Convenience Initializers

extension RetryableView where LoadingView == DefaultLoadingView {
    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder errorView: @escaping (WQError, @escaping () -> Void) -> ErrorView,
        retryAction: @escaping () async throws -> Void
    ) {
        self.content = content
        self.loadingView = { DefaultLoadingView() }
        self.errorView = errorView
        self.retryAction = retryAction
    }
}

extension RetryableView where ErrorView == DefaultErrorView {
    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder loadingView: @escaping () -> LoadingView,
        retryAction: @escaping () async throws -> Void
    ) {
        self.content = content
        self.loadingView = loadingView
        self.errorView = { error, retry in DefaultErrorView(error: error, onRetry: retry) }
        self.retryAction = retryAction
    }
}

extension RetryableView where LoadingView == DefaultLoadingView, ErrorView == DefaultErrorView {
    init(
        @ViewBuilder content: @escaping () -> Content,
        retryAction: @escaping () async throws -> Void
    ) {
        self.content = content
        self.loadingView = { DefaultLoadingView() }
        self.errorView = { error, retry in DefaultErrorView(error: error, onRetry: retry) }
        self.retryAction = retryAction
    }
}

// MARK: - Default Views

struct DefaultLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.clockwise")
                .font(.title2)
                .foregroundColor(.accentColor)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
            
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct DefaultErrorView: View {
    let error: WQError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(error.userMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            if error.isRetryable {
                Button("Try Again") {
                    onRetry()
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }
}

// MARK: - Specialized Retryable Views

struct RetryableDataView<Data, Content: View>: View {
    let loadData: () async throws -> Data
    let content: (Data) -> Content
    
    @State private var data: Data?
    @State private var isLoading = true
    @State private var error: WQError?
    
    var body: some View {
        RetryableView(
            content: {
                if let data = data {
                    content(data)
                } else {
                    Text("No data available")
                        .foregroundColor(.secondary)
                }
            },
            retryAction: {
                let loadedData = try await loadData()
                await MainActor.run {
                    self.data = loadedData
                }
            }
        )
    }
}

struct RetryableAsyncImage: View {
    let url: String
    let placeholder: String
    
    @State private var imageData: Data?
    @State private var isLoading = true
    @State private var error: WQError?
    
    var body: some View {
        RetryableView(
            content: {
                if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: placeholder)
                        .foregroundColor(.secondary)
                }
            },
            retryAction: {
                guard let url = URL(string: url) else {
                    throw WQError.validation(.dataFormatError("Invalid URL"))
                }
                
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    self.imageData = data
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RetryableView(
            content: {
                Text("Content loaded successfully!")
                    .foregroundColor(.green)
            },
            retryAction: {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                // Simulate random failure
                if Bool.random() {
                    throw WQError.network(.timeout)
                }
            }
        )
        
        RetryableDataView(
            loadData: {
                try await Task.sleep(nanoseconds: 500_000_000)
                return "Sample data"
            },
            content: { data in
                Text("Loaded: \(data)")
                    .foregroundColor(.blue)
            }
        )
    }
    .padding()
}