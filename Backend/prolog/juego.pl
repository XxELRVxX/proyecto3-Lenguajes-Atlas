% ============================================================
%  juego.pl — Lógica principal del juego Operación Atlas
%  IC-4700 Lenguajes de Programación
% ============================================================

:- use_module('hechos.pl').
:- use_module('auxiliares.pl').

% -----------------------------------------------------------
%  conexion(+A, +B) — Bidireccional
% -----------------------------------------------------------
conexion(A, B) :- enlace(A, B).
conexion(A, B) :- enlace(B, A).

% -----------------------------------------------------------
%  lugar_bloqueado(+Lugar)
%  Verdadero si el lugar requiere un artefacto no usado aún.
% -----------------------------------------------------------
lugar_bloqueado(Lugar) :-
    necesita(Lugar, Objeto),
    usado(Usados),
    \+ member(Objeto, Usados).

% -----------------------------------------------------------
%  visita_requerida(+LugarDestino)
%  Verifica que el módulo previo requerido ya fue visitado.
% -----------------------------------------------------------
visita_requerida(LugarDestino) :-
    pasoPrevio(LugarDestino, LugarPrevio),
    lugares(Visitados),
    member(LugarPrevio, Visitados).

visita_requerida(LugarDestino) :-
    \+ pasoPrevio(LugarDestino, _).

% -----------------------------------------------------------
%  tomar(+Objeto)
%  Agrega artefacto al inventario. Guarda estado.
% -----------------------------------------------------------
tomar(Objeto) :-
    jugador(Lugar),
    artefacto(Objeto, Lugar),
    artefactosLogrados(Inventario),
    \+ member(Objeto, Inventario),
    retract(artefactosLogrados(Inventario)),
    assertz(artefactosLogrados([Objeto|Inventario])),
    guardar_estado,
    write('Tomaste: '), write(Objeto), nl.

tomar(Objeto) :-
    artefactosLogrados(Inventario),
    member(Objeto, Inventario),
    write('ERROR: Ya tienes '), write(Objeto), write(' en tu inventario.'), nl, fail.

tomar(Objeto) :-
    jugador(Lugar),
    \+ artefacto(Objeto, Lugar),
    write('ERROR: '), write(Objeto), write(' no esta en este modulo.'), nl, fail.

% -----------------------------------------------------------
%  usar(+Objeto)
%  Usa un artefacto para desbloquear módulos. Guarda estado.
% -----------------------------------------------------------
usar(Objeto) :-
    artefactosLogrados(Inventario),
    member(Objeto, Inventario),
    jugador(Lugar),
    conexion(Lugar, Destino),
    necesita(Destino, Objeto),
    usado(Usados),
    \+ member(Objeto, Usados),
    retract(usado(Usados)),
    assertz(usado([Objeto|Usados])),
    guardar_estado,
    write('Usaste '), write(Objeto), write(' y desbloqueaste acceso a '), write(Destino), nl.

usar(Objeto) :-
    \+ (artefactosLogrados(Inv), member(Objeto, Inv)),
    write('ERROR: No tienes '), write(Objeto), write(' en tu inventario.'), nl, fail.

usar(Objeto) :-
    write('ERROR: No puedes usar '), write(Objeto), write(' aqui.'), nl, fail.

% -----------------------------------------------------------
%  reparar(+Sistema)
%  Restaura un sistema crítico. Guarda estado.
% -----------------------------------------------------------
reparar(Sistema) :-
    jugador(Lugar),
    sistema(Lugar, Sistema, Artefactos, fallo),
    artefactosLogrados(Inventario),
    coincidencias(Inventario, Artefactos),
    reparados(Registro),
    \+ member(Sistema, Registro),
    retract(reparados(Registro)),
    assertz(reparados([Sistema|Registro])),
    retract(sistema(Lugar, Sistema, Artefactos, fallo)),
    assertz(sistema(Lugar, Sistema, Artefactos, restaurado)),
    guardar_estado,
    write('Sistema '), write(Sistema), write(' restaurado correctamente.'), nl.

reparar(Sistema) :-
    jugador(Lugar),
    sistema(Lugar, Sistema, Artefactos, fallo),
    artefactosLogrados(Inventario),
    \+ coincidencias(Inventario, Artefactos),
    write('ERROR: Te faltan artefactos. Necesitas: '), write(Artefactos), nl, fail.

reparar(_) :-
    write('ERROR: No hay sistema reparable aqui o ya fue reparado.'), nl, fail.

% -----------------------------------------------------------
%  rescatar(+Nombre)
%  Rescata un tripulante. Guarda estado.
% -----------------------------------------------------------
rescatar(Nombre) :-
    jugador(Lugar),
    tripulante(Nombre, Lugar, SistemasNecesarios, atrapado),
    reparados(Registro),
    coincidencias(Registro, SistemasNecesarios),
    rescatados(RescatadosActual),
    \+ member(Nombre, RescatadosActual),
    retract(tripulante(Nombre, Lugar, SistemasNecesarios, atrapado)),
    assertz(tripulante(Nombre, Lugar, SistemasNecesarios, rescatado)),
    retract(rescatados(RescatadosActual)),
    assertz(rescatados([Nombre|RescatadosActual])),
    guardar_estado,
    write('Rescataste a '), write(Nombre), write(' exitosamente.'), nl.

rescatar(Nombre) :-
    jugador(Lugar),
    tripulante(Nombre, Lugar, SistemasNecesarios, atrapado),
    reparados(Registro),
    \+ coincidencias(Registro, SistemasNecesarios),
    write('ERROR: Necesitas reparar primero: '), write(SistemasNecesarios), nl, fail.

rescatar(Nombre) :-
    write('ERROR: No puedes rescatar a '), write(Nombre), write(' aqui o ya fue rescatado.'), nl, fail.

% -----------------------------------------------------------
%  puedo_ir(+Hacia)
% -----------------------------------------------------------
puedo_ir(Hacia) :-
    jugador(Actual),
    conexion(Actual, Hacia),
    visita_requerida(Hacia),
    (necesita(Hacia, Objeto) -> (usado(Usados), member(Objeto, Usados)) ; true),
    (necesitaEstado(Hacia, Srv, Est) -> sistema(_, Srv, _, Est) ; true),
    write('Puedes ir a '), write(Hacia), nl.

puedo_ir(Hacia) :-
    write('ERROR: No puedes ir a '), write(Hacia), nl, fail.

% -----------------------------------------------------------
%  mover(+Lugar)
%  Mueve al jugador. Guarda estado.
% -----------------------------------------------------------
mover(Lugar) :-
    jugador(Actual),
    conexion(Actual, Lugar),
    visita_requerida(Lugar),
    \+ lugar_bloqueado(Lugar),
    (necesitaEstado(Lugar, Srv, Est) -> sistema(_, Srv, _, Est) ; true),
    retractall(jugador(_)),
    assertz(jugador(Lugar)),
    lugares(Visitados),
    (member(Lugar, Visitados) -> true ;
        (retract(lugares(Visitados)), assertz(lugares([Lugar|Visitados])))),
    guardar_estado,
    write('Te moviste a '), write(Lugar), nl.

mover(Lugar) :-
    write('ERROR: No puedes moverte a '), write(Lugar), nl, fail.

% -----------------------------------------------------------
%  donde_esta(+Objeto)
% -----------------------------------------------------------
donde_esta(Objeto) :-
    artefactosLogrados(Inventario),
    member(Objeto, Inventario),
    write(Objeto), write(' esta en tu inventario.'), nl, !.

donde_esta(Objeto) :-
    artefacto(Objeto, Lugar),
    write(Objeto), write(' esta en '), write(Lugar), nl, !.

donde_esta(Objeto) :-
    write(Objeto), write(' no fue encontrado.'), nl.

% -----------------------------------------------------------
%  que_tengo
% -----------------------------------------------------------
que_tengo :-
    artefactosLogrados(Inventario),
    write('Inventario actual:'), nl,
    leer_lista(Inventario).

% -----------------------------------------------------------
%  modulos_visitados
% -----------------------------------------------------------
modulos_visitados :-
    lugares(Visitados),
    write('Modulos visitados:'), nl,
    leer_lista(Visitados).

% -----------------------------------------------------------
%  ruta(+Inicio, +Fin, -Camino)
%  Backtracking para encontrar ruta entre módulos.
% -----------------------------------------------------------
ruta(Inicio, Fin, Camino) :-
    sub_ruta(Inicio, Fin, [Inicio], Camino).

sub_ruta(Fin, Fin, Camino, Camino).
sub_ruta(Actual, Fin, Visitados, Camino) :-
    conexion(Actual, Siguiente),
    \+ member(Siguiente, Visitados),
    append(Visitados, [Siguiente], NuevosVisitados),
    sub_ruta(Siguiente, Fin, NuevosVisitados, Camino).

% -----------------------------------------------------------
%  como_gano
% -----------------------------------------------------------
como_gano :-
    jugador(Inicio),
    nl,
    write('=== GUIA DE OBJETIVOS ==='), nl, nl,
    write('[ Sistemas a restaurar ]'), nl,
    forall(
        objetivoS(Sistema, restaurado),
        (
            sistema(Modulo, Sistema, Artefactos, Estado),
            (Estado = fallo -> Etiqueta = 'PENDIENTE' ; Etiqueta = 'LISTO'),
            write('  ['), write(Etiqueta), write('] '),
            write(Sistema), write(' en '), write(Modulo),
            write(' — requiere: '), write(Artefactos), nl
        )
    ),
    nl,
    write('[ Tripulantes a rescatar ]'), nl,
    forall(
        objetivoT(Nombre, rescatado),
        (
            tripulante(Nombre, Modulo, Sistemas, Estado),
            (Estado = atrapado -> Etiqueta = 'PENDIENTE' ; Etiqueta = 'RESCATADO'),
            write('  ['), write(Etiqueta), write('] '),
            write(Nombre), write(' en '), write(Modulo),
            write(' — necesita: '), write(Sistemas), nl
        )
    ),
    nl,
    write('[ Rutas desde tu posicion ]'), nl,
    forall(
        objetivoT(Nombre, _),
        (
            tripulante(Nombre, Destino, _, _),
            (ruta(Inicio, Destino, Camino)
                -> (write('  Hacia '), write(Nombre), write(': '), write(Camino), nl)
                ;  (write('  Sin ruta hacia '), write(Nombre), nl))
        )
    ), nl.

% -----------------------------------------------------------
%  verifica_gane
% -----------------------------------------------------------
verifica_gane :-
    forall(objetivoS(Sistema, restaurado), (reparados(R), member(Sistema, R))),
    forall(objetivoT(Nombre, rescatado),  (rescatados(Rs), member(Nombre, Rs))),
    lugares(Visitados),
    artefactosLogrados(Inventario),
    reparados(Reparados),
    rescatados(Rescatados),
    nl,
    write('*** OPERACION ATLAS COMPLETADA ***'), nl, nl,
    write('Ruta realizada:'),    nl, leer_lista(Visitados),  nl,
    write('Artefactos:'),        nl, leer_lista(Inventario), nl,
    write('Sistemas reparados:'),nl, leer_lista(Reparados),  nl,
    write('Tripulacion:'),       nl, leer_lista(Rescatados), nl,
    write('VICTORIA: todos los objetivos cumplidos.'), nl.

verifica_gane :-
    write('Aun no cumples todas las condiciones de victoria.'), nl, fail.

% -----------------------------------------------------------
%  estado_json
%  Imprime el estado como JSON para que Node lo parsee.
% -----------------------------------------------------------
estado_json :-
    jugador(Lugar),
    modulo(Lugar, Desc),
    artefactosLogrados(Inv),
    usado(Usados),
    reparados(Reps),
    rescatados(Resc),
    lugares(Visitados),
    findall(C, conexion(Lugar, C), Cons),
    findall(A, artefacto(A, Lugar), ArtsAqui),
    findall(T, tripulante(T, Lugar, _, atrapado), TripsAqui),
    findall(S, sistema(Lugar, S, _, fallo), SisAqui),
    format('{"lugar":"~w","descripcion":"~w","inventario":~w,"usados":~w,"reparados":~w,"rescatados":~w,"visitados":~w,"conexiones":~w,"artefactos_aqui":~w,"tripulantes_aqui":~w,"sistemas_aqui":~w}',
        [Lugar, Desc, Inv, Usados, Reps, Resc, Visitados, Cons, ArtsAqui, TripsAqui, SisAqui]).
