param(
    [Parameter(Mandatory = $true)][string]$CorreoProfesor,
    [string]$Alumno = 'Adrian Tapia',
    [string]$Grupo = '602'
)
$ErrorActionPreference = 'Stop'
if ($CorreoProfesor -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') { throw 'Correo del profesor invalido.' }
if (-not (Test-Path 'compose.yaml')) { throw 'Ejecuta esto desde la carpeta del proyecto que contiene compose.yaml.' }
function Check-Docker {
    if ($LASTEXITCODE -ne 0) { throw 'Docker/n8n devolvio un error. No se confirma el envio.' }
}
$cid = docker compose ps -q n8n
Check-Docker
if (-not $cid) { throw 'Primero inicia n8n: docker compose --profile cliente up -d n8n' }
# Evita enviar dos veces si se repite este comando.
docker compose exec -T n8n node -e "const fs=require('fs'); if(fs.existsSync('/home/node/.n8n/productos-profesor-enviado.json')){console.error('Este envio ya se completo. No se enviara otra vez.');process.exit(2)}"
Check-Docker
$work = Join-Path ([System.IO.Path]::GetTempPath()) ('productos-n8n-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
try {
    $template = Join-Path $work 'workflow.json'
    [IO.File]::WriteAllBytes($template, [Convert]::FromBase64String('ewogICJuYW1lIjogIkVudmlhciBBUEkgZGUgcHJvZHVjdG9zIGFsIHByb2Zlc29yIHBvciBHbWFpbCIsCiAgIm5vZGVzIjogWwogICAgewogICAgICAicGFyYW1ldGVycyI6IHt9LAogICAgICAiaWQiOiAibWFudWFsIiwKICAgICAgIm5hbWUiOiAiRWplY3V0YXIgbWFudWFsbWVudGUiLAogICAgICAidHlwZSI6ICJuOG4tbm9kZXMtYmFzZS5tYW51YWxUcmlnZ2VyIiwKICAgICAgInR5cGVWZXJzaW9uIjogMSwKICAgICAgInBvc2l0aW9uIjogWwogICAgICAgIDAsCiAgICAgICAgMAogICAgICBdCiAgICB9LAogICAgewogICAgICAicGFyYW1ldGVycyI6IHsKICAgICAgICAiYXNzaWdubWVudHMiOiB7CiAgICAgICAgICAiYXNzaWdubWVudHMiOiBbCiAgICAgICAgICAgIHsKICAgICAgICAgICAgICAiaWQiOiAiZGVzdGlubyIsCiAgICAgICAgICAgICAgIm5hbWUiOiAiY29ycmVvUHJvZmVzb3IiLAogICAgICAgICAgICAgICJ2YWx1ZSI6ICIiLAogICAgICAgICAgICAgICJ0eXBlIjogInN0cmluZyIKICAgICAgICAgICAgfSwKICAgICAgICAgICAgewogICAgICAgICAgICAgICJpZCI6ICJhbHVtbm8iLAogICAgICAgICAgICAgICJuYW1lIjogImFsdW1ubyIsCiAgICAgICAgICAgICAgInZhbHVlIjogIkFkcmlhbiBUYXBpYSIsCiAgICAgICAgICAgICAgInR5cGUiOiAic3RyaW5nIgogICAgICAgICAgICB9LAogICAgICAgICAgICB7CiAgICAgICAgICAgICAgImlkIjogImdydXBvIiwKICAgICAgICAgICAgICAibmFtZSI6ICJncnVwbyIsCiAgICAgICAgICAgICAgInZhbHVlIjogIjYwMiIsCiAgICAgICAgICAgICAgInR5cGUiOiAic3RyaW5nIgogICAgICAgICAgICB9CiAgICAgICAgICBdCiAgICAgICAgfSwKICAgICAgICAib3B0aW9ucyI6IHt9CiAgICAgIH0sCiAgICAgICJpZCI6ICJkYXRvcyIsCiAgICAgICJuYW1lIjogIkRhdG9zIGRlbCBjb3JyZW8iLAogICAgICAidHlwZSI6ICJuOG4tbm9kZXMtYmFzZS5zZXQiLAogICAgICAidHlwZVZlcnNpb24iOiAzLjQsCiAgICAgICJwb3NpdGlvbiI6IFsKICAgICAgICAyNDAsCiAgICAgICAgMAogICAgICBdCiAgICB9LAogICAgewogICAgICAicGFyYW1ldGVycyI6IHsKICAgICAgICAibWV0aG9kIjogIkdFVCIsCiAgICAgICAgInVybCI6ICJodHRwczovL2FwaS1wcm9kdWN0b3MtYWRyaWFuLWxxd2sub25yZW5kZXIuY29tL2FwaS9wcm9kdWN0b3MiLAogICAgICAgICJhdXRoZW50aWNhdGlvbiI6ICJub25lIiwKICAgICAgICAib3B0aW9ucyI6IHsKICAgICAgICAgICJ0aW1lb3V0IjogMTIwMDAwCiAgICAgICAgfQogICAgICB9LAogICAgICAiaWQiOiAiYXBpIiwKICAgICAgIm5hbWUiOiAiQ29uc3VsdGFyIEFQSSBkZSBwcm9kdWN0b3MiLAogICAgICAidHlwZSI6ICJuOG4tbm9kZXMtYmFzZS5odHRwUmVxdWVzdCIsCiAgICAgICJ0eXBlVmVyc2lvbiI6IDQuMiwKICAgICAgInBvc2l0aW9uIjogWwogICAgICAgIDQ4MCwKICAgICAgICAwCiAgICAgIF0KICAgIH0sCiAgICB7CiAgICAgICJwYXJhbWV0ZXJzIjogewogICAgICAgICJtb2RlIjogInJ1bk9uY2VGb3JBbGxJdGVtcyIsCiAgICAgICAgImpzQ29kZSI6ICJjb25zdCBjb25maWcgPSAkKCdEYXRvcyBkZWwgY29ycmVvJykuZmlyc3QoKS5qc29uO1xuY29uc3QgcGFyYSA9IFN0cmluZyhjb25maWcuY29ycmVvUHJvZmVzb3IgfHwgJycpLnRyaW0oKTtcbmlmICghL15bXlxcc0BdK0BbXlxcc0BdK1xcLlteXFxzQF0rJC8udGVzdChwYXJhKSkge1xuICB0aHJvdyBuZXcgRXJyb3IoJ0NvbXBsZXRhIGNvcnJlb1Byb2Zlc29yIGVuIGVsIG5vZG8gRGF0b3MgZGVsIGNvcnJlbyBhbnRlcyBkZSBlbnZpYXIuJyk7XG59XG5jb25zdCBwcm9kdWN0b3MgPSAkaW5wdXQuYWxsKCkuZmxhdE1hcChpdGVtID0+IEFycmF5LmlzQXJyYXkoaXRlbS5qc29uKSA/IGl0ZW0uanNvbiA6IFtpdGVtLmpzb25dKTtcbmlmICghcHJvZHVjdG9zLmxlbmd0aCB8fCBwcm9kdWN0b3Muc29tZShwID0+ICFOdW1iZXIuaXNJbnRlZ2VyKHAuaWQpIHx8IHR5cGVvZiBwLm5vbWJyZSAhPT0gJ3N0cmluZycpKSB7XG4gIHRocm93IG5ldyBFcnJvcignTGEgQVBJIG5vIGRldm9sdmnDsyB1biBjYXTDoWxvZ28gZGUgcHJvZHVjdG9zIHbDoWxpZG8uIE5vIHNlIGVudmlhcsOhIGVsIGNvcnJlby4nKTtcbn1cbmNvbnN0IGVzYyA9IHZhbHVlID0+IFN0cmluZyh2YWx1ZSkucmVwbGFjZSgvWyY8PlwiJ10vZywgYyA9PiAoeycmJzonJmFtcDsnLCc8JzonJmx0OycsJz4nOicmZ3Q7JywnXCInOicmcXVvdDsnLFwiJ1wiOicmIzM5Oyd9W2NdKSk7XG5jb25zdCBhbHVtbm8gPSBTdHJpbmcoY29uZmlnLmFsdW1ubyB8fCAnQWRyaWFuIFRhcGlhJyk7XG5jb25zdCBncnVwbyA9IFN0cmluZyhjb25maWcuZ3J1cG8gfHwgJzYwMicpO1xuY29uc3QgdXJsID0gJ2h0dHBzOi8vYXBpLXByb2R1Y3Rvcy1hZHJpYW4tbHF3ay5vbnJlbmRlci5jb20vYXBpL3Byb2R1Y3Rvcyc7XG5jb25zdCBmaWxhcyA9IHByb2R1Y3Rvcy5tYXAocCA9PiBgPHRyPjx0ZCBzdHlsZT1cInBhZGRpbmc6OHB4O2JvcmRlcjoxcHggc29saWQgI2NjY1wiPiR7cC5pZH08L3RkPjx0ZCBzdHlsZT1cInBhZGRpbmc6OHB4O2JvcmRlcjoxcHggc29saWQgI2NjY1wiPiR7ZXNjKHAubm9tYnJlKX08L3RkPjwvdHI+YCkuam9pbignJyk7XG5jb25zdCBodG1sID0gYDxwPkJ1ZW4gZMOtYSwgcHJvZmVzb3I6PC9wPjxwPkNvbXBhcnRvIG1pIEFQSSBkZSBwcm9kdWN0b3MgZGVzYXJyb2xsYWRhIGVuIE5vZGUuanMgY29uIFBvc3RncmVTUUwsIGRlc3BsZWdhZGEgZW4gUmVuZGVyIHkgY29uc3VsdGFkYSBkZXNkZSBlc3RlIGZsdWpvIGRlIG44bi48L3A+PHA+PHN0cm9uZz5BbHVtbm86PC9zdHJvbmc+ICR7ZXNjKGFsdW1ubyl9PGJyPjxzdHJvbmc+R3J1cG86PC9zdHJvbmc+ICR7ZXNjKGdydXBvKX08L3A+PHA+PGEgaHJlZj1cIiR7dXJsfVwiPkNvbnN1bHRhciBsYSBBUEkgZGUgcHJvZHVjdG9zPC9hPjwvcD48cD5Qcm9kdWN0b3Mgb2J0ZW5pZG9zIGRlIGxhIEFQSTogPHN0cm9uZz4ke3Byb2R1Y3Rvcy5sZW5ndGh9PC9zdHJvbmc+LjwvcD48dGFibGUgc3R5bGU9XCJib3JkZXItY29sbGFwc2U6Y29sbGFwc2VcIj48dGhlYWQ+PHRyPjx0aCBzdHlsZT1cInBhZGRpbmc6OHB4O2JvcmRlcjoxcHggc29saWQgI2NjY1wiPklEPC90aD48dGggc3R5bGU9XCJwYWRkaW5nOjhweDtib3JkZXI6MXB4IHNvbGlkICNjY2NcIj5Qcm9kdWN0bzwvdGg+PC90cj48L3RoZWFkPjx0Ym9keT4ke2ZpbGFzfTwvdGJvZHk+PC90YWJsZT48cD5TYWx1ZG9zLDxicj4ke2VzYyhhbHVtbm8pfTwvcD5gO1xucmV0dXJuIFt7anNvbjoge3BhcmEsIGFzdW50bzogYEVudHJlZ2EgQVBJIGRlIHByb2R1Y3RvcyAtICR7YWx1bW5vfSAtIEdydXBvICR7Z3J1cG99YCwgaHRtbCwgdG90YWxQcm9kdWN0b3M6IHByb2R1Y3Rvcy5sZW5ndGgsIGFwaVVybDogdXJsfX1dOyIKICAgICAgfSwKICAgICAgImlkIjogInRhYmxhIiwKICAgICAgIm5hbWUiOiAiUHJlcGFyYXIgdW4gc29sbyBjb3JyZW8iLAogICAgICAidHlwZSI6ICJuOG4tbm9kZXMtYmFzZS5jb2RlIiwKICAgICAgInR5cGVWZXJzaW9uIjogMiwKICAgICAgInBvc2l0aW9uIjogWwogICAgICAgIDcyMCwKICAgICAgICAwCiAgICAgIF0KICAgIH0sCiAgICB7CiAgICAgICJwYXJhbWV0ZXJzIjogewogICAgICAgICJyZXNvdXJjZSI6ICJtZXNzYWdlIiwKICAgICAgICAib3BlcmF0aW9uIjogInNlbmQiLAogICAgICAgICJzZW5kVG8iOiAiPXt7ICRqc29uLnBhcmEgfX0iLAogICAgICAgICJzdWJqZWN0IjogIj17eyAkanNvbi5hc3VudG8gfX0iLAogICAgICAgICJlbWFpbFR5cGUiOiAiaHRtbCIsCiAgICAgICAgIm1lc3NhZ2UiOiAiPXt7ICRqc29uLmh0bWwgfX0iLAogICAgICAgICJvcHRpb25zIjogewogICAgICAgICAgImFwcGVuZEF0dHJpYnV0aW9uIjogZmFsc2UKICAgICAgICB9CiAgICAgIH0sCiAgICAgICJpZCI6ICJnbWFpbCIsCiAgICAgICJuYW1lIjogIkVudmlhciBhbCBwcm9mZXNvciBjb24gR21haWwiLAogICAgICAidHlwZSI6ICJuOG4tbm9kZXMtYmFzZS5nbWFpbCIsCiAgICAgICJ0eXBlVmVyc2lvbiI6IDIuMSwKICAgICAgInBvc2l0aW9uIjogWwogICAgICAgIDk2MCwKICAgICAgICAwCiAgICAgIF0KICAgIH0KICBdLAogICJjb25uZWN0aW9ucyI6IHsKICAgICJFamVjdXRhciBtYW51YWxtZW50ZSI6IHsKICAgICAgIm1haW4iOiBbCiAgICAgICAgWwogICAgICAgICAgewogICAgICAgICAgICAibm9kZSI6ICJEYXRvcyBkZWwgY29ycmVvIiwKICAgICAgICAgICAgInR5cGUiOiAibWFpbiIsCiAgICAgICAgICAgICJpbmRleCI6IDAKICAgICAgICAgIH0KICAgICAgICBdCiAgICAgIF0KICAgIH0sCiAgICAiRGF0b3MgZGVsIGNvcnJlbyI6IHsKICAgICAgIm1haW4iOiBbCiAgICAgICAgWwogICAgICAgICAgewogICAgICAgICAgICAibm9kZSI6ICJDb25zdWx0YXIgQVBJIGRlIHByb2R1Y3RvcyIsCiAgICAgICAgICAgICJ0eXBlIjogIm1haW4iLAogICAgICAgICAgICAiaW5kZXgiOiAwCiAgICAgICAgICB9CiAgICAgICAgXQogICAgICBdCiAgICB9LAogICAgIkNvbnN1bHRhciBBUEkgZGUgcHJvZHVjdG9zIjogewogICAgICAibWFpbiI6IFsKICAgICAgICBbCiAgICAgICAgICB7CiAgICAgICAgICAgICJub2RlIjogIlByZXBhcmFyIHVuIHNvbG8gY29ycmVvIiwKICAgICAgICAgICAgInR5cGUiOiAibWFpbiIsCiAgICAgICAgICAgICJpbmRleCI6IDAKICAgICAgICAgIH0KICAgICAgICBdCiAgICAgIF0KICAgIH0sCiAgICAiUHJlcGFyYXIgdW4gc29sbyBjb3JyZW8iOiB7CiAgICAgICJtYWluIjogWwogICAgICAgIFsKICAgICAgICAgIHsKICAgICAgICAgICAgIm5vZGUiOiAiRW52aWFyIGFsIHByb2Zlc29yIGNvbiBHbWFpbCIsCiAgICAgICAgICAgICJ0eXBlIjogIm1haW4iLAogICAgICAgICAgICAiaW5kZXgiOiAwCiAgICAgICAgICB9CiAgICAgICAgXQogICAgICBdCiAgICB9CiAgfSwKICAiYWN0aXZlIjogZmFsc2UsCiAgInNldHRpbmdzIjogewogICAgImV4ZWN1dGlvbk9yZGVyIjogInYxIgogIH0sCiAgInBpbkRhdGEiOiB7fQp9Cg=='))
    $workflow = Get-Content -Raw -Encoding UTF8 $template | ConvertFrom-Json
    $workflow | Add-Member -NotePropertyName id -NotePropertyValue 'productos-render-profesor' -Force
    foreach ($node in $workflow.nodes) {
        if ($node.id -eq 'datos') {
            foreach ($field in $node.parameters.assignments.assignments) {
                if ($field.name -eq 'correoProfesor') { $field.value = $CorreoProfesor }
                if ($field.name -eq 'alumno') { $field.value = $Alumno }
                if ($field.name -eq 'grupo') { $field.value = $Grupo }
            }
        }
    }
    $json = $workflow | ConvertTo-Json -Depth 50
    [IO.File]::WriteAllText($template, $json, (New-Object System.Text.UTF8Encoding($false)))
    docker compose cp $template n8n:/tmp/productos-correo-nuevo.json
    Check-Docker
    # Exporta flujos, no credenciales ni tokens; solo reutiliza la referencia Gmail.
    docker compose exec -T n8n n8n export:workflow --all --output=/tmp/productos-flujos-existentes.json
    Check-Docker
    $prepare = @'
const fs = require('fs');
const existing = JSON.parse(fs.readFileSync('/tmp/productos-flujos-existentes.json', 'utf8'));
const workflow = JSON.parse(fs.readFileSync('/tmp/productos-correo-nuevo.json', 'utf8'));
const candidates = new Map();
for (const flow of existing) for (const node of flow.nodes || []) {
  const credential = node.credentials?.gmailOAuth2;
  if (credential?.id) candidates.set(credential.id, credential);
}
if (candidates.size !== 1) {
  console.error(candidates.size === 0 ? 'No hay una conexion Gmail configurada en tus flujos. Abre Gmail en n8n y conecta tu cuenta antes de repetir.' : 'Hay varias cuentas Gmail. Selecciona la cuenta correcta manualmente; no se enviara ningun correo.');
  process.exit(3);
}
workflow.nodes.find(n => n.id === 'gmail').credentials = {gmailOAuth2: [...candidates.values()][0]};
fs.writeFileSync('/tmp/productos-correo-nuevo.json', JSON.stringify(workflow));
console.log('Referencia Gmail existente reutilizada. El flujo original no se modifica.');
'@
    $preparePath = Join-Path $work 'prepare.cjs'
    [IO.File]::WriteAllText($preparePath, $prepare, (New-Object System.Text.UTF8Encoding($false)))
    docker compose cp $preparePath n8n:/tmp/productos-preparar.cjs
    Check-Docker
    docker compose exec -T n8n node /tmp/productos-preparar.cjs
    Check-Docker
    docker compose exec -T n8n n8n import:workflow --input=/tmp/productos-correo-nuevo.json
    Check-Docker
    Write-Host "Enviando un correo a $CorreoProfesor con el catalogo real de Render..."
    # Conserva el codigo de salida; el log queda local en n8n, no se sube a GitHub.
    docker compose exec -T n8n sh -c 'n8n execute --id=productos-render-profesor --rawOutput > /tmp/productos-resultado-envio.log 2>&1'
    if ($LASTEXITCODE -ne 0) {
        throw 'n8n no confirmo el envio. Abre el flujo nuevo en n8n para revisar la conexion Gmail. No se marco como enviado.'
    }
    $check = @'
const fs = require('fs');
const log = fs.readFileSync('/tmp/productos-resultado-envio.log', 'utf8');
let result;
for (let i = 0; i < log.length; i++) {
  if (log[i] !== '{') continue;
  let depth = 0, inString = false, escape = false;
  for (let j = i; j < log.length; j++) {
    const c = log[j];
    if (inString) { if (escape) escape = false; else if (c === '\\') escape = true; else if (c === '"') inString = false; }
    else if (c === '"') inString = true;
    else if (c === '{') depth++;
    else if (c === '}' && --depth === 0) {
      try { const v = JSON.parse(log.slice(i, j + 1)); if (v.status && v.data) result = v; } catch {}
      break;
    }
  }
  if (result) break;
}
const sent = result?.data?.resultData?.runData?.['Enviar al profesor con Gmail']?.[0]?.data?.main?.[0]?.[0]?.json;
if (result?.status !== 'success' || !sent?.id) { console.error('No se encontro confirmacion de Gmail; no se confirma el envio.'); process.exit(4); }
fs.writeFileSync('/home/node/.n8n/productos-profesor-enviado.json', JSON.stringify({sentAt:new Date().toISOString(),messageId:sent.id}));
console.log('CONFIRMADO: Gmail acepto el correo para el profesor. No lo ejecutes de nuevo.');
'@
    $checkPath = Join-Path $work 'check.cjs'
    [IO.File]::WriteAllText($checkPath, $check, (New-Object System.Text.UTF8Encoding($false)))
    docker compose cp $checkPath n8n:/tmp/productos-confirmar.cjs
    Check-Docker
    docker compose exec -T n8n node /tmp/productos-confirmar.cjs
    Check-Docker
} finally {
    docker compose exec -T n8n node -e "const fs=require('fs'); for(const p of ['/tmp/productos-flujos-existentes.json','/tmp/productos-correo-nuevo.json','/tmp/productos-preparar.cjs','/tmp/productos-confirmar.cjs']) try{fs.unlinkSync(p)}catch{}" | Out-Null
    Remove-Item -Recurse -Force $work
}
