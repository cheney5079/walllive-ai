import Foundation

/// 火山方舟 Ark：`POST/GET …/api/v3/contents/generations/tasks`
final class VolcanoService {
    private let apiKey: String
    private let baseURL = URL(string: "https://ark.cn-beijing.volces.com/api/v3")!
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// 图生视频：创建任务后轮询直到完成
    func imageToVideo(
        imageJPEGData: Data,
        textPrompt: String,
        endpointId: String,
        onPoll: @escaping (String, Int) -> Void
    ) async throws -> VolcanoVideoResult {
        let mime = "image/jpeg"
        let b64 = imageJPEGData.base64EncodedString()
        let dataURI = "data:\(mime);base64,\(b64)"

        let taskId = try await createTask(
            endpointId: endpointId,
            imageDataURI: dataURI,
            textPrompt: textPrompt
        )

        let deadline = Date().addingTimeInterval(120 * 2)
        var attempt = 0
        while Date() < deadline {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            attempt += 1
            let query = try await getTask(taskId: taskId)
            onPoll(query.normalizedStatus, attempt)
            if query.isSucceeded {
                guard let url = query.resolvedVideoURL else {
                    throw VolcanoError.message("任务成功但未解析到视频 URL")
                }
                return VolcanoVideoResult(taskId: taskId, videoURL: url, thumbnailURL: query.thumbnailURL)
            }
            if query.isFailed {
                throw VolcanoError.message(query.errorMessage ?? "任务失败")
            }
        }
        throw VolcanoError.message("轮询超时")
    }

    private func createTask(endpointId: String, imageDataURI: String, textPrompt: String) async throws -> String {
        let url = baseURL.appendingPathComponent("contents/generations/tasks")
        let body: [String: Any] = [
            "model": endpointId,
            "content": [
                ["type": "text", "role": "user", "text": textPrompt],
                ["type": "image_url", "role": "reference_image", "image_url": ["url": imageDataURI]]
            ],
            "duration": 5,
            "resolution": "720p",
            "ratio": "9:16"
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        try throwIfHTTPError(data: data, response: resp)

        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VolcanoError.message("无效 JSON")
        }
        let root = (obj["data"] as? [String: Any]) ?? obj
        let id = (root["id"] as? String)
            ?? (root["task_id"] as? String)
            ?? ((obj["data"] as? [String: Any])?["id"] as? String)
        guard let taskId = id, !taskId.isEmpty else {
            throw VolcanoError.message("无法解析任务 ID")
        }
        return taskId
    }

    private func getTask(taskId: String) async throws -> TaskQueryResult {
        let url = baseURL.appendingPathComponent("contents/generations/tasks/\(taskId)")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await session.data(for: req)
        try throwIfHTTPError(data: data, response: resp)

        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VolcanoError.message("无效 JSON")
        }
        return TaskQueryResult(json: obj)
    }

    private func throwIfHTTPError(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200 ..< 300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw VolcanoError.message("HTTP \(http.statusCode) \(text)")
        }
    }
}

struct VolcanoVideoResult {
    let taskId: String
    let videoURL: URL
    let thumbnailURL: URL?
}

enum VolcanoError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self {
        case .message(let s): return s
        }
    }
}

struct TaskQueryResult {
    let raw: [String: Any]
    let normalizedStatus: String
    let videoURLString: String?
    let thumbnailURLString: String?
    let errorMessage: String?

    init(json: [String: Any]) {
        let root = (json["data"] as? [String: Any]) ?? json
        raw = root
        let s = (root["status"] as? String)
            ?? (root["task_status"] as? String)
            ?? (root["state"] as? String)
            ?? (json["status"] as? String)
            ?? ""
        normalizedStatus = s.lowercased()

        var video: String?
        var thumb: String?
        let content = root["content"] ?? root["output"] ?? root["result"]
        if let c = content as? [String: Any] {
            video = c["video_url"] as? String ?? c["url"] as? String
            thumb = c["cover_url"] as? String ?? c["thumbnail_url"] as? String
            if let inner = c["videos"] as? [[String: Any]], let first = inner.first {
                video = video ?? first["url"] as? String ?? first["video_url"] as? String
            }
        }

        var err: String?
        if let e = root["error"] as? String { err = e }
        if let e = root["failure_reason"] as? String { err = err ?? e }
        if let e = root["error"] as? [String: Any], let m = e["message"] as? String { err = m }

        videoURLString = video
        thumbnailURLString = thumb
        errorMessage = err
    }

    var isSucceeded: Bool {
        normalizedStatus == "succeeded" || normalizedStatus == "success" || normalizedStatus == "completed"
    }

    var isFailed: Bool {
        normalizedStatus == "failed" || normalizedStatus == "error" || normalizedStatus == "cancelled"
    }

    var resolvedVideoURL: URL? {
        if let s = videoURLString, let u = URL(string: s) { return u }
        return TaskQueryResult.deepFindVideoURL(in: raw).flatMap { URL(string: $0) }
    }

    var thumbnailURL: URL? {
        if let s = thumbnailURLString, let u = URL(string: s) { return u }
        return nil
    }

    private static func deepFindVideoURL(in any: Any) -> String? {
        if let s = any as? String, s.hasPrefix("http"), (s.lowercased().contains(".mp4") || s.lowercased().contains("video")) {
            return s
        }
        if let d = any as? [String: Any] {
            for v in d.values {
                if let x = deepFindVideoURL(in: v) { return x }
            }
        }
        if let arr = any as? [Any] {
            for v in arr {
                if let x = deepFindVideoURL(in: v) { return x }
            }
        }
        return nil
    }
}
