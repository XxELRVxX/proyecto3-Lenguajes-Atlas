# Instituto Tecnológico de Costa Rica
## Escuela de Ingeniería en Computación
### Curso: Lenguajes de Programación (Semestre 1, 2026)
**Profesor:** Allan Rodríguez Dávila  
**Proyecto Programado #3:** Operación Atlas  

---

## 1. Introducción
El paradigma de programación lógica se fundamenta en la definición de hechos relacionales y reglas de inferencia deductiva, permitiendo al sistema razonar y resolver problemas mediante el mecanismo de unificación y resolución por *backtracking*. El presente proyecto implementa un entorno interactivo y dinámico denominado **"Operación Atlas"**, una aventura espacial de toma de decisiones ambientada en una estación orbital averiada. El core del sistema (motor lúdico, reglas de restricción física, estados espaciales y árboles de caminos óptimos) se encuentra desarrollado de manera íntegra bajo el paradigma lógico en **Prolog (SWI-Prolog)**, mientras que el control de la interfaz y la entrega de datos al usuario se implementa mediante una arquitectura desacoplada utilizando **Node.js/Express** como middleware y **React** para el Frontend.

## 2. Arquitectura del Sistema y Persistencia Autónoma
Para asegurar la naturaleza declarativa evaluada en el curso, el backend lógico es completamente autónomo y administra su propio estado a través de archivos planos (`estado.pl`). La comunicación sigue el siguiente flujo de componentes:

1. **Frontend (React):** Despliega la cabina de control visual del juego de forma dinámica. Envía solicitudes HTTP síncronas (`POST /api/accion` o `GET /api/estado_json`) disparadas por eventos de la interfaz de usuario.
2. **Middleware (Node.js + Express):** Actúa como un puente translacional sin estado (*stateless*). Recibe las peticiones HTTP, levanta un subproceso del intérprete `swipl` pasando como metas la carga de las bases y la ejecución de la consulta de forma atómica.
3. **Backend Lógico (Prolog):** Al invocarse, el predicado ejecutor carga el archivo dinámico `estado.pl` (si existe) mediante `cargar_estado/0`, realiza las validaciones, actualiza los hechos mutables en memoria, escribe el nuevo estado serializado invocando a `guardar_estado/0` empleando predicados como `tell/1` y `format/2`, y finalmente escupe a la salida estándar (`stdout`) un string formateado en JSON puro a través de `estado_json/0` que Node.js parsea y retorna a la UI.

## 3. Estructura Estricta de Archivos y Directorios
El código fuente del ecosistema de la Operación Atlas se encuentra estrictamente modularizado en las siguientes dimensiones funcionales:

### Directorio del Backend (`/Backend`)
* **`prolog/hechos.pl`:** Actúa como la ontología base y almacenamiento estático inicial de la estación. Define las locaciones válidas (`modulo/2`), los pasillos y uniones espaciales (`enlace/2`), la ubicación predeterminada de las herramientas (`artefacto/2`), las averías sistémicas de las consolas de control (`sistema/4`) y el personal superviviente en peligro (`tripulante/4`).
* **`prolog/auxiliares.pl`:** Contiene la definición de los predicados mutables y dinámicos globales (`jugador/1`, `artefactosLogrados/1`, `usado/1`, `lugares/1`, `reparados/1`, `rescatados/1`). Implementa de manera nativa la automatización de la persistencia de archivos a través de un flujo físico con `open/3`, `format/3` y `close/1`, encapsulando el aislamiento de los datos.
* **`prolog/juego.pl`:** Representa el núcleo procedimental lógico del videojuego. Implementa de forma estricta las mecánicas requeridas en las especificaciones del proyecto:
  * `cargar_estado/0` y `guardar_estado/0`: Administradores nativos del ciclo de vida y persistencia síncrona de datos en disco utilizando prefijos lógicos estables (`est_*`).
  * `puedo_ir/1`: Valida adyacencias físicas en el mapa de grafos, historiales de visitas secuenciales de tránsito obligatorio (`visita_requerida/1`), y cerraduras condicionales basadas en el inventario.
  * `mover/1`: Altera la ubicación del cosmonauta actualizando concurrentemente el histórico cronológico de navegación.
  * `tomar/1` y `usar/1`: Mecánicas de inventario dinámico con desunificación de variables sobre los hechos dinámicos.
  * `reparar/1` y `rescatar/1`: Modificadores estructurales que habilitan el rescate de tripulantes y la remoción de bloqueos sistémicos en la estación.
  * `ruta/3`: Algoritmo matemático implementado con backtracking nativo para el cálculo de vectores de navegación entre dos salas cualesquiera, previniendo ciclos infinitos mediante listas de exclusión de nodos visitados.
  * `como_gano/0` y `verifica_gane/0`: Motores predictivos encargados de evaluar si la conjunción de metas lógicas pendientes se ha satisfecho plenamente.
  * `estado_json/0`: Serializador lógico que mapea variables lógicas a cadenas de texto formateadas en JSON nativo.
* **`server.js`:** Servidor HTTP construido sobre la plataforma Express. Implementa la instanciación de procesos hijos por medio de `child_process.spawn` y expone endpoints parametrizados REST (`/api/estado_json`, `/api/accion`, `/api/reset`, `/api/verifica_gane`, `/api/donde_esta`).

### Directorio del Frontend (`/Frontend`)
* **`src/App.jsx`:** Componente raíz unificado de la interfaz web. Administra el estado reactivo del juego (`gameState`, `logs`) y consume asíncronamente el API de Node.js empleando promesas nativas. Renderiza un tablero de control espacial estilizado con soporte de renderizado dinámico condicional.
* **`src/index.js`:** Punto de entrada secundario que inicializa e inyecta la aplicación de React en el DOM del navegador.
* **`public/index.html`:** Plantilla HTML base configurada con tipografías monoespaciadas y estilos globales adaptados a entornos oscuros industriales.

## 4. Descripción del Entorno Orbital (Base de Conocimiento)
La estación orbital simulada se compone lógicamente de 5 locaciones interconectadas jerárquicamente a través de pasillos de tránsito controlado:

1. **`puente_mando`:** Punto de inicio de la misión y nodo raíz de la topología. Alberga la `tarjeta_seguridad`. Conecta bidireccionalmente con el `laboratorio` y la `enfermeria`.
2. **`laboratorio`:** Estación científica superior. Contiene el ítem de soporte `fusible` e incluye el sistema de `comunicaciones` dañado. Permite el tránsito hacia el puente de mando y hacia el módulo de energía.
3. **`enfermeria`:** Bahía médica inferior. Contiene guardado el `traje_espacial` y resguarda al tripulante herido `kai`. Enlaza directamente con el puente de mando y con el módulo de escape.
4. **`modulo_energia`:** Zona de reactores de alta tensión. El acceso físico está bloqueado lógicamente por la regla de adyacencia condicionada al uso obligatorio del `traje_espacial`. Contiene el sistema de `energia` principal averiado y resguarda a la tripulante atrapada `elena`.
5. **`modulo_escape`:** Bahía de evacuación y punto de victoria final. Se encuentra bloqueado lógicamente por dos factores de restricción concurrentes: la cerradura de acceso requiere haber usado la `tarjeta_seguridad`, y el estado global de la nave exige que el sistema de `energia` del reactor adyacente haya sido previamente restaurado con éxito.

 ## 5. Manual de Configuración, Instalación y Ejecución
 Para asegurar la correcta ejecución del ecosistema multiplataforma, verifique contar con las siguientes herramientas globales en su sistema operativo:
 
1. **SWI-Prolog Intérprete Oficial:** Asegúrese de tener el ejecutable `swipl` correctamente añadido a las variables de entorno de su terminal de comandos.
2. **Node.js:** Versión de entorno de ejecución v16.0.0 o superior instalada de forma local.

## 6. Configuración e Inicio del Servidor Backend (Node.js + Prolog)
1. Abra una ventana de su terminal de comandos en la carpeta raíz del proyecto y navegue al directorio del servidor de aplicaciones: `cd Backend`
2. Realice la instalación limpia de las dependencias de red:
