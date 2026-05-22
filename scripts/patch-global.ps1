# Hermes Web UI 全局修补脚本
# 功能：git pull 后自动修补源码 + 编译 + 覆盖全局安装目录
# 触发：.git/hooks/post-merge（git pull 后自动执行）
# 也可手动运行：.\scripts\patch-global.ps1
#
# 补丁内容：
#   P1: providers.ts — 添加 NVIDIA NIM provider preset
#   P2: models.ts (controller) — 修复 builtin preset 动态 fetch 逻辑
#   P3: models.ts (controller) — 添加 fetchModelsFromProvider 函数
#   P4: models.ts (routes)     — 添加 /api/hermes/fetch-models 路由
#   P5: ProviderFormModal.vue  — 前端 fetch-models 改走后端代理

$ErrorActionPreference = "Stop"

# ============================
# 配置
# ============================
$ProjectRoot = $PSScriptRoot | Split-Path -Parent
$GlobalInstallPath = "$env:APPDATA\npm\node_modules\hermes-web-ui"

$ProvidersFile      = Join-Path $ProjectRoot "packages\server\src\shared\providers.ts"
$ModelsCtrlFile     = Join-Path $ProjectRoot "packages\server\src\controllers\hermes\models.ts"
$ModelsRouteFile    = Join-Path $ProjectRoot "packages\server\src\routes\hermes\models.ts"
$ProviderModalFile  = Join-Path $ProjectRoot "packages\client\src\components\hermes\models\ProviderFormModal.vue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Hermes Web UI 全局修补脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================
# 步骤 1: 检查全局安装目录
# ============================
Write-Host "[1/6] 检查全局安装目录..." -ForegroundColor Yellow

if (!(Test-Path $GlobalInstallPath)) {
    Write-Host "警告: 全局安装目录不存在: $GlobalInstallPath" -ForegroundColor Yellow
    Write-Host "跳过覆盖步骤（编译仍会执行）" -ForegroundColor Yellow
    Write-Host "稍后可手动运行: npm install -g hermes-web-ui" -ForegroundColor Yellow
}
Write-Host ""

# ============================
# 步骤 2: P1 — providers.ts 添加 NVIDIA preset
# ============================
Write-Host "[2/6] P1: 检查 NVIDIA Provider preset..." -ForegroundColor Yellow

if (!(Test-Path $ProvidersFile)) {
    Write-Host "错误: providers.ts 不存在: $ProvidersFile" -ForegroundColor Red
    exit 1
}

$content = Get-Content $ProvidersFile -Raw -Encoding UTF8

if ($content -match "label:\s*'NVIDIA'") {
    Write-Host "  ✓ NVIDIA Provider preset 已存在" -ForegroundColor Green
} else {
    Write-Host "  NVIDIA Provider preset 不存在，正在添加..." -ForegroundColor Yellow

    $nvidiaBlock = @"
    {
      label: 'NVIDIA',
      value: 'nvidia',
      builtin: true,
      base_url: 'https://integrate.api.nvidia.com/v1',
      models: [],
    },
"@

    # 在 DeepSeek 块的 }, 后面插入
    $pattern = "(label:\s*'DeepSeek',\s*value:\s*'deepseek',[^}]*?models:\s*\[[^\]]*\]\s*,\s*\},)"
    if ($content -match $pattern) {
        $insertPoint = $content.IndexOf($Matches[1]) + $Matches[1].Length
        $content = $content.Insert($insertPoint, "`n$nvidiaBlock")

        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($ProvidersFile),
            $content,
            [System.Text.Encoding]::UTF8
        )

        Write-Host "  ✓ NVIDIA Provider preset 添加成功" -ForegroundColor Green
    } else {
        Write-Host "  错误: 无法找到 DeepSeek Provider 块，跳过 P1" -ForegroundColor Red
    }
}
Write-Host ""

# ============================
# 步骤 3: P2 — 修复动态 fetch 逻辑
# ============================
Write-Host "[3/6] P2: 修复 builtin preset 动态 fetch 逻辑..." -ForegroundColor Yellow

if (!(Test-Path $ModelsCtrlFile)) {
    Write-Host "错误: models.ts (controller) 不存在: $ModelsCtrlFile" -ForegroundColor Red
    exit 1
}

$ctrlContent = Get-Content $ModelsCtrlFile -Raw -Encoding UTF8

if ($ctrlContent -match "if\s*\(\s*!builtinPreset\?\.\w+\?\.\w+\s+&&\s+cp\.api_key\s*\)") {
    Write-Host "  ✓ 动态 fetch 逻辑已是新版本" -ForegroundColor Green
} elseif ($ctrlContent -match "if\s*\(\s*!builtinPreset\s+&&\s+cp\.api_key\s*\)") {
    $ctrlContent = $ctrlContent -replace "if\s*\(\s*!builtinPreset\s+&&\s+cp\.api_key\s*\)", "if (!builtinPreset?.models?.length && cp.api_key)"

    # 同时修复注释
    $ctrlContent = $ctrlContent -replace "// Skip dynamic fetch for builtin presets[^\\n]*", "// Skip dynamic fetch for builtin presets that already have models"
    $ctrlContent = $ctrlContent -replace "(// Skip dynamic fetch for builtin presets that already have models\s*\n)", "`$1// But fetch for presets with empty models list (e.g. NVIDIA) or non-builtin providers`n"

    [System.IO.File]::WriteAllText(
        [System.IO.Path]::GetFullPath($ModelsCtrlFile),
        $ctrlContent,
        [System.Text.Encoding]::UTF8
    )

    Write-Host "  ✓ 动态 fetch 逻辑修复成功" -ForegroundColor Green
} else {
    Write-Host "  ? 未匹配到任何 fetch 逻辑模式，手动检查" -ForegroundColor Yellow
}
Write-Host ""

# ============================
# 步骤 4: P3+P4 — 添加 fetchModelsFromProvider 函数 + 路由
# ============================
Write-Host "[4/6] P3+P4: 检查 fetchModelsFromProvider..." -ForegroundColor Yellow

# 重新读取（步骤3可能已修改）
$ctrlContent = Get-Content $ModelsCtrlFile -Raw -Encoding UTF8

if ($ctrlContent -match "fetchModelsFromProvider") {
    Write-Host "  ✓ fetchModelsFromProvider 函数已存在" -ForegroundColor Green
} else {
    Write-Host "  添加 fetchModelsFromProvider 函数..." -ForegroundColor Yellow

    $fetchFunc = @'

export async function fetchModelsFromProvider(ctx: any) {
  const { base_url, api_key } = ctx.request.body as { base_url: string; api_key: string }
  if (!base_url) {
    ctx.status = 400
    ctx.body = { error: 'Missing base_url' }
    return
  }
  try {
    const base = base_url.replace(/\/+$/, '')
    const modelsUrl = /\/v\d+\/?$/.test(base) ? `${base}/models` : `${base}/v1/models`
    const headers: Record<string, string> = {}
    if (api_key) headers['Authorization'] = `Bearer ${api_key}`
    const res = await fetch(modelsUrl, {
      headers,
      signal: AbortSignal.timeout(10000),
    })
    if (!res.ok) {
      ctx.status = res.status
      ctx.body = { error: `HTTP ${res.status}` }
      return
    }
    const data = await res.json() as { data?: Array<{ id: string }> }
    if (!Array.isArray(data.data)) {
      ctx.status = 502
      ctx.body = { error: 'Unexpected response format' }
      return
    }
    const uniqueModels = Array.from(new Set(data.data.map(m => m.id))).sort()
    ctx.body = { models: uniqueModels }
  } catch (err: any) {
    ctx.status = 502
    ctx.body = { error: err.message }
  }
}

'@

    # 在 getConfigModels 函数前插入
    $insertMarker = "(export async function getConfigModels)"
    if ($ctrlContent -match $insertMarker) {
        $ctrlContent = $ctrlContent -replace $insertMarker, "$fetchFunc`n`$1"

        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($ModelsCtrlFile),
            $ctrlContent,
            [System.Text.Encoding]::UTF8
        )

        Write-Host "  ✓ fetchModelsFromProvider 函数添加成功" -ForegroundColor Green
    } else {
        Write-Host "  错误: 无法找到 getConfigModels 插入点" -ForegroundColor Red
    }
}

# P4: 路由
if (!(Test-Path $ModelsRouteFile)) {
    Write-Host "错误: models.ts (routes) 不存在: $ModelsRouteFile" -ForegroundColor Red
    exit 1
}

$routeContent = Get-Content $ModelsRouteFile -Raw -Encoding UTF8

if ($routeContent -match "fetch-models") {
    Write-Host "  ✓ fetch-models 路由已存在" -ForegroundColor Green
} else {
    Write-Host "  添加 fetch-models 路由..." -ForegroundColor Yellow

    # 在最后一行路由后追加
    $routeContent = $routeContent.TrimEnd() + "`nmodelRoutes.post('/api/hermes/fetch-models', ctrl.fetchModelsFromProvider)`n"

    [System.IO.File]::WriteAllText(
        [System.IO.Path]::GetFullPath($ModelsRouteFile),
        $routeContent,
        [System.Text.Encoding]::UTF8
    )

    Write-Host "  ✓ fetch-models 路由添加成功" -ForegroundColor Green
}
Write-Host ""

# ============================
# 步骤 5: P5 — ProviderFormModal.vue 改走后端代理
# ============================
Write-Host "[5/6] P5: 检查 ProviderFormModal.vue fetch-models 代理..." -ForegroundColor Yellow

if (!(Test-Path $ProviderModalFile)) {
    Write-Host "警告: ProviderFormModal.vue 不存在，跳过 P5" -ForegroundColor Yellow
} else {
    $vueContent = Get-Content $ProviderModalFile -Raw -Encoding UTF8

    if ($vueContent -match "/api/hermes/fetch-models") {
        Write-Host "  ✓ ProviderFormModal.vue 已使用后端代理" -ForegroundColor Green
    } else {
        Write-Host "  修补 ProviderFormModal.vue..." -ForegroundColor Yellow

        # 添加 import { request } from '@/api/client'
        if ($vueContent -notmatch "import.*request.*from.*@/api/client") {
            $vueContent = $vueContent -replace "(import \{ useModelsStore \} from '@/stores/hermes/models'\s*\n)", "`$1import { request } from '@/api/client'`n"
        }

        # 替换 fetchModels 函数中的直接 fetch 为后端代理
        $oldFetch = "(?s)fetchingModels\.value = true\s*\n\s*try \{\s*\n\s*const base = base_url\.replace.*?const data = await res\.json.*?if \(!Array\.IsArray\(data\.data\)\).*?modelOptions\.value = data\.data\.map"
        $newFetch = @'
fetchingModels.value = true
  try {
    const data = await request<{ models?: string[] }>('/api/hermes/fetch-models', {
      method: 'POST',
      body: JSON.stringify({
        base_url: base_url.trim(),
        api_key: formData.value.api_key.trim(),
      }),
    })
    if (!Array.isArray(data.models)) throw new Error(t('models.unexpectedFormat'))

    modelOptions.value = data.models.map
'@
        if ($vueContent -match $oldFetch) {
            $vueContent = $vueContent -replace $oldFetch, $newFetch

            # 修正 .map 回调：data.data.map(m => ...) → data.models.map(m => ...)
            $vueContent = $vueContent -replace "\(m => \(\{ label: m\.id, value: m\.id \}\)\)", "(m => ({ label: m, value: m }))"

            [System.IO.File]::WriteAllText(
                [System.IO.Path]::GetFullPath($ProviderModalFile),
                $vueContent,
                [System.Text.Encoding]::UTF8
            )

            Write-Host "  ✓ ProviderFormModal.vue 修补成功" -ForegroundColor Green
        } else {
            Write-Host "  ? 未匹配到旧 fetch 代码，可能已修改或格式不同" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# ============================
# 步骤 6: 编译 + 覆盖全局安装目录
# ============================
Write-Host "[6/6] 编译项目..." -ForegroundColor Yellow
Set-Location $ProjectRoot

# npm install（package.json 变更时重新安装）
if (!(Test-Path "node_modules")) {
    Write-Host "  node_modules 不存在，运行 npm install..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: npm install 失败" -ForegroundColor Red
        exit 1
    }
}

# 执行编译
Write-Host "  运行 npm run build..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: npm run build 失败" -ForegroundColor Red
    exit 1
}

if (!(Test-Path "dist")) {
    Write-Host "错误: dist 目录不存在，编译失败" -ForegroundColor Red
    exit 1
}

Write-Host "  ✓ 编译成功" -ForegroundColor Green

# 覆盖全局安装目录（仅当存在时）
if (Test-Path $GlobalInstallPath) {
    Write-Host "  覆盖全局安装目录..." -ForegroundColor Yellow

    # 备份原 dist
    $BackupPath = "$GlobalInstallPath\dist.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    if (Test-Path "$GlobalInstallPath\dist") {
        Write-Host "  备份原 dist 目录..." -ForegroundColor Yellow
        Move-Item -Path "$GlobalInstallPath\dist" -Destination $BackupPath -Force
        Write-Host "  ✓ 备份完成: $BackupPath" -ForegroundColor Green
    }

    # 复制新 dist
    Copy-Item -Path "dist" -Destination $GlobalInstallPath -Recurse -Force
    Write-Host "  ✓ 全局目录覆盖完成" -ForegroundColor Green
} else {
    Write-Host "  全局安装目录不存在，跳过覆盖" -ForegroundColor Yellow
    Write-Host "  本地编译已完成，dist 目录: $ProjectRoot\dist" -ForegroundColor Cyan
}

# ============================
# 完成
# ============================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 修补完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "全局安装目录: $GlobalInstallPath" -ForegroundColor White
if (Test-Path $GlobalInstallPath) {
    Write-Host "请重启 hermes-web-ui 以应用更改:" -ForegroundColor Yellow
    Write-Host "  hermes gateway restart" -ForegroundColor Cyan
}
Write-Host ""
