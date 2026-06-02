% ============================================================
%  hechos.pl — Base de conocimiento de Operación Atlas
% ============================================================

:- module(hechos, [
    modulo/2, artefacto/2, enlace/2,
    necesita/2, necesitaEstado/3, pasoPrevio/2,
    sistema/4, tripulante/4, objetivoS/2, objetivoT/2
]).

:- dynamic sistema/4.
:- dynamic tripulante/4.

% MÓDULOS
modulo(puente_mando,   "Centro principal de control de la estacion.").
modulo(laboratorio,    "Laboratorio cientifico parcialmente destruido.").
modulo(modulo_energia, "Modulo encargado del suministro energetico.").
modulo(enfermeria,     "Area medica de emergencia.").
modulo(modulo_escape,  "Zona de evacuacion orbital.").

% ENLACES
enlace(puente_mando, laboratorio).
enlace(laboratorio,  modulo_energia).
enlace(puente_mando, enfermeria).
enlace(enfermeria,   modulo_escape).

% ARTEFACTOS
artefacto(traje_espacial,    enfermeria).
artefacto(fusible,           laboratorio).
artefacto(tarjeta_seguridad, puente_mando).

% SISTEMAS (estado inicial — puede ser sobreescrito por estado.pl)
sistema(modulo_energia, energia,        [fusible],                 fallo).
sistema(laboratorio,    comunicaciones, [fusible, traje_espacial], fallo).

% TRIPULANTES (estado inicial — puede ser sobreescrito por estado.pl)
tripulante(elena, modulo_energia, [energia], atrapado).
tripulante(kai,   enfermeria,     [energia], atrapado).

% RESTRICCIONES
necesita(modulo_energia, traje_espacial).
necesita(modulo_escape,  tarjeta_seguridad).
necesitaEstado(modulo_escape, energia, restaurado).
pasoPrevio(modulo_escape, modulo_energia).

% OBJETIVOS
objetivoS(energia,        restaurado).
objetivoS(comunicaciones, restaurado).
objetivoT(elena,          rescatado).
