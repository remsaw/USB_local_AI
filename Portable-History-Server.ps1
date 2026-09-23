param(
    [string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [int]$Port = 8765
)

# Normalize Root path
if (-not [string]::IsNullOrWhiteSpace($Root)) {
    $Root = $Root.Trim().Trim('"', '''').TrimEnd('\', '/')
}
if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$ErrorActionPreference = 'Stop'
$dataDir = Join-Path $Root 'Data'
$dataFile = Join-Path $dataDir 'conversations.json'
$uploadsDir = Join-Path $dataDir 'uploads'

New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
New-Item -ItemType Directory -Force -Path $uploadsDir | Out-Null

# Clean up any previous listener on the same port
try {
    $conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($conns) {
        foreach ($c in $conns) {
            if ($c.OwningProcess -and $c.OwningProcess -ne $PID) {
                Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
            }
        }
        Start-Sleep -Milliseconds 300
    }
} catch {}

function Read-Data {
    if (-not (Test-Path -LiteralPath $dataFile)) {
        return [pscustomobject]@{ version = 1; updated = 0; conversations = @(); messages = @() }
    }
    try {
        $raw = [System.IO.File]::ReadAllText($dataFile, [System.Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($raw)) { throw 'empty' }
        $d = $raw | ConvertFrom-Json
        if ($null -eq $d.conversations) { $d | Add-Member -NotePropertyName conversations -NotePropertyValue @() -Force }
        if ($null -eq $d.messages) { $d | Add-Member -NotePropertyName messages -NotePropertyValue @() -Force }
        return $d
    } catch {
        return [pscustomobject]@{ version = 1; updated = 0; conversations = @(); messages = @() }
    }
}

function Save-Data($data) {
    $tmp = "$dataFile.tmp"
    $json = $data | ConvertTo-Json -Depth 100 -Compress
    [System.IO.File]::WriteAllText($tmp, $json, [System.Text.Encoding]::UTF8)
    Move-Item -Force -LiteralPath $tmp -Destination $dataFile
}

function To-Array($x) {
    if ($null -eq $x) { return ,@() }
    if ($x -is [System.Collections.IEnumerable] -and -not ($x -is [string])) { return ,@($x) }
    return ,@($x)
}

function Save-MessageAttachments($messages) {
    if ($null -eq $messages) { return }
    foreach ($msg in (To-Array $messages)) {
        if ($null -eq $msg.extra) { continue }
        foreach ($item in (To-Array $msg.extra)) {
            if ($null -eq $item) { continue }
            try {
                $rawName = $item.name
                if ([string]::IsNullOrWhiteSpace($rawName)) {
                    $ext = if ($item.type -eq 'image') { '.png' } elseif ($item.type -eq 'pdf') { '.pdf' } else { '.bin' }
                    $rawName = "attachment_$(Get-Random)$ext"
                }
                $safeName = [System.IO.Path]::GetFileName($rawName) -replace '[\\/:*?"<>|]', '_'
                $dest = Join-Path $uploadsDir $safeName

                # Handle images with base64Url (data:image/...;base64,...)
                if ($item.type -eq 'image' -and -not [string]::IsNullOrWhiteSpace($item.base64Url)) {
                    $idx = $item.base64Url.IndexOf(';base64,')
                    if ($idx -ge 0) {
                        $b64 = $item.base64Url.Substring($idx + 8)
                        $bytes = [Convert]::FromBase64String($b64)
                        if (-not (Test-Path -LiteralPath $dest) -or (Get-Item -LiteralPath $dest).Length -ne $bytes.Length) {
                            [System.IO.File]::WriteAllBytes($dest, $bytes)
                        }
                    }
                }
                # Handle binary audio, video, or PDF with base64Data
                elseif (-not [string]::IsNullOrWhiteSpace($item.base64Data)) {
                    $bytes = [Convert]::FromBase64String($item.base64Data)
                    if (-not (Test-Path -LiteralPath $dest) -or (Get-Item -LiteralPath $dest).Length -ne $bytes.Length) {
                        [System.IO.File]::WriteAllBytes($dest, $bytes)
                    }
                }
                # Handle text attachments
                elseif ($item.type -eq 'text' -and -not [string]::IsNullOrWhiteSpace($item.content)) {
                    if (-not (Test-Path -LiteralPath $dest)) {
                        [System.IO.File]::WriteAllText($dest, $item.content, [System.Text.Encoding]::UTF8)
                    }
                }
            } catch {
                # Ignore individual file save failures to keep sync resilient
            }
        }
    }
}

function Merge-Records($serverRecords, $clientRecords, $type) {
    $map = @{}
    foreach ($r in (To-Array $serverRecords)) {
        if ($null -ne $r.id) { $map[[string]$r.id] = $r }
    }
    foreach ($r in (To-Array $clientRecords)) {
        if ($null -eq $r.id) { continue }
        $id = [string]$r.id
        if (-not $map.ContainsKey($id)) {
            $map[$id] = $r
            continue
        }
        $old = $map[$id]
        if ($type -eq 'conversation') {
            $ot = [int64]($old.lastModified | ForEach-Object { $_ })
            $nt = [int64]($r.lastModified | ForEach-Object { $_ })
            if ($nt -ge $ot) { $map[$id] = $r }
        } else {
            $ot = [int64]($old.timestamp | ForEach-Object { $_ })
            $nt = [int64]($r.timestamp | ForEach-Object { $_ })
            if ($nt -gt $ot) {
                $map[$id] = $r
            } elseif ($nt -eq $ot) {
                # If equal timestamp, keep the record that has non-empty extra or content
                $newHasExtra = ($null -ne $r.extra -and (To-Array $r.extra).Count -gt 0)
                $oldHasExtra = ($null -ne $old.extra -and (To-Array $old.extra).Count -gt 0)
                if ($newHasExtra -or (-not $oldHasExtra)) { $map[$id] = $r }
            }
        }
    }
    return @($map.Values)
}

function Get-MimeType([string]$filename) {
    $ext = [System.IO.Path]::GetExtension($filename).ToLower()
    switch ($ext) {
        '.png'  { return 'image/png' }
        '.jpg'  { return 'image/jpeg' }
        '.jpeg' { return 'image/jpeg' }
        '.webp' { return 'image/webp' }
        '.gif'  { return 'image/gif' }
        '.svg'  { return 'image/svg+xml' }
        '.ico'  { return 'image/x-icon' }
        '.pdf'  { return 'application/pdf' }
        '.txt'  { return 'text/plain; charset=utf-8' }
        '.json' { return 'application/json; charset=utf-8' }
        '.mp3'  { return 'audio/mpeg' }
        '.wav'  { return 'audio/wav' }
        '.mp4'  { return 'video/mp4' }
        default { return 'application/octet-stream' }
    }
}

function Send-Response($stream, [int]$status, [string]$statusText, [string]$contentType, [byte[]]$bytes, [string]$origin) {
    $corsOrigin = if ([string]::IsNullOrWhiteSpace($origin)) { '*' } else { $origin }
    $headers = "HTTP/1.1 $status $statusText`r`n" +
               "Content-Type: $contentType`r`n" +
               "Content-Length: $($bytes.Length)`r`n" +
               "Access-Control-Allow-Origin: $corsOrigin`r`n" +
               "Access-Control-Allow-Methods: GET, POST, OPTIONS`r`n" +
               "Access-Control-Allow-Headers: Content-Type, Cache-Control`r`n" +
               "Cache-Control: no-store`r`n" +
               "Connection: close`r`n`r`n"
    $hb = [System.Text.Encoding]::ASCII.GetBytes($headers)
    $stream.Write($hb, 0, $hb.Length)

    # Write body in 64KB chunks to prevent socket buffer overflows
    $chunkSize = 65536
    $offset = 0
    while ($offset -lt $bytes.Length) {
        $len = [Math]::Min($chunkSize, $bytes.Length - $offset)
        $stream.Write($bytes, $offset, $len)
        $offset += $len
    }
    $stream.Close()
}

function JsonResponse($stream, [int]$status, $obj, [string]$origin) {
    $statusText = if ($status -eq 200) { 'OK' } elseif ($status -eq 404) { 'Not Found' } else { 'Error' }
    $json = $obj | ConvertTo-Json -Depth 100 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    Send-Response $stream $status $statusText 'application/json; charset=utf-8' $bytes $origin
}

function EmptyResponse($stream, [string]$origin) {
    $corsOrigin = if ([string]::IsNullOrWhiteSpace($origin)) { '*' } else { $origin }
    $headers = "HTTP/1.1 204 No Content`r`n" +
               "Access-Control-Allow-Origin: $corsOrigin`r`n" +
               "Access-Control-Allow-Methods: GET, POST, OPTIONS`r`n" +
               "Access-Control-Allow-Headers: Content-Type, Cache-Control`r`n" +
               "Connection: close`r`n`r`n"
    $hb = [System.Text.Encoding]::ASCII.GetBytes($headers)
    $stream.Write($hb, 0, $hb.Length)
    $stream.Close()
}

function Read-HttpRequest($stream) {
    $ms = New-Object IO.MemoryStream
    $buffer = New-Object byte[] 4096
    $headerEndPos = -1

    # Read until CRLF CRLF (13, 10, 13, 10)
    while ($true) {
        $n = $stream.Read($buffer, 0, $buffer.Length)
        if ($n -le 0) { break }
        $ms.Write($buffer, 0, $n)
        $bytes = $ms.ToArray()
        for ($i = 0; $i -le $bytes.Length - 4; $i++) {
            if ($bytes[$i] -eq 13 -and $bytes[$i+1] -eq 10 -and $bytes[$i+2] -eq 13 -and $bytes[$i+3] -eq 10) {
                $headerEndPos = $i
                break
            }
        }
        if ($headerEndPos -ge 0) { break }
    }

    if ($headerEndPos -lt 0) { return $null }

    $allBytes = $ms.ToArray()
    $headerBytes = [byte[]]::new($headerEndPos)
    [Array]::Copy($allBytes, 0, $headerBytes, 0, $headerEndPos)
    $headerText = [System.Text.Encoding]::ASCII.GetString($headerBytes)
    $lines = $headerText -split "`r`n"
    $requestLine = $lines[0].Split(' ')
    $method = $requestLine[0]
    $path = $requestLine[1]

    $contentLength = 0
    $origin = '*'
    foreach ($line in $lines) {
        if ($line -match '^Content-Length:\s*(\d+)') {
            $contentLength = [int]$Matches[1]
        } elseif ($line -match '^Origin:\s*(.+)') {
            $origin = $Matches[1].Trim()
        }
    }

    # Extract any body bytes already buffered past the headers
    $bodyStart = $headerEndPos + 4
    $alreadyRead = $allBytes.Length - $bodyStart
    $bodyBytes = [byte[]]::new($contentLength)

    if ($alreadyRead -gt 0 -and $contentLength -gt 0) {
        $toCopy = [Math]::Min($alreadyRead, $contentLength)
        [Array]::Copy($allBytes, $bodyStart, $bodyBytes, 0, $toCopy)
    }

    $curr = [Math]::Min($alreadyRead, $contentLength)
    while ($curr -lt $contentLength) {
        $read = $stream.Read($bodyBytes, $curr, $contentLength - $curr)
        if ($read -le 0) { break }
        $curr += $read
    }

    $bodyText = if ($contentLength -gt 0) { [System.Text.Encoding]::UTF8.GetString($bodyBytes) } else { "" }

    return @{
        Method = $method
        Path = $path
        ContentLength = $contentLength
        Origin = $origin
        Body = $bodyText
    }
}

$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$listener.Start()

while ($true) {
    try {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $stream.ReadTimeout = 15000
        $stream.WriteTimeout = 15000

        $req = Read-HttpRequest $stream
        if ($null -eq $req) {
            $stream.Close()
            $client.Close()
            continue
        }

        $method = $req.Method
        $path = $req.Path
        $origin = $req.Origin

        if ($method -eq 'OPTIONS') {
            EmptyResponse $stream $origin
            $client.Close()
            continue
        }

        if ($method -eq 'GET' -and $path -eq '/health') {
            $d = Read-Data
            $uploadCount = (Get-ChildItem -LiteralPath $uploadsDir -File -ErrorAction SilentlyContinue | Measure-Object).Count
            JsonResponse $stream 200 ([pscustomobject]@{
                ok = $true
                portableHistory = $true
                updated = [int64]$d.updated
                conversations = [int]@($d.conversations).Count
                messages = [int]@($d.messages).Count
                uploads = [int]$uploadCount
            }) $origin
            $client.Close()
            continue
        }

        if ($method -eq 'GET' -and $path -eq '/sync') {
            JsonResponse $stream 200 (Read-Data) $origin
            $client.Close()
            continue
        }

        if ($method -eq 'POST' -and $path -eq '/sync') {
            $clientData = if (-not [string]::IsNullOrWhiteSpace($req.Body)) { $req.Body | ConvertFrom-Json } else { $null }
            $serverData = Read-Data
            $mergedConversations = @(Merge-Records $serverData.conversations $clientData.conversations 'conversation')
            $mergedMessages = @(Merge-Records $serverData.messages $clientData.messages 'message')

            # Extract and persist all message attachments/images directly to Data\uploads\
            Save-MessageAttachments $mergedMessages

            $merged = [pscustomobject]@{
                version = 1
                updated = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                conversations = $mergedConversations
                messages = $mergedMessages
            }
            Save-Data $merged
            JsonResponse $stream 200 $merged $origin
            $client.Close()
            continue
        }

        if ($method -eq 'POST' -and $path -eq '/clear') {
            # Reset conversations.json
            $emptyData = [pscustomobject]@{
                version = 1
                updated = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
                conversations = @()
                messages = @()
            }
            Save-Data $emptyData

            # Clean uploads folder except .gitkeep
            Get-ChildItem -LiteralPath $uploadsDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne '.gitkeep' } | Remove-Item -Force -ErrorAction SilentlyContinue

            JsonResponse $stream 200 ([pscustomobject]@{ ok = $true; cleared = $true; updated = $emptyData.updated }) $origin
            $client.Close()
            continue
        }

        # Serve uploaded files: GET /uploads/<filename>
        if ($method -eq 'GET' -and $path.StartsWith('/uploads/')) {
            $fileName = [System.IO.Path]::GetFileName([System.Uri]::UnescapeDataString($path.Substring(9)))
            $filePath = Join-Path $uploadsDir $fileName
            if (Test-Path -LiteralPath $filePath) {
                $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                $mime = Get-MimeType $fileName
                Send-Response $stream 200 'OK' $mime $fileBytes $origin
            } else {
                JsonResponse $stream 404 ([pscustomobject]@{ error = 'File not found' }) $origin
            }
            $client.Close()
            continue
        }

        JsonResponse $stream 404 ([pscustomobject]@{ error = 'Not found' }) $origin
        $client.Close()
    } catch {
        try { if ($stream) { JsonResponse $stream 500 ([pscustomobject]@{ error = $_.Exception.Message }) '*' } } catch {}
        try { if ($client) { $client.Close() } } catch {}
    }
}
