# Türkçe karakter desteği için UTF-8 encoding ayarı
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Ana proje adı ve WebAPI adı kullanıcıdan alınıyor
$solutionName = Read-Host "Solution Adi "
$solutionPath = "${solutionName}.sln"
$srcFolderPath = "$PSScriptRoot\$solutionName\src"

$appName = Read-Host "Uygulama Adi "
$apiName = Read-Host "API Adi (otomatik olarak sonuna API eklenecek) "
$apiNameWithPrefix = "${appName}.${apiName}API"

# Klasör yapısını oluştur
$applicationPath = "$srcFolderPath\$appName"
New-Item -Path "$applicationPath\Core" -ItemType Directory -Force
New-Item -Path "$applicationPath\Infrastructure" -ItemType Directory -Force
New-Item -Path "$applicationPath\Presentation" -ItemType Directory -Force

# Core katmanı projelerini oluştur
dotnet new classlib -n "$appName.Domain" -o "$applicationPath\Core\$appName.Domain"
dotnet new classlib -n "$appName.Application" -o "$applicationPath\Core\$appName.Application"

# Infrastructure katmanı projelerini oluştur
dotnet new classlib -n "$appName.Infrastructure" -o "$applicationPath\Infrastructure\$appName.Infrastructure"
dotnet new classlib -n "$appName.Persistence" -o "$applicationPath\Infrastructure\$appName.Persistence"

# Presentation katmanı ve WebAPI projesi
$webApiPath = "$applicationPath\Presentation\$apiNameWithPrefix"
dotnet new webapi -n "$apiNameWithPrefix" -o "$webApiPath"

# Solution dosyasını oluştur
dotnet new sln -n "$solutionName" -o "$PSScriptRoot\$solutionName"

# Projeleri solution dosyasına ekle
dotnet sln "$PSScriptRoot\$solutionName\$solutionPath" add "$applicationPath\Core\$appName.Domain\$appName.Domain.csproj"
dotnet sln "$PSScriptRoot\$solutionName\$solutionPath" add "$applicationPath\Core\$appName.Application\$appName.Application.csproj"
dotnet sln "$PSScriptRoot\$solutionName\$solutionPath" add "$applicationPath\Infrastructure\$appName.Infrastructure\$appName.Infrastructure.csproj"
dotnet sln "$PSScriptRoot\$solutionName\$solutionPath" add "$applicationPath\Infrastructure\$appName.Persistence\$appName.Persistence.csproj"
dotnet sln "$PSScriptRoot\$solutionName\$solutionPath" add "$webApiPath\$apiNameWithPrefix.csproj"

# WebAPI projesindeki belirli dosyaları sil
$httpFilePath = "$webApiPath\$apiNameWithPrefix.http"
if (Test-Path $httpFilePath) {
    Remove-Item $httpFilePath
    Write-Host "$httpFilePath dosyasi silindi."
}
else {
    Write-Host "$httpFilePath dosyasi bulunamadi."
}

# WebAPI projesinin csproj dosyası yolu
$csprojFilePath = "$webApiPath\$apiNameWithPrefix.csproj"

# Post-build event için eklenmesi gereken XML
$postBuildEvent = @"
    <Target Name="PostBuild" AfterTargets="PostBuildEvent">
        <Exec Command="echo Publish klasörü temizleniyor&#xD;&#xA;rmdir /s /q &quot;publish&quot;&#xD;&#xA;echo Publish klasörü temizlendi." />
    </Target>
"@

# csproj dosyasına Post-build event'i ekle
if (Test-Path $csprojFilePath) {
    $csprojContent = Get-Content $csprojFilePath -Raw
    if ($csprojContent -notlike '*<Target Name="PostBuild"*') {
        $csprojContent = $csprojContent -replace '</Project>', "$postBuildEvent`n</Project>"
        Set-Content -Path $csprojFilePath -Value $csprojContent
        Write-Host "Post-build event $csprojFilePath dosyasina eklendi."
    }
    else {
        Write-Host "Post-build event zaten mevcut."
    }
}
else {
    Write-Host "$csprojFilePath dosyasi bulunamadi."
}

# Required Files klasöründeki dosyaları WebAPI klasörüne kopyala
$requiredFilesFolderPath = "$PSScriptRoot\required-files"
$destinationPath = "$webApiPath"
if (Test-Path $requiredFilesFolderPath) {
    Copy-Item "$requiredFilesFolderPath\*" -Destination $destinationPath -Recurse -Force
    Write-Host "Required Files'daki dosyalar $destinationPath klasorune kopyalandi."
}
else {
    Write-Host "Required Files klasoru bulunamadi: $requiredFilesFolderPath"
}

Write-Host "Proje yapisi olusturuldu!"

Write-Host "Devam etmek icin bir tusa basin..."
[System.Console]::ReadKey() > $null
