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
    Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/tctapia857-code/adrian-602/codex/postgres-render/n8n/enviar-productos-gmail.json' -OutFile $template
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
