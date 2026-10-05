$ErrorActionPreference = 'Stop'

$project = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $project

$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
$env:ANDROID_HOME = 'C:\Android\Sdk'
$env:ANDROID_SDK_ROOT = 'C:\Android\Sdk'
$env:SOFSON_ANDROID_BUILD = '1'

if (!(Test-Path "$env:JAVA_HOME\bin\java.exe")) {
  throw "JDK 21 not found at $env:JAVA_HOME"
}
if (!(Test-Path "$env:ANDROID_HOME\platforms\android-36\android.jar")) {
  throw "Android SDK API 36 not found at $env:ANDROID_HOME"
}

Write-Host "[Sofson Android] Project: $project"
Write-Host "[Sofson Android] Java: $env:JAVA_HOME"
Write-Host "[Sofson Android] Android SDK: $env:ANDROID_HOME"
Write-Host "[Sofson Android] Building same-DEV Android APK..."

Write-Host "[Sofson Android] Cleaning stale web output..."
# Do NOT recursively delete android\app\build or Capacitor's generated assets here.
# Windows can report DirectoryNotFoundException when Gradle/AVD/Defender touches
# a deeply nested file while Remove-Item is walking the tree. Gradle clean below
# owns the Android build directory.
foreach ($p in @('www', '.next')) {
  if (Test-Path -LiteralPath $p) {
    try {
      Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
      Write-Host "[Sofson Android] Removed $p"
    } catch {
      Write-Warning "Could not fully remove $p; continuing because the build regenerates it: $($_.Exception.Message)"
    }
  }
}


Write-Host "[Sofson Android] Checking Android native build tools..."
$sdkmanager = Join-Path $env:ANDROID_HOME 'cmdline-tools\latest\bin\sdkmanager.bat'
if (!(Test-Path $sdkmanager)) { $sdkmanager = Join-Path $env:ANDROID_HOME 'cmdline-tools\bin\sdkmanager.bat' }

# @capawesome/capacitor-nodejs 0.1.1 currently selects this NDK for its
# Android native build. A partially-created directory without source.properties
# causes CXX1101 before the app module is even configured. Repair that exact
# installation instead of installing a different NDK and hoping Gradle switches.
$requiredNdk = '27.0.12077973'
$ndkPath = Join-Path $env:ANDROID_HOME "ndk\$requiredNdk"
$sourceProperties = Join-Path $ndkPath 'source.properties'

if (Test-Path $ndkPath) {
  if (!(Test-Path $sourceProperties)) {
    Write-Warning "[Sofson Android] Corrupt/incomplete NDK detected: $ndkPath"
    Write-Host "[Sofson Android] Removing incomplete NDK so sdkmanager can reinstall it..."
    try {
      Remove-Item -LiteralPath $ndkPath -Recurse -Force -ErrorAction Stop
    } catch {
      throw "Cannot remove incomplete NDK $ndkPath. Close Android/Gradle processes and retry. $($_.Exception.Message)"
    }
  }
}

if (!(Test-Path $sdkmanager)) {
  throw "sdkmanager.bat not found. Install Android Command-line Tools; required NDK $requiredNdk cannot be repaired automatically."
}

& $sdkmanager "platforms;android-36" "build-tools;36.0.0" "cmake;3.22.1" "ndk;$requiredNdk"
if ($LASTEXITCODE -ne 0) { throw "Android SDK native tool installation failed" }

if (!(Test-Path $sourceProperties)) {
  throw "NDK installation is incomplete: $sourceProperties is missing."
}

Write-Host "[Sofson Android] Verified NDK $requiredNdk"

Write-Host "[Sofson Android] Installing/repairing npm dependencies..."
npm install --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { throw "npm install failed" }

$nodePluginGradle = Join-Path $project 'node_modules\@capawesome\capacitor-nodejs\android\build.gradle'
if (!(Test-Path $nodePluginGradle)) {
  throw "Capawesome Node.js Android Gradle module is missing: $nodePluginGradle"
}
$pluginGradleText = Get-Content -LiteralPath $nodePluginGradle -Raw
if ($pluginGradleText -match '27\.0\.12077973') {
  Write-Host "[Sofson Android] Capawesome Node.js plugin requires NDK 27.0.12077973"
} else {
  Write-Host "[Sofson Android] Capawesome Node.js plugin NDK requirement is handled by its Gradle build."
}

Write-Host "[Sofson Android] Removing stale APK..."
$apk = Join-Path $project 'android\app\build\outputs\apk\debug\app-debug.apk'
if (Test-Path -LiteralPath $apk) { Remove-Item -LiteralPath $apk -Force -ErrorAction SilentlyContinue }

Write-Host "[Sofson Android] Building APK..."
npm run android:real
if ($LASTEXITCODE -ne 0) { throw "Gradle APK build failed (exit code $LASTEXITCODE). No APK was produced." }

$apk = Join-Path $project 'android\app\build\outputs\apk\debug\app-debug.apk'
if (!(Test-Path $apk)) {
  throw "Build reported success but APK was not found: $apk"
}

Write-Host ""
Write-Host "==============================================="
Write-Host "Sofson APK READY"
Write-Host $apk
Write-Host "==============================================="
