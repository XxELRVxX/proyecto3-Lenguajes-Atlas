// ============================================================
//  server.js — Servidor Node.js para Operación Atlas
//  Actúa de puente entre la interfaz React y SWI-Prolog.
// ============================================================

const express = require('express');
const cors    = require('cors');
const { spawn } = require('child_process');
const path    = require('path');

const app  = express();
const PORT = 3001;

app.use(cors());
app.use(express.json());

const JUEGO_PL = path.join(__dirname, 'prolog', 'juego.pl');

function ejecutarProlog(goal) {
    return new Promise((resolve, reject) => {
        const args = [
            '--quiet',
            '-g', `${goal}, halt`,
            '-g', 'halt(1)',
            '-l', JUEGO_PL
        ];

        const proc = spawn('swipl', args);
        let output = '';

        proc.stdout.on('data', d => { output += d.toString(); });
        proc.stderr.on('data', () => {});

        proc.on('close', () => {
            const limpio = output
                .split('\n')
                .filter(l => !l.startsWith('Warning:') && !l.startsWith('%') && l.trim() !== '')
                .join('\n')
                .trim();
            resolve(limpio || 'OK');
        });

        proc.on('error', err => reject(new Error('No se pudo iniciar swipl: ' + err.message)));
        setTimeout(() => { proc.kill(); reject(new Error('Timeout')); }, 8000);
    });
}

// Estado del juego guardado en Node (espejo del estado Prolog)
// Esto permite que React sepa qué mostrar sin consultar Prolog cada vez
let estadoJuego = {
    lugar: 'puente_mando',
    inventario: [],
    usados: [],
    reparados: [],
    rescatados: [],
    visitados: ['puente_mando'],
    conexiones: ['laboratorio', 'enfermeria'],
    artefactos_aqui: ['tarjeta_seguridad'],
    tripulantes_aqui: [],
    sistemas_aqui: []
};

// Parsea la lista Prolog "[a,b,c]" a array JS ["a","b","c"]
function parsearListaProlog(str) {
    if (!str || str === '[]') return [];
    const inner = str.replace(/^\[/, '').replace(/\]$/, '');
    return inner.split(',').map(s => s.trim()).filter(Boolean);
}

// Actualiza el estado leyendo la salida de estado_json
async function actualizarEstado() {
    try {
        const texto = await ejecutarProlog('estado_json');
        // estado_json imprime un JSON válido
        estadoJuego = JSON.parse(texto);
    } catch (e) {
        console.error('Error actualizando estado:', e.message);
    }
}

// GET /api/estado
app.get('/api/estado', async (req, res) => {
    await actualizarEstado();
    res.json({ ok: true, estado: estadoJuego });
});

// POST /api/mover
app.post('/api/mover', async (req, res) => {
    const { destino } = req.body;
    if (!destino) return res.status(400).json({ error: 'Falta destino.' });
    const respuesta = await ejecutarProlog(`mover(${destino})`).catch(e => e.message);
    res.json({ ok: !respuesta.includes('ERROR'), respuesta });
});

// POST /api/tomar
app.post('/api/tomar', async (req, res) => {
    const { artefacto } = req.body;
    if (!artefacto) return res.status(400).json({ error: 'Falta artefacto.' });
    const respuesta = await ejecutarProlog(`tomar(${artefacto})`).catch(e => e.message);
    res.json({ ok: !respuesta.includes('ERROR'), respuesta });
});

// POST /api/usar
app.post('/api/usar', async (req, res) => {
    const { artefacto } = req.body;
    if (!artefacto) return res.status(400).json({ error: 'Falta artefacto.' });
    const respuesta = await ejecutarProlog(`usar(${artefacto})`).catch(e => e.message);
    res.json({ ok: !respuesta.includes('ERROR'), respuesta });
});

// POST /api/reparar
app.post('/api/reparar', async (req, res) => {
    const { sistema } = req.body;
    if (!sistema) return res.status(400).json({ error: 'Falta sistema.' });
    const respuesta = await ejecutarProlog(`reparar(${sistema})`).catch(e => e.message);
    res.json({ ok: !respuesta.includes('ERROR'), respuesta });
});

// POST /api/rescatar
app.post('/api/rescatar', async (req, res) => {
    const { tripulante } = req.body;
    if (!tripulante) return res.status(400).json({ error: 'Falta tripulante.' });
    const respuesta = await ejecutarProlog(`rescatar(${tripulante})`).catch(e => e.message);
    res.json({ ok: !respuesta.includes('ERROR'), respuesta });
});

// GET /api/inventario
app.get('/api/inventario', async (req, res) => {
    const respuesta = await ejecutarProlog('que_tengo').catch(e => e.message);
    res.json({ ok: true, respuesta });
});

// GET /api/visitados
app.get('/api/visitados', async (req, res) => {
    const respuesta = await ejecutarProlog('modulos_visitados').catch(e => e.message);
    res.json({ ok: true, respuesta });
});

// GET /api/ruta?inicio=X&fin=Y
app.get('/api/ruta', async (req, res) => {
    const { inicio, fin } = req.query;
    if (!inicio || !fin) return res.status(400).json({ error: 'Faltan inicio y/o fin.' });
    const respuesta = await ejecutarProlog(`ruta(${inicio},${fin},C),write(C)`).catch(e => e.message);
    res.json({ ok: true, respuesta });
});

// GET /api/como_gano
app.get('/api/como_gano', async (req, res) => {
    const respuesta = await ejecutarProlog('como_gano').catch(e => e.message);
    res.json({ ok: true, respuesta });
});

// GET /api/verifica_gane
app.get('/api/verifica_gane', async (req, res) => {
    const respuesta = await ejecutarProlog('verifica_gane').catch(e => e.message);
    res.json({ ok: !respuesta.includes('no cumples'), respuesta });
});

// GET /api/donde_esta?objeto=fusible
app.get('/api/donde_esta', async (req, res) => {
    const { objeto } = req.query;
    if (!objeto) return res.status(400).json({ error: 'Falta objeto.' });
    const respuesta = await ejecutarProlog(`donde_esta(${objeto})`).catch(e => e.message);
    res.json({ ok: true, respuesta });
});

app.listen(PORT, () => {
    console.log(`\n Servidor Atlas en http://localhost:${PORT}`);
    console.log(` Prolog: ${JUEGO_PL}\n`);
});

// GET /api/reset — Reinicia el juego al estado inicial
app.get('/api/reset', (req, res) => {
    const fs = require('fs');
    const estadoPath = path.join(__dirname, 'prolog', 'estado.pl');
    const estadoInicial =
`% estado.pl — generado automaticamente
:- retractall(auxiliares:jugador(_)), assertz(auxiliares:jugador(puente_mando)).
:- retractall(auxiliares:artefactosLogrados(_)), assertz(auxiliares:artefactosLogrados([])).
:- retractall(auxiliares:usado(_)), assertz(auxiliares:usado([])).
:- retractall(auxiliares:lugares(_)), assertz(auxiliares:lugares([puente_mando])).
:- retractall(auxiliares:reparados(_)), assertz(auxiliares:reparados([])).
:- retractall(auxiliares:rescatados(_)), assertz(auxiliares:rescatados([])).
:- retractall(hechos:sistema(_,_,_,_)).
:- assertz(hechos:sistema(modulo_energia,energia,[fusible],fallo)).
:- assertz(hechos:sistema(laboratorio,comunicaciones,[fusible,traje_espacial],fallo)).
:- retractall(hechos:tripulante(_,_,_,_)).
:- assertz(hechos:tripulante(elena,modulo_energia,[energia],atrapado)).
:- assertz(hechos:tripulante(kai,enfermeria,[energia],atrapado)).
`;
    fs.writeFileSync(estadoPath, estadoInicial);
    res.json({ ok: true, respuesta: 'Juego reiniciado.' });
});
