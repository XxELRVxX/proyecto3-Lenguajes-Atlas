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
