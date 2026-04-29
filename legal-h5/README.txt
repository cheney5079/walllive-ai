独立 H5 页面说明（隐私政策 / 用户协议）
========================================

本目录文件：
  privacy.html   — 隐私政策全文（由 LegalCopy.swift 脚本生成，修改条文后请重新生成或手动同步）
  terms.html     — 用户协议全文

部署后你将得到两个 HTTPS 链接（示例结构）：
  https://<你的域名>/legal-h5/privacy.html
  https://<你的域名>/legal-h5/terms.html

配置步骤：
  1. 将 legal-h5 整个目录上传到任意 HTTPS 静态托管（对象存储 + CDN、GitHub Pages、Vercel、自有 Nginx 等）。
  2. 打开 Configs/Legal.urls.xcconfig，把两处 URL 改成实际上线地址（勿有空格）。
  3. 在项目根目录执行：xcodegen generate，再用 Xcode 编译运行。
  4. App Store Connect「App 隐私」与「隐私政策网址」等字段，填写与 privacy.html 一致的 HTTPS 链接。

应用行为：
  • Info.plist 键 LegalPrivacyPolicyURL / LegalUserAgreementURL 非空且为 http(s) 时，应用内用内置浏览器打开线上页面。
  • 若未配置有效 URL，则回退为应用内本地文本（LegalCopy）。
