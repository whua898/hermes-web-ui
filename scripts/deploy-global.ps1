# 停止全局服务
Write-Output "停止全局服务..."
hermes-web-ui stop 2>$null
Start-Sleep -Seconds 3

# 获取全局路径
$globalPath = (npm root -g).Trim()
$globalDist = "$globalPath\hermes-web-ui\dist"

# 删除旧 dist
Write-Output "删除旧 dist: $globalDist"
if (Test-Path $globalDist) {
    Remove-Item $globalDist -Recurse -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# 复制新 dist
Write-Output "复制新 dist..."
Copy-Item "dist\*" $globalDist -Recurse -Force

# 验证
$success = Test-Path "$globalDist\client\index.html"
if ($success) {
    Write-Output "✅ 复制成功"
    hermes-web-ui start
    Write-Output "✅ 全局服务已启动"
} else {
    Write-Output "❌ 复制失败"
    exit 1
}
