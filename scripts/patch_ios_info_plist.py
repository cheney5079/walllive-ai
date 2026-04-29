#!/usr/bin/env python3
"""向 Flutter iOS Runner 的 Info.plist 合并相册/相机用途说明（Unicode 安全）。"""
import plistlib
import sys
from pathlib import Path


def main() -> None:
    path = Path(sys.argv[1])
    data = plistlib.loads(path.read_bytes())

    extra = {
        "NSPhotoLibraryUsageDescription": (
            "Livewall AI 需要访问相册，以便你选择照片并生成动态壁纸。"
        ),
        "NSPhotoLibraryAddUsageDescription": (
            "若后续支持保存视频到相册，将使用该权限。"
        ),
        "NSCameraUsageDescription": (
            "若你选择「拍照」上传，需要使用相机拍摄照片。"
        ),
    }
    data.update(extra)
    path.write_bytes(plistlib.dumps(data, fmt=plistlib.FMT_XML))


if __name__ == "__main__":
    main()
