# Horror Mod Analyzer - PowerShell Script
# Author: Daanii06_
# scans minecraft mods for shady stuff and checks em against known mod databases

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

$Banner = @"

██╗  ██╗ ██████╗ ██████╗ ██████╗  ██████╗ ██████╗     ███╗   ███╗ ██████╗ ██████╗     
██║  ██║██╔═══██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗    ████╗ ████║██╔═══██╗██╔══██╗    
███████║██║   ██║██████╔╝██████╔╝██║   ██║██████╔╝    ██╔████╔██║██║   ██║██║  ██║    
██╔══██║██║   ██║██╔══██╗██╔══██╗██║   ██║██╔══██╗    ██║╚██╔╝██║██║   ██║██║  ██║    
██║  ██║╚██████╔╝██║  ██║██║  ██║╚██████╔╝██║  ██║    ██║ ╚═╝ ██║╚██████╔╝██████╔╝    
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝     ╚═╝ ╚═════╝ ╚═════╝     


 █████╗ ███╗   ██╗ █████╗ ██╗     ██╗   ██╗███████╗███████╗██████╗ 
██╔══██╗████╗  ██║██╔══██╗██║     ╚██╗ ██╔╝╚══███╔╝██╔════╝██╔══██╗
███████║██╔██╗ ██║███████║██║      ╚████╔╝   ███╔╝ █████╗  ██████╔╝
██╔══██║██║╚██╗██║██╔══██║██║       ╚██╔╝   ███╔╝  ██╔══╝  ██╔══██╗
██║  ██║██║ ╚████║██║  ██║███████╗   ██║   ███████╗███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚══════╝╚═╝  ╚═╝


                         \    /\
                          )  ( ')
                         (  /  )
                          \(__)|            Made ♥ by Daanii06_

"@

Write-Host $Banner -ForegroundColor Cyan
Write-Host "Made with" -ForegroundColor Gray -NoNewline
Write-Host "♥ " -ForegroundColor Red -NoNewline
Write-Host "by " -ForegroundColor Gray -NoNewline
Write-Host "Daanii06_" -ForegroundColor Cyan
Write-Host ""
Write-Host ("━" * 76) -ForegroundColor DarkCyan
Write-Host

# ask the user where their mods folder is
Write-Host "Enter path to the mods folder: " -NoNewline
Write-Host "(press Enter to use default)" -ForegroundColor DarkGray
$modsPath = Read-Host "PATH"
Write-Host

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "Continuing with " -NoNewline
    Write-Host $modsPath -ForegroundColor White
    Write-Host
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "❌ Invalid Path!" -ForegroundColor Red
    Write-Host "The directory does not exist or is not accessible." -ForegroundColor Yellow
    Write-Host
    Write-Host "Tried to access: $modsPath" -ForegroundColor Gray
    Write-Host
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "📁 Scanning directory: $modsPath" -ForegroundColor Green
Write-Host

# check if minecraft is already running
$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) {
    $mcProcess = Get-Process java -ErrorAction SilentlyContinue
}

if ($mcProcess) {
    try {
        $startTime = $mcProcess.StartTime
        $uptime = (Get-Date) - $startTime
        Write-Host "🕒 { Minecraft Uptime }" -ForegroundColor DarkCyan
        Write-Host "   $($mcProcess.Name) PID $($mcProcess.Id) started at $startTime" -ForegroundColor Gray
        Write-Host "   Running for: $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor Gray
        Write-Host ""
    } catch {
        # couldn't grab process info, no biggie
    }
}

function Get-FileSHA1 {
    param([string]$Path)
    return (Get-FileHash -Path $Path -Algorithm SHA1).Hash
}

function Get-DownloadSource {
    param([string]$Path)
    $zoneData = Get-Content -Raw -Stream Zone.Identifier $Path -ErrorAction SilentlyContinue
    if ($zoneData -match "HostUrl=(.+)") {
        $url = $matches[1].Trim()
        if ($url -match "mediafire\.com")                                        { return "MediaFire" }
        elseif ($url -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { return "Discord" }
        elseif ($url -match "dropbox\.com")                                      { return "Dropbox" }
        elseif ($url -match "drive\.google\.com")                                { return "Google Drive" }
        elseif ($url -match "mega\.nz|mega\.co\.nz")                             { return "MEGA" }
        elseif ($url -match "github\.com")                                       { return "GitHub" }
        elseif ($url -match "modrinth\.com")                                     { return "Modrinth" }
        elseif ($url -match "curseforge\.com")                                   { return "CurseForge" }
        elseif ($url -match "anydesk\.com")                                      { return "AnyDesk" }
        elseif ($url -match "doomsdayclient\.com")                               { return "DoomsdayClient" }
        elseif ($url -match "prestigeclient\.vip")                               { return "PrestigeClient" }
        elseif ($url -match "198macros\.com")                                    { return "198Macros" }
        else {
            if ($url -match "https?://(?:www\.)?([^/]+)") { return $matches[1] }
            return $url
        }
    }
    return $null
}

function Query-Modrinth {
    param([string]$Hash)
    try {
        $versionInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($versionInfo.project_id) {
            $projectInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($versionInfo.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $projectInfo.title; Slug = $projectInfo.slug }
        }
    } catch { }
    return @{ Name = ""; Slug = "" }
}

function Query-Megabase {
    param([string]$Hash)
    try {
        $result = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if (-not $result.error) { return $result.data }
    } catch { }
    return $null
}

# --- detection lists ---
# these two arrays feed into the same scan pass, no need to run things twice
#
# $suspiciousPatterns - matched against class/file names and text inside the jar
# $cheatStrings       - raw string search across bytecode
#
# note: i switched to word-boundary regex so stuff like "inject" (used by mixin @Inject)
# or "NoDelay" from some networking libs doesn't trip the scanner anymore.
# also pulled out "velocity" as a standalone since literally half of fabric uses that word.

$suspiciousPatterns = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "Hitboxes", "JumpReset", "LegitTotem", "PingSpoof", "SelfDestruct",
    "ShieldBreaker", "TriggerBot", "Velocity", "AxeSpam", "WebMacro",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod", "Reach",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag",
    "BlockESP", "dev.krypton", "Virgin", "AntiMissClick",
    "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "FastXP", "FastExp", "Refill", "NoJumpDelay", "AirAnchor",
    "jnativehook", "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework",
    "PackSpoof", "Antiknockback", "scrim", "catlean", "Argon",
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy",
    "Grim", "grim",
    "org.chainlibs.module.impl.modules.Crystal.Y",
    "org.chainlibs.module.impl.modules.Crystal.bF",
    "org.chainlibs.module.impl.modules.Crystal.bM",
    "org.chainlibs.module.impl.modules.Crystal.bY",
    "org.chainlibs.module.impl.modules.Crystal.bq",
    "org.chainlibs.module.impl.modules.Crystal.cv",
    "org.chainlibs.module.impl.modules.Crystal.o",
    "org.chainlibs.module.impl.modules.Blatant.I",
    "org.chainlibs.module.impl.modules.Blatant.bR",
    "org.chainlibs.module.impl.modules.Blatant.bx",
    "org.chainlibs.module.impl.modules.Blatant.cj",
    "org.chainlibs.module.impl.modules.Blatant.dk",
    "imgui", "imgui.gl3", "imgui.glfw",
    "BowAim", "Criticals", "Flight", "Fakenick", "FakeItem",
    "invsee", "ItemExploit", "Hellion", "hellion",
    "LicenseCheckMixin", "ClientPlayerInteractionManagerAccessor",
    "ClientPlayerEntityMixim", "dev.gambleclient", "obfuscatedAuth",
    "phantom-refmap.json", "xyz.greaj",
    "じ.class", "ふ.class", "ぶ.class", "ぷ.class", "た.class",
    "ね.class", "そ.class", "な.class", "ど.class", "ぐ.class",
    "ず.class", "で.class", "つ.class", "べ.class", "せ.class",
    "と.class", "み.class", "び.class", "す.class", "の.class"
)

$cheatStrings = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal",
    "dontPlaceCrystal", "dontBreakCrystal",
    "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer", "healPotSlot",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor",
    "hasGlowstone", "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "AutoTotem", "autototem", "auto totem", "InventoryTotem",
    "inventorytotem", "HoverTotem", "hover totem", "legittotem",
    "AutoPot", "autopot", "auto pot", "speedPotSlot", "strengthPotSlot",
    "AutoArmor", "autoarmor", "auto armor",
    "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "AutoDoubleHand", "autodoublehand", "auto double hand",
    "AutoClicker",
    "Failed to switch to mace after axe!",
    "Breaking shield with axe...",
    "Donut", "JumpReset", "axespam", "axe spam",
    "shieldbreaker", "shield breaker", "EndCrystalItemMixin",
    "findKnockbackSword", "attackRegisteredThisClick",
    "AimAssist", "aimassist", "aim assist",
    "triggerbot", "trigger bot",
    "FakeInv", "Friends", "swapBackToOriginalSlot",
    "FakeLag", "pingspoof", "ping spoof", "velocity",
    "webmacro", "web macro",
    "lvstrng", "dqrkis", "selfdestruct", "self destruct",
    "AutoMace", "AutoFirework", "MaceSwap", "AirAnchor",
    "ElytraSwap", "FastXP", "FastExp", "NoJumpDelay",
    "PackSpoof", "Antiknockback", "scrim", "catlean",
    "AuthBypass", "obfuscatedAuth", "LicenseCheckMixin",
    "BaseFinder", "invsee", "ItemExploit",
    "NoFall", "nofall",
    "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer"
)

# single pass scan — runs pattern matching and raw string search together
# no reason to loop through the jars twice
#
# word boundary trick: (?<![A-Za-z])TOKEN(?![A-Za-z])
# keeps things like "AimAssist" from matching inside some random unrelated class name
# also "velocity" gets special treatment since it's way too generic on its own

function Invoke-ModScan {
    param([string]$FilePath)

    $foundPatterns = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings  = [System.Collections.Generic.HashSet[string]]::new()

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # check entry names + readable text inside the jar
    try {
        $patternRegex = [regex]::new(
            '(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])',
            [System.Text.RegularExpressions.RegexOptions]::Compiled
        )
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        foreach ($entry in $archive.Entries) {
            foreach ($m in $patternRegex.Matches($entry.FullName)) { [void]$foundPatterns.Add($m.Value) }
            if ($entry.FullName -match '\.(class|json)$' -or $entry.FullName -match 'MANIFEST\.MF') {
                try {
                    $stream  = $entry.Open()
                    $reader  = New-Object System.IO.StreamReader($stream)
                    $content = $reader.ReadToEnd()
                    $reader.Close(); $stream.Close()
                    foreach ($m in $patternRegex.Matches($content)) { [void]$foundPatterns.Add($m.Value) }
                } catch { }
            }
        }
        $archive.Dispose()
    } catch { }

    # raw bytecode string search
    # tries strings.exe first (faster), falls back to reading bytes directly
    try {
        $stringsExe = @(
            "C:\Program Files\Git\usr\bin\strings.exe",
            "C:\Program Files\Git\mingw64\bin\strings.exe",
            "$env:ProgramFiles\Git\usr\bin\strings.exe",
            "C:\msys64\usr\bin\strings.exe",
            "C:\cygwin64\bin\strings.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($stringsExe) {
            $tmp = Join-Path $env:TEMP "meow_str_$(Get-Random).txt"
            & $stringsExe $FilePath 2>$null | Out-File $tmp -Encoding UTF8
            if (Test-Path $tmp) {
                $raw = Get-Content $tmp -Raw
                Remove-Item $tmp -Force -ErrorAction SilentlyContinue
                foreach ($s in $cheatStrings) {
                    if ($s -eq "velocity") {
                        if ($raw -match "velocity(?:hack|module|cheat|bypass|packet|horizontal|vertical|amount|factor|setting)") {
                            [void]$foundStrings.Add($s)
                        }
                    } elseif ($raw -match [regex]::Escape($s)) {
                        [void]$foundStrings.Add($s)
                    }
                }
            }
        } else {
            # fallback: read raw ASCII bytes from the whole file
            $rawText = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($FilePath))
            foreach ($s in $cheatStrings) {
                if ($s -eq "velocity") {
                    if ($rawText -match "velocity(?:hack|module|cheat|bypass|packet|horizontal|vertical|amount|factor|setting)") {
                        [void]$foundStrings.Add($s)
                    }
                } elseif ($rawText -match [regex]::Escape($s)) {
                    [void]$foundStrings.Add($s)
                }
            }
            # also scan individual .class entries — catches non-ASCII paths
            try {
                $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
                foreach ($entry in ($zip.Entries | Where-Object { $_.Name -like "*.class" })) {
                    try {
                        $stream    = $entry.Open()
                        $reader    = New-Object System.IO.StreamReader($stream)
                        $classText = $reader.ReadToEnd()
                        $reader.Close(); $stream.Close()
                        foreach ($s in $cheatStrings) {
                            if ($s -eq "velocity") {
                                if ($classText -match "velocity(?:hack|module|cheat|bypass|packet|horizontal|vertical|amount|factor|setting)") {
                                    [void]$foundStrings.Add($s)
                                }
                            } elseif ($classText -match [regex]::Escape($s)) {
                                [void]$foundStrings.Add($s)
                            }
                        }
                    } catch { }
                }
                $zip.Dispose()
            } catch { }
        }
    } catch { }

    return @{ Patterns = $foundPatterns; Strings = $foundStrings }
}

$verifiedMods   = @()
$unknownMods    = @()
$suspiciousMods = @()

try {
    $jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction Stop
} catch {
    Write-Host "❌ Error accessing directory: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

if ($jarFiles.Count -eq 0) {
    Write-Host "⚠️  No JAR files found in: $modsPath" -ForegroundColor Yellow
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

$fileWord = if ($jarFiles.Count -eq 1) { "file" } else { "files" }
Write-Host "🔍 Found $($jarFiles.Count) JAR $fileWord to analyze" -ForegroundColor Green
Write-Host

$spinnerFrames = @("⣾","⣽","⣻","⢿","⡿","⣟","⣯","⣷")
$totalFiles    = $jarFiles.Count
$idx           = 0

# pass 1 - hash lookup against modrinth and megabase
foreach ($jar in $jarFiles) {
    $idx++
    $spinner = $spinnerFrames[$idx % $spinnerFrames.Length]
    Write-Host "`r[$spinner] Verifying: $idx/$totalFiles - $($jar.Name)" -ForegroundColor Yellow -NoNewline

    $hash = Get-FileSHA1 -Path $jar.FullName

    if ($hash) {
        $modrinthData = Query-Modrinth -Hash $hash
        if ($modrinthData.Slug) {
            $verifiedMods += [PSCustomObject]@{ ModName = $modrinthData.Name; FileName = $jar.Name; FilePath = $jar.FullName }
            continue
        }
        $megabaseData = Query-Megabase -Hash $hash
        if ($megabaseData.name) {
            $verifiedMods += [PSCustomObject]@{ ModName = $megabaseData.Name; FileName = $jar.Name; FilePath = $jar.FullName }
            continue
        }
    }

    $src = Get-DownloadSource $jar.FullName
    $unknownMods += [PSCustomObject]@{ FileName = $jar.Name; FilePath = $jar.FullName; DownloadSource = $src }
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

# pass 2 - deep scan every jar for cheat patterns and strings
# runs on ALL mods, even verified ones — injected code can hide inside a legit wrapper
$modWord = if ($totalFiles -eq 1) { "mod" } else { "mods" }
Write-Host "🔬 Deep-scanning all $totalFiles $modWord..." -ForegroundColor Cyan
$idx = 0

foreach ($jar in $jarFiles) {
    $idx++
    $spinner = $spinnerFrames[$idx % $spinnerFrames.Length]
    Write-Host "`r[$spinner] Scanning: $idx/$totalFiles - $($jar.Name)" -ForegroundColor Yellow -NoNewline

    $result = Invoke-ModScan -FilePath $jar.FullName

    if ($result.Patterns.Count -gt 0 -or $result.Strings.Count -gt 0) {
        $suspiciousMods += [PSCustomObject]@{
            FileName = $jar.Name
            Patterns = $result.Patterns
            Strings  = $result.Strings
        }
        # if it got flagged it's not verified anymore
        $verifiedMods = $verifiedMods | Where-Object { $_.FileName -ne $jar.Name }
    }
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

# --- results ---
Write-Host "`n" + ("━" * 76) -ForegroundColor DarkCyan

if ($verifiedMods.Count -gt 0) {
    Write-Host "✅ VERIFIED MODS ($($verifiedMods.Count))" -ForegroundColor Green
    Write-Host ("─" * 76) -ForegroundColor DarkGray
    foreach ($mod in $verifiedMods) {
        Write-Host "  ✓ " -ForegroundColor Green -NoNewline
        Write-Host "$($mod.ModName)" -ForegroundColor White -NoNewline
        Write-Host " → " -ForegroundColor Gray -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

if ($unknownMods.Count -gt 0) {
    Write-Host "❓ UNKNOWN MODS ($($unknownMods.Count))" -ForegroundColor Yellow
    Write-Host ("─" * 76) -ForegroundColor DarkGray
    foreach ($mod in $unknownMods) {
        $name = $mod.FileName
        if ($name.Length -gt 50) { $name = $name.Substring(0,47) + "..." }
        $topLine    = "  ╔═ ? " + $name + " " + ("═" * (65 - $name.Length)) + "╗"
        $sourceText = if ($mod.DownloadSource) { "Source: $($mod.DownloadSource)" } else { "Source: ?" }
        $bottomLine = "  ╚═ " + $sourceText + " " + ("═" * (67 - $sourceText.Length)) + "╝"
        Write-Host $topLine    -ForegroundColor Yellow
        Write-Host $bottomLine -ForegroundColor Yellow
        Write-Host ""
    }
}

if ($suspiciousMods.Count -gt 0) {
    Write-Host "🚨 SUSPICIOUS MODS ($($suspiciousMods.Count))" -ForegroundColor Red
    Write-Host ("─" * 76) -ForegroundColor DarkGray
    Write-Host ""
    foreach ($mod in $suspiciousMods) {
        Write-Host "  ╔═══ " -ForegroundColor Red -NoNewline
        Write-Host "FLAGGED" -ForegroundColor White -BackgroundColor Red -NoNewline
        Write-Host " ═══════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "  ║" -ForegroundColor Red
        Write-Host "  ║  File: " -ForegroundColor Red -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor Yellow

        if ($mod.Patterns.Count -gt 0) {
            Write-Host "  ║" -ForegroundColor Red
            Write-Host "  ║  Detected Patterns:" -ForegroundColor Red
            foreach ($p in ($mod.Patterns | Sort-Object)) {
                Write-Host "  ║    • " -ForegroundColor Red -NoNewline
                Write-Host "$p" -ForegroundColor White
            }
        }

        $uniqueStrings = $mod.Strings | Where-Object { $mod.Patterns -notcontains $_ } | Sort-Object
        if ($uniqueStrings.Count -gt 0) {
            Write-Host "  ║" -ForegroundColor Red
            Write-Host "  ║  Detected Strings:" -ForegroundColor DarkYellow
            foreach ($s in $uniqueStrings) {
                Write-Host "  ║    • " -ForegroundColor DarkYellow -NoNewline
                Write-Host "$s" -ForegroundColor DarkYellow
            }
        }

        Write-Host "  ║" -ForegroundColor Red
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host "📊 SUMMARY" -ForegroundColor Cyan
Write-Host ("━" * 76) -ForegroundColor Blue
Write-Host "  Total files scanned: " -ForegroundColor Gray -NoNewline; Write-Host "$totalFiles"              -ForegroundColor White
Write-Host "  Verified mods:       " -ForegroundColor Gray -NoNewline; Write-Host "$($verifiedMods.Count)"   -ForegroundColor Green
Write-Host "  Unknown mods:        " -ForegroundColor Gray -NoNewline; Write-Host "$($unknownMods.Count)"    -ForegroundColor Yellow
Write-Host "  Suspicious mods:     " -ForegroundColor Gray -NoNewline; Write-Host "$($suspiciousMods.Count)" -ForegroundColor Red
Write-Host
Write-Host ("━" * 76) -ForegroundColor Blue
Write-Host ""
Write-Host "  ✨ Analysis complete! Thanks for using Meow Mod Analyzer 🐱" -ForegroundColor Cyan
Write-Host ""
Write-Host "  👤 Created by: " -ForegroundColor White -NoNewline
Write-Host "🌟 " -ForegroundColor Cyan -NoNewline
Write-Host "Tonynoh" -ForegroundColor Cyan
Write-Host "  📱 My Socials: " -ForegroundColor White -NoNewline
Write-Host "💬 " -ForegroundColor Blue -NoNewline
Write-Host "Discord  : " -ForegroundColor Blue -NoNewline
Write-Host "tonyboy90_" -ForegroundColor Blue
Write-Host "                 " -NoNewline
Write-Host "🔗 " -ForegroundColor DarkGray -NoNewline
Write-Host "GitHub   : " -ForegroundColor DarkGray -NoNewline
Write-Host "https://github.com/MeowTonynoh" -ForegroundColor DarkGray
Write-Host "                 " -NoNewline
Write-Host "🎥 " -ForegroundColor Red -NoNewline
Write-Host "YouTube  : " -ForegroundColor Red -NoNewline
Write-Host "tonynoh-07" -ForegroundColor Red
Write-Host ""
Write-Host ("━" * 76) -ForegroundColor Blue
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
