$files = Get-ChildItem -Recurse -Filter *.dart
foreach ($f in $files) {
    $c = Get-Content $f.FullName -Raw
    $c = $c -replace '(from\s+[\'"])(\.\./)+(core|features|shared)/', 'from \'package:kawangizi_mobile/$3/'
    $c = $c -replace '(import\s+[\'"])(\.\./)+(core|features|shared)/', 'import \'package:kawangizi_mobile/$3/'
    Set-Content $f.FullName $c
}
Write-Output "Done"