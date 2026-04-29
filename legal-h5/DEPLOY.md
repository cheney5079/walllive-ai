# 一键部署到 GitHub Pages

1. 在 GitHub 打开仓库 **cheney5079/walllive-ai** → **Settings** → **Pages**。
2. **Build and deployment** → **Source** 选 **GitHub Actions**（不要选 Deploy from a branch，除非你改用分支部署）。
3. 推送包含 `.github/workflows/deploy-legal-pages.yml` 与 `legal-h5/` 的提交后，在 **Actions** 页查看 **Deploy legal H5 to GitHub Pages** 是否成功。
4. 成功后访问（约 1～2 分钟生效）：
   - https://cheney5079.github.io/walllive-ai/privacy.html
   - https://cheney5079.github.io/walllive-ai/terms.html

若首页 404 正常：静态站点只放了这两个页面，无 index.html。

故障排查：Actions 报权限错误时，确认 Pages 源已切换为 GitHub Actions；首次需在 Actions 里批准 **workflow** 运行。
