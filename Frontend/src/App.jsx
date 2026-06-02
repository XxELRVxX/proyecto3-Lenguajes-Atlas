// ============================================================
//  App.jsx — Interfaz principal de Operación Atlas
//  Juego de aventura espacial en Prolog con interfaz React
// ============================================================

import { useState, useEffect, useRef, useCallback } from "react";

const API = "http://localhost:3001/api";

// Mapa del juego (espejo de hechos.pl para la UI)
const MAPA_CONEXIONES = {
  puente_mando:   ["laboratorio", "enfermeria"],
  laboratorio:    ["puente_mando", "modulo_energia"],
  modulo_energia: ["laboratorio"],
  enfermeria:     ["puente_mando", "modulo_escape"],
  modulo_escape:  ["enfermeria"],
};

const ARTEFACTOS_EN = {
  puente_mando: ["tarjeta_seguridad"],
  laboratorio:  ["fusible"],
  enfermeria:   ["traje_espacial"],
};

const TRIPULANTES_EN = {
  modulo_energia: ["elena"],
  enfermeria:     ["kai"],
};

const SISTEMAS_EN = {
  modulo_energia: ["energia"],
  laboratorio:    ["comunicaciones"],
};

const DESCRIPCIONES = {
  puente_mando:   "Centro principal de control de la estación. Los paneles parpadean con luz roja de emergencia.",
  laboratorio:    "Laboratorio científico parcialmente destruido. Equipos dañados flotan en gravedad cero.",
  modulo_energia: "Módulo encargado del suministro energético. El zumbido de los generadores es irregular.",
  enfermeria:     "Área médica de emergencia. Suministros médicos esparcidos por el suelo.",
  modulo_escape:  "Zona de evacuación orbital. Las cápsulas de escape esperan en posición de lanzamiento.",
};

const NOMBRES_DISPLAY = {
  puente_mando:      "Puente de Mando",
  laboratorio:       "Laboratorio",
  modulo_energia:    "Módulo de Energía",
  enfermeria:        "Enfermería",
  modulo_escape:     "Módulo de Escape",
  traje_espacial:    "Traje Espacial",
  fusible:           "Fusible",
  tarjeta_seguridad: "Tarjeta de Seguridad",
  energia:           "Sistema de Energía",
  comunicaciones:    "Sistema de Comunicaciones",
  elena:             "Elena",
  kai:               "Kai",
};

function nombre(id) {
  return NOMBRES_DISPLAY[id] || id.replace(/_/g, " ");
}

// ============================================================
export default function App() {
  // Estado del juego en React
  const [lugar, setLugar]           = useState("puente_mando");
  const [inventario, setInventario] = useState([]);
  const [usados, setUsados]         = useState([]);
  const [reparados, setReparados]   = useState([]);
  const [rescatados, setRescatados] = useState([]);
  const [visitados, setVisitados]   = useState(["puente_mando"]);

  // UI
  const [log, setLog]               = useState([
    "[ SISTEMA DE IA ATLAS INICIALIZADO ]",
    "Ingeniero, la tormenta solar ha dañado sistemas críticos.",
    "Localización actual: Puente de Mando.",
    "Recorra la estación, repare los sistemas y rescate a la tripulación.",
  ]);
  const [panel, setPanel]           = useState(null); // 'inventario'|'visitados'|'ruta'|'como_gano'|'victoria'
  const [panelTexto, setPanelTexto] = useState("");
  const [cargando, setCargando]     = useState(false);
  const [victoria, setVictoria]     = useState(false);
  const [rutaInicio, setRutaInicio] = useState("");
  const [rutaFin, setRutaFin]       = useState("");

  const logRef = useRef(null);

  useEffect(() => {
    if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight;
  }, [log]);

  // Agrega líneas al log narrativo
  const log_ = useCallback((...lineas) => {
    setLog(prev => [...prev, ...lineas]);
  }, []);

  // Llamada genérica a la API
  async function api(url, metodo = "GET", body = null) {
    setCargando(true);
    try {
      const opts = { method: metodo, headers: { "Content-Type": "application/json" } };
      if (body) opts.body = JSON.stringify(body);
      const res  = await fetch(url, opts);
      const data = await res.json();
      return data;
    } catch {
      return { ok: false, respuesta: "Error de conexión con el servidor." };
    } finally {
      setCargando(false);
    }
  }

  // ── Acciones del juego ─────────────────────────────────────

  async function mover(destino) {
    const data = await api(`${API}/mover`, "POST", { destino });
    log_(`▶ Intentando mover a ${nombre(destino)}...`, data.respuesta);
    if (data.ok && data.respuesta && !data.respuesta.includes("ERROR")) {
      setLugar(destino);
      if (!visitados.includes(destino)) setVisitados(v => [...v, destino]);
      log_(`📍 Ahora estás en: ${nombre(destino)}`);
      // Verificar victoria automáticamente
      const gane = await api(`${API}/verifica_gane`);
      if (gane.respuesta && gane.respuesta.includes("COMPLETADA")) {
        setVictoria(true);
        setPanelTexto(gane.respuesta);
        setPanel("victoria");
        log_("🏆 ¡OPERACIÓN ATLAS COMPLETADA!");
      }
    }
  }

  async function tomar(artefacto) {
    const data = await api(`${API}/tomar`, "POST", { artefacto });
    log_(`▶ Intentando tomar ${nombre(artefacto)}...`, data.respuesta);
    if (data.ok && !data.respuesta.includes("ERROR")) {
      setInventario(i => [...i, artefacto]);
    }
  }

  async function usar(artefacto) {
    const data = await api(`${API}/usar`, "POST", { artefacto });
    log_(`▶ Intentando usar ${nombre(artefacto)}...`, data.respuesta);
    if (data.ok && !data.respuesta.includes("ERROR")) {
      setUsados(u => [...u, artefacto]);
    }
  }

  async function reparar(sistema) {
    const data = await api(`${API}/reparar`, "POST", { sistema });
    log_(`▶ Intentando reparar ${nombre(sistema)}...`, data.respuesta);
    if (data.ok && !data.respuesta.includes("ERROR")) {
      setReparados(r => [...r, sistema]);
    }
  }

  async function rescatar(tripulante) {
    const data = await api(`${API}/rescatar`, "POST", { tripulante });
    log_(`▶ Intentando rescatar a ${nombre(tripulante)}...`, data.respuesta);
    if (data.ok && !data.respuesta.includes("ERROR")) {
      setRescatados(r => [...r, tripulante]);
    }
  }

  async function verInventario() {
    const data = await api(`${API}/inventario`);
    setPanelTexto(data.respuesta || "Inventario vacío.");
    setPanel("inventario");
  }

  async function verVisitados() {
    const data = await api(`${API}/visitados`);
    setPanelTexto(data.respuesta || "");
    setPanel("visitados");
  }

  async function verComoGano() {
    const data = await api(`${API}/como_gano`);
    setPanelTexto(data.respuesta || "");
    setPanel("como_gano");
  }

  async function calcularRuta() {
    if (!rutaInicio || !rutaFin) { setPanelTexto("Selecciona inicio y fin."); setPanel("ruta"); return; }
    const data = await api(`${API}/ruta?inicio=${rutaInicio}&fin=${rutaFin}`);
    setPanelTexto(data.respuesta || "Sin ruta encontrada.");
    setPanel("ruta");
  }

  async function resetJuego() {
    await api(`${API}/reset`);
    setLugar("puente_mando");
    setInventario([]);
    setUsados([]);
    setReparados([]);
    setRescatados([]);
    setVisitados(["puente_mando"]);
    setPanel(null);
    setVictoria(false);
    setLog([
      "[ SISTEMA REINICIADO ]",
      "Ingeniero, la tormenta solar ha dañado sistemas críticos.",
      "Localización actual: Puente de Mando.",
    ]);
  }

  async function verificarVictoria() {
    const data = await api(`${API}/verifica_gane`);
    if (data.respuesta && data.respuesta.includes("COMPLETADA")) {
      setVictoria(true);
      setPanelTexto(data.respuesta);
      setPanel("victoria");
    } else {
      setPanelTexto(data.respuesta || "");
      setPanel("victoria");
    }
  }

  // ── Datos contextuales ────────────────────────────────────

  const conexiones      = MAPA_CONEXIONES[lugar] || [];
  const artefactosAqui  = (ARTEFACTOS_EN[lugar] || []).filter(a => !inventario.includes(a));
  const tripulantesAqui = (TRIPULANTES_EN[lugar] || []).filter(t => !rescatados.includes(t));
  const sistemasAqui    = (SISTEMAS_EN[lugar] || []).filter(s => !reparados.includes(s));
  const usables         = inventario.filter(a => !usados.includes(a));

  // ── Render ────────────────────────────────────────────────
  return (
    <div style={s.root}>
      {/* HEADER */}
      <div style={s.header}>
        <div>
          <span style={s.titulo}>⬡ OPERACIÓN ATLAS</span>
          <span style={s.chip}>ESTACIÓN AURORA</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          {cargando && <span style={s.cargando}>● PROCESANDO</span>}
          <span style={s.ubicacion}>📍 {nombre(lugar).toUpperCase()}</span>
        </div>
      </div>

      <div style={s.cuerpo}>
        {/* ── COLUMNA IZQUIERDA ───────────────────── */}
        <div style={s.colIzq}>

          {/* Imagen del módulo */}
          <div style={s.imgBox}>
            <div style={s.imgPlaceholder}>
              <div style={s.imgIcon}>
                {lugar === "puente_mando"   && "🛸"}
                {lugar === "laboratorio"    && "🔬"}
                {lugar === "modulo_energia" && "⚡"}
                {lugar === "enfermeria"     && "🏥"}
                {lugar === "modulo_escape"  && "🚀"}
              </div>
              <div style={s.imgNombre}>{nombre(lugar)}</div>
            </div>
            <img
              src={`/imagenes/${lugar}.jpg`}
              alt={lugar}
              style={s.img}
              onError={e => { e.target.style.display = "none"; }}
            />
          </div>

          {/* Descripción del módulo */}
          <div style={s.descripcion}>{DESCRIPCIONES[lugar]}</div>

          {/* Log narrativo */}
          <div style={s.logBox} ref={logRef}>
            {log.map((l, i) => (
              <div key={i} style={{
                ...s.logLinea,
                color: l.startsWith("▶") ? "#4af" : l.startsWith("ERROR") ? "#f64" : l.startsWith("🏆") ? "#fa4" : "#b0c8e0",
                fontWeight: l.startsWith("[") ? "bold" : "normal",
              }}>
                {l}
              </div>
            ))}
          </div>

          {/* Botones de acción contextuales */}
          <div style={s.accionesBox}>
            {conexiones.length > 0 && (
              <Grupo titulo="🚀 MOVERSE A">
                {conexiones.map(d => (
                  <Btn key={d} color="#1a6fff" onClick={() => mover(d)}>{nombre(d)}</Btn>
                ))}
              </Grupo>
            )}
            {artefactosAqui.length > 0 && (
              <Grupo titulo="📦 TOMAR ARTEFACTO">
                {artefactosAqui.map(a => (
                  <Btn key={a} color="#22aa55" onClick={() => tomar(a)}>{nombre(a)}</Btn>
                ))}
              </Grupo>
            )}
            {usables.length > 0 && (
              <Grupo titulo="🔧 USAR ARTEFACTO">
                {usables.map(a => (
                  <Btn key={a} color="#cc7722" onClick={() => usar(a)}>{nombre(a)}</Btn>
                ))}
              </Grupo>
            )}
            {sistemasAqui.length > 0 && (
              <Grupo titulo="⚡ REPARAR SISTEMA">
                {sistemasAqui.map(s => (
                  <Btn key={s} color="#9922cc" onClick={() => reparar(s)}>{nombre(s)}</Btn>
                ))}
              </Grupo>
            )}
            {tripulantesAqui.length > 0 && (
              <Grupo titulo="🧑‍🚀 RESCATAR TRIPULANTE">
                {tripulantesAqui.map(t => (
                  <Btn key={t} color="#cc2244" onClick={() => rescatar(t)}>{nombre(t)}</Btn>
                ))}
              </Grupo>
            )}
            {conexiones.length === 0 && artefactosAqui.length === 0 &&
             sistemasAqui.length === 0 && tripulantesAqui.length === 0 && (
              <span style={{ color: "#445", fontSize: 12 }}>Sin acciones disponibles aquí.</span>
            )}
          </div>
        </div>

        {/* ── COLUMNA DERECHA ─────────────────────── */}
        <div style={s.colDer}>
          <div style={s.panelTitulo}>PANEL DE CONTROL</div>

          {/* Botones de consulta */}
          <BtnConsulta onClick={verInventario}>🎒 Inventario</BtnConsulta>
          <BtnConsulta onClick={verVisitados}>🗺️ Módulos visitados</BtnConsulta>
          <BtnConsulta onClick={verComoGano}>❓ ¿Cómo gano?</BtnConsulta>
          <BtnConsulta onClick={verificarVictoria}>🏆 Verificar victoria</BtnConsulta>
          <BtnConsulta onClick={resetJuego}>🔄 Reiniciar juego</BtnConsulta>

          {/* Calcular ruta */}
          <div style={s.rutaBox}>
            <div style={s.rutaTitulo}>📍 CALCULAR RUTA</div>
            <select style={s.select} value={rutaInicio} onChange={e => setRutaInicio(e.target.value)}>
              <option value="">Origen...</option>
              {Object.keys(MAPA_CONEXIONES).map(m =>
                <option key={m} value={m}>{nombre(m)}</option>
              )}
            </select>
            <select style={{ ...s.select, marginTop: 4 }} value={rutaFin} onChange={e => setRutaFin(e.target.value)}>
              <option value="">Destino...</option>
              {Object.keys(MAPA_CONEXIONES).map(m =>
                <option key={m} value={m}>{nombre(m)}</option>
              )}
            </select>
            <BtnConsulta onClick={calcularRuta}>Calcular</BtnConsulta>
          </div>

          {/* Panel resultado */}
          {panel && (
            <div style={{ ...s.resultado, borderColor: panel === "victoria" ? "#fa4" : "#1a3a5c" }}>
              <div style={s.resultadoHeader}>
                <span style={{ color: panel === "victoria" ? "#fa4" : "#4af", fontSize: 11, fontWeight: "bold" }}>
                  {panel === "victoria" && "🏆 "}
                  {panel.replace(/_/g, " ").toUpperCase()}
                </span>
                <button onClick={() => setPanel(null)} style={s.btnX}>✕</button>
              </div>
              <pre style={s.pre}>{panelTexto}</pre>
            </div>
          )}

          {/* Inventario rápido */}
          <div style={s.invRapido}>
            <div style={s.rutaTitulo}>INVENTARIO RÁPIDO</div>
            {inventario.length === 0
              ? <span style={{ color: "#445", fontSize: 11 }}>Vacío</span>
              : inventario.map(a => (
                  <div key={a} style={s.badge}>
                    {usados.includes(a) ? "✓ " : "○ "}{nombre(a)}
                  </div>
                ))
            }
          </div>

          {/* Progreso de objetivos */}
          <div style={s.invRapido}>
            <div style={s.rutaTitulo}>OBJETIVOS</div>
            <div style={s.objetivo}>
              {reparados.includes("energia")        ? "✅" : "⬜"} Energía reparada
            </div>
            <div style={s.objetivo}>
              {reparados.includes("comunicaciones") ? "✅" : "⬜"} Comunicaciones
            </div>
            <div style={s.objetivo}>
              {rescatados.includes("elena")         ? "✅" : "⬜"} Elena rescatada
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Subcomponentes ────────────────────────────────────────────

function Grupo({ titulo, children }) {
  return (
    <div style={{ marginBottom: 10 }}>
      <div style={{ color: "#556", fontSize: 10, letterSpacing: 2, marginBottom: 5 }}>{titulo}</div>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>{children}</div>
    </div>
  );
}

function Btn({ children, onClick, color }) {
  return (
    <button onClick={onClick} style={{
      background: "transparent",
      border: `1px solid ${color}`,
      color,
      padding: "5px 12px",
      cursor: "pointer",
      fontSize: 12,
      fontFamily: "'Courier New', monospace",
      borderRadius: 2,
      transition: "background 0.15s",
    }}
    onMouseEnter={e => e.target.style.background = color + "22"}
    onMouseLeave={e => e.target.style.background = "transparent"}
    >
      {children}
    </button>
  );
}

function BtnConsulta({ children, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: "100%",
      background: "transparent",
      border: "1px solid #1a3a5c",
      color: "#7ab",
      padding: "8px 10px",
      textAlign: "left",
      cursor: "pointer",
      fontSize: 12,
      fontFamily: "'Courier New', monospace",
      marginBottom: 4,
      transition: "border-color 0.15s",
    }}
    onMouseEnter={e => e.target.style.borderColor = "#4af"}
    onMouseLeave={e => e.target.style.borderColor = "#1a3a5c"}
    >
      {children}
    </button>
  );
}

// ── Estilos ───────────────────────────────────────────────────

const s = {
  root: {
    background: "#0a0e14",
    minHeight: "100vh",
    color: "#c8d8e8",
    fontFamily: "'Courier New', monospace",
    display: "flex",
    flexDirection: "column",
  },
  header: {
    background: "#060a10",
    borderBottom: "1px solid #1a3a5c",
    padding: "10px 20px",
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
  },
  titulo: { color: "#4af", fontWeight: "bold", fontSize: 18, letterSpacing: 4, marginRight: 12 },
  chip: { background: "#0d2040", color: "#446", fontSize: 10, letterSpacing: 3, padding: "3px 8px", border: "1px solid #1a3a5c" },
  cargando: { color: "#fa4", fontSize: 10, letterSpacing: 2, animation: "pulse 1s infinite" },
  ubicacion: { color: "#4af", fontSize: 11, letterSpacing: 2 },
  cuerpo: { display: "flex", flex: 1, overflow: "hidden" },
  colIzq: { flex: 1, display: "flex", flexDirection: "column", borderRight: "1px solid #1a3a5c", overflow: "hidden" },
  imgBox: { position: "relative", height: 220, background: "#050a10", flexShrink: 0 },
  imgPlaceholder: {
    position: "absolute", inset: 0,
    display: "flex", flexDirection: "column",
    alignItems: "center", justifyContent: "center",
    gap: 8,
  },
  imgIcon: { fontSize: 60, opacity: 0.3 },
  imgNombre: { color: "#1a3a5c", fontSize: 11, letterSpacing: 3, textTransform: "uppercase" },
  img: { position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover", opacity: 0.75 },
  descripcion: { padding: "10px 16px", color: "#556", fontSize: 12, borderBottom: "1px solid #111a22", fontStyle: "italic", flexShrink: 0 },
  logBox: { flex: 1, overflowY: "auto", padding: "10px 16px", minHeight: 80, maxHeight: 180 },
  logLinea: { fontSize: 12, lineHeight: 1.6, marginBottom: 1 },
  accionesBox: { padding: "10px 16px", borderTop: "1px solid #111a22", flexShrink: 0 },
  colDer: { width: 250, background: "#060a10", padding: "14px 12px", display: "flex", flexDirection: "column", gap: 4, overflowY: "auto" },
  panelTitulo: { color: "#4af", fontSize: 10, letterSpacing: 3, marginBottom: 8 },
  rutaBox: { marginTop: 8, marginBottom: 4 },
  rutaTitulo: { color: "#446", fontSize: 10, letterSpacing: 2, marginBottom: 5 },
  select: {
    width: "100%", background: "#0a0e14", border: "1px solid #1a3a5c",
    color: "#7ab", padding: "5px 8px", fontSize: 11,
    fontFamily: "'Courier New', monospace", cursor: "pointer",
  },
  resultado: {
    background: "#080c12", border: "1px solid",
    padding: 10, marginTop: 6, maxHeight: 220, overflowY: "auto",
  },
  resultadoHeader: { display: "flex", justifyContent: "space-between", marginBottom: 6 },
  btnX: { background: "none", border: "none", color: "#446", cursor: "pointer", fontSize: 12 },
  pre: { color: "#8ab", fontSize: 10, whiteSpace: "pre-wrap", margin: 0, fontFamily: "'Courier New', monospace" },
  invRapido: { marginTop: 8, paddingTop: 8, borderTop: "1px solid #111a22" },
  badge: { color: "#4af", fontSize: 10, marginBottom: 3 },
  objetivo: { fontSize: 11, color: "#7ab", marginBottom: 3 },
};
