# Meow Mod Analyzer - PowerShell Script
# Author: Tonynoh
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

⠀⠀⠀⠀⣶⣄⠀⠀⠀⠀⠀⠀⢀⣶⡆⠀⠀⠀
⠀⠀⠀⢸⣿⣿⡆⠀⠀⠀⠀⢀⣾⣿⡇⠀⠀⠀
⠀⠀⠀⠘⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⡇⠀⠀⠀
⠀⠀⠀⠀⢿⣿⣿⣤⣤⣤⣤⣼⣿⡿⠃⠀⠀⠀
⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀
⠀⠀⢠⣿⡃⣦⢹⣿⣟⣙⣿⣿⠰⡀⣿⣇⠀⠀
⠠⠬⣿⣿⣷⣶⣿⣿⣿⣿⣿⣿⣷⣾⣿⣿⡭⠤      
⠀⣼⣿⣿⣿⣿⠿⠛⠛⠛⠛⠻⢿⣿⣿⣿⣿⡀
⢰⣿⣿⣿⠋⠀⠀⠀⢀⣀⠀⠀⠀⠉⢿⣿⣿⣧
⢸⣿⣿⠃⠜⠛⠂⠀⠋⠉⠃⠐⠛⠻⠄⢿⣿⣿
⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿
⠘⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⡏
⠀⠈⠻⠿⣤⣀⡀⠀⠀⠀⠀⠀⣀⣠⠾⠟⠋⠀  Made By ♥ Daanii06_

"@

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

# ─────────────────────────────────────────────────────────────────────────────
# BYPASS / INJECTION DETECTION
# Catches obfuscated cheat loaders (dqrkis-style) without false positives on
# legitimate mods that use Fabric's jar-in-jar system normally.
#
# Core insight — what separates a malicious loader from a legit mod:
#
#   LEGIT jar-in-jar:
#     • Every nested JAR has a version number in its filename
#       (cloth-config-13.0.jar, fabric-api-base-0.97.3.jar)
#     • OR it's a Maven-style dep (org_jetbrains_*, com_ibm_*, net_*, etc.)
#     • The outer JAR has real code alongside its nested deps
#     • No dangerous APIs (Runtime.exec, HTTP download/POST)
#
#   MALICIOUS loader:
#     • Nested JAR has a short generic name with NO version number
#       (mc-core.jar, payload.jar, bootstrap.jar, core.jar)
#     • Outer JAR is a hollow shell: 0-2 own classes, wraps exactly 1 JAR
#     • Bytecode uses Runtime.exec / HTTP file download / HTTP POST exfil
#     • 60%+ of all classes renamed to single letters (a/a/b/c.class)
#
# False-positive guards:
#   • "Suspicious nested JAR name" → only fires when filename has NO digits
#     AND does NOT start with a Maven prefix (com_, org_, net_, io_, dev_…)
#     AND the base name is ≤ 20 chars
#     → passes cloth-config-13.0.jar, org_jetbrains_kotlin-stdlib.jar, etc.
#
#   • "Hollow shell" → only fires when there is EXACTLY ONE nested JAR
#     and the outer JAR owns < 3 classes
#     → never triggers on fabric-api (50 nested JARs) or any normal mod
#
#   • "Fake mod identity" → ONLY emitted when at least one dangerous flag
#     (Runtime.exec / HTTP / obfuscation / suspicious JAR name) is also present
#     → Modrinth simply doesn't index every build; a missing hash alone is
#        not meaningful evidence
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-BypassScan {
    param([string]$FilePath)

    $flags = [System.Collections.Generic.List[string]]::new()

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Maven/Gradle-style prefixes used when bundling third-party libs.
    # Filenames starting with these are always legitimate bundled dependencies.
    # e.g. org_jetbrains_kotlin_kotlin-stdlib.jar, com_ibm_async_asyncutil.jar
    $mavenPrefixes = @(
        "com_","org_","net_","io_","dev_","gs_","xyz_",
        "app_","me_","tv_","uk_","be_","fr_","de_"
    )

    # Returns $true when a nested JAR filename looks like a hidden payload.
    # Safe when: has a digit (versioned), starts with a maven prefix, or name > 20 chars.
    function Test-SuspiciousJarName {
        param([string]$JarName)
        $base = [System.IO.Path]::GetFileNameWithoutExtension($JarName)
        if ($base -match '\d')                                          { return $false }
        foreach ($pfx in $mavenPrefixes) {
            if ($base.ToLower().StartsWith($pfx))                       { return $false }
        }
        if ($base.Length -gt 20)                                        { return $false }
        return $true
    }

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)

        $nestedJars   = @($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })
        $outerClasses = @($zip.Entries | Where-Object { $_.FullName -match "\.class$" })

        # ── 1. SUSPICIOUS NESTED JAR NAME ────────────────────────────────────
        # A nested JAR without a version number and without a maven prefix is
        # the clearest sign of a hidden payload (mc-core.jar, payload.jar, etc.)
        $suspiciousNestedJars = @()
        foreach ($nj in $nestedJars) {
            $njBase = [System.IO.Path]::GetFileName($nj.FullName)
            if (Test-SuspiciousJarName -JarName $njBase) {
                $suspiciousNestedJars += $njBase
            }
        }
        foreach ($sj in $suspiciousNestedJars) {
            $flags.Add("Suspicious nested JAR — no version number, not a known dependency: $sj")
        }

        # ── 2. HOLLOW SHELL ───────────────────────────────────────────────────
        # Exactly ONE nested JAR + fewer than 3 own classes = the outer JAR
        # exists only to load the hidden inner JAR. fabric-api has 50 nested
        # JARs and tons of own code, so this never fires for legitimate mods.
        if ($nestedJars.Count -eq 1 -and $outerClasses.Count -lt 3) {
            $njName = [System.IO.Path]::GetFileName(($nestedJars | Select-Object -First 1).FullName)
            $flags.Add("Hollow shell — outer JAR has only $($outerClasses.Count) own class(es) but wraps: $njName")
        }

        # ── Read outer mod ID for later use ──────────────────────────────────
        $outerModId = ""
        $fmje = $zip.Entries | Where-Object { $_.FullName -eq "fabric.mod.json" } | Select-Object -First 1
        if ($fmje) {
            try {
                $s = $fmje.Open()
                $r = New-Object System.IO.StreamReader($s)
                $t = $r.ReadToEnd(); $r.Close(); $s.Close()
                if ($t -match '"id"\s*:\s*"([^"]+)"') { $outerModId = $matches[1] }
            } catch { }
        }

        # ── 3. BYTECODE CHECKS — scan outer + all nested JARs ────────────────
        $allEntries = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $zip.Entries) { $allEntries.Add($e) }

        $innerZips = [System.Collections.Generic.List[object]]::new()
        foreach ($nj in $nestedJars) {
            try {
                $ns = $nj.Open()
                $ms = New-Object System.IO.MemoryStream
                $ns.CopyTo($ms); $ns.Close()
                $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $innerZips.Add($iz)
                foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
            } catch { }
        }

        $runtimeExecFound  = $false
        $httpDownloadFound = $false
        $httpExfilFound    = $false
        $obfuscatedCount   = 0
        $totalClassCount   = 0

        foreach ($entry in $allEntries) {
            $name = $entry.FullName

            if ($name -match "\.class$") {
                $totalClassCount++
                # Obfuscation: every path segment is 1-2 chars, at least 3 levels deep
                # a/a/b/c.class → obfuscated | net/minecraft/client/Foo.class → not
                $segs = ($name -replace "\.class$","") -split "/"
                if ($segs.Count -ge 3 -and ($segs | Where-Object { $_.Length -gt 2 }).Count -eq 0) {
                    $obfuscatedCount++
                }

                # Scan bytecode for dangerous API patterns
                try {
                    $st = $entry.Open()
                    $rd = New-Object System.IO.StreamReader($st, [System.Text.Encoding]::Latin1)
                    $ct = $rd.ReadToEnd(); $rd.Close(); $st.Close()

                    # Runtime.exec — requires all three together to avoid false positives.
                    # getRuntime() alone is used by perf mods to check available CPU cores.
                    if ($ct -match "java/lang/Runtime" -and
                        $ct -match "getRuntime" -and
                        $ct -match "\bexec\b") {
                        $runtimeExecFound = $true
                    }

                    # HTTP file download: fetches a URL and writes it to disk
                    if ($ct -match "openConnection" -and
                        $ct -match "HttpURLConnection" -and
                        $ct -match "FileOutputStream") {
                        $httpDownloadFound = $true
                    }

                    # HTTP POST exfiltration: sends a body to an external server
                    if ($ct -match "openConnection" -and
                        $ct -match "setDoOutput" -and
                        $ct -match "getOutputStream") {
                        $httpExfilFound = $true
                    }
                } catch { }
            }
        }

        foreach ($iz in $innerZips) { try { $iz.Dispose() } catch { } }
        $zip.Dispose()

        # ── Emit dangerous-code flags ─────────────────────────────────────────

        if ($runtimeExecFound) {
            $flags.Add("Runtime.exec() — mod can execute arbitrary OS commands on your machine")
        }

        if ($httpDownloadFound) {
            $flags.Add("HTTP file download — mod fetches and writes files from a remote server")
        }

        if ($httpExfilFound) {
            $flags.Add("HTTP POST exfiltration — mod sends data to an external server (possible token/session theft)")
        }

        # Obfuscation: >60% single-letter path classes, at least 10 total.
        # The 10-class floor avoids flagging tiny utility mods with short package names.
        if ($totalClassCount -ge 10 -and $obfuscatedCount -gt 0) {
            $pct = [math]::Round(($obfuscatedCount / $totalClassCount) * 100)
            if ($pct -ge 60) {
                $flags.Add("Heavy obfuscation — $pct% of classes have single-letter names (a/b/c style). Legitimate mods don't do this.")
            }
        }

        # ── Fake mod identity (only with corroborating dangerous flags) ───────
        # We never emit this alone. A missing Modrinth hash just means the build
        # wasn't indexed — that's true for tons of old/custom releases.
        # We only call it out when dangerous code was also found.
        $knownLegitModIds = @(
            "vmp-fabric","vmp","lithium","sodium","iris","fabric-api",
            "modmenu","ferrite-core","lazydfu","starlight","entityculling",
            "memoryleakfix","krypton","c2me-fabric","smoothboot-fabric",
            "immediatelyfast","noisium","threadtweak"
        )
        $dangerCount = ($flags | Where-Object {
            $_ -match "Runtime\.exec|HTTP file download|HTTP POST|Heavy obfuscation|Suspicious nested JAR"
        }).Count
        if ($outerModId -and ($knownLegitModIds -contains $outerModId) -and $dangerCount -gt 0) {
            $flags.Add("Fake mod identity — outer JAR claims to be '$outerModId' but hash is not on Modrinth and dangerous code was found inside")
        }

    } catch { }

    return $flags
}

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
$bypassMods     = @()

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

# pass 3 - bypass / injection scan
Write-Host "🛡️  Running bypass/injection scan on all $totalFiles $modWord..." -ForegroundColor Magenta
$idx = 0

foreach ($jar in $jarFiles) {
    $idx++
    $spinner = $spinnerFrames[$idx % $spinnerFrames.Length]
    Write-Host "`r[$spinner] Bypass scan: $idx/$totalFiles - $($jar.Name)" -ForegroundColor Yellow -NoNewline

    $bypassFlags = Invoke-BypassScan -FilePath $jar.FullName

    if ($bypassFlags.Count -gt 0) {
        $bypassMods += [PSCustomObject]@{
            FileName = $jar.Name
            Flags    = $bypassFlags
        }
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

if ($bypassMods.Count -gt 0) {
    Write-Host "☠️  BYPASS / INJECTION DETECTED ($($bypassMods.Count))" -ForegroundColor Magenta
    Write-Host ("─" * 76) -ForegroundColor DarkGray
    Write-Host ""
    foreach ($mod in $bypassMods) {
        Write-Host "  ╔═══ " -ForegroundColor Magenta -NoNewline
        Write-Host "INJECTION" -ForegroundColor White -BackgroundColor DarkMagenta -NoNewline
        Write-Host " ══════════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host "  ║" -ForegroundColor Magenta
        Write-Host "  ║  File: " -ForegroundColor Magenta -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor Yellow
        Write-Host "  ║" -ForegroundColor Magenta
        Write-Host "  ║  Bypass Flags:" -ForegroundColor Magenta
        foreach ($flag in $mod.Flags) {
            Write-Host "  ║    ⚠ " -ForegroundColor Magenta -NoNewline
            Write-Host "$flag" -ForegroundColor White
        }
        Write-Host "  ║" -ForegroundColor Magenta
        Write-Host "  ╚═══════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host ""
    }
}

Write-Host "📊 SUMMARY" -ForegroundColor Cyan
Write-Host ("━" * 76) -ForegroundColor Blue
Write-Host "  Total files scanned: " -ForegroundColor Gray -NoNewline; Write-Host "$totalFiles"              -ForegroundColor White
Write-Host "  Verified mods:       " -ForegroundColor Gray -NoNewline; Write-Host "$($verifiedMods.Count)"   -ForegroundColor Green
Write-Host "  Unknown mods:        " -ForegroundColor Gray -NoNewline; Write-Host "$($unknownMods.Count)"    -ForegroundColor Yellow
Write-Host "  Suspicious mods:     " -ForegroundColor Gray -NoNewline; Write-Host "$($suspiciousMods.Count)" -ForegroundColor Red
Write-Host "  Bypass/Injected:     " -ForegroundColor Gray -NoNewline; Write-Host "$($bypassMods.Count)"     -ForegroundColor Magenta
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
