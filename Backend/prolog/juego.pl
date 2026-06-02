% ============================================================
%  juego.pl — Lógica principal de Operación Atlas
% ============================================================

:- use_module('hechos.pl').
:- use_module('auxiliares.pl').

% Predicados temporales para leer estado.pl
:- dynamic est_jugador/1, est_inventario/1, est_usado/1.
:- dynamic est_lugares/1, est_reparados/1, est_rescatados/1.
:- dynamic est_sistema/4, est_tripulante/4.

% -----------------------------------------------------------
%  cargar_estado/0
%  Lee estado.pl y aplica cada valor al estado dinámico.
%  Se invoca explícitamente desde cada predicado de acción.
% -----------------------------------------------------------
cargar_estado :-
    working_directory(Dir, Dir),
    atomic_list_concat([Dir, 'prolog/estado.pl'], P),
    ( exists_file(P) ->
        (
            % Limpiar predicados est_* anteriores
            retractall(est_jugador(_)),
            retractall(est_inventario(_)),
            retractall(est_usado(_)),
            retractall(est_lugares(_)),
            retractall(est_reparados(_)),
            retractall(est_rescatados(_)),
            retractall(est_sistema(_,_,_,_)),
            retractall(est_tripulante(_,_,_,_)),
            % Cargar el archivo
            load_files(P, [silent(true)]),
            % Aplicar estado del jugador
            ( est_jugador(J)       -> retractall(jugador(_)),            assertz(jugador(J))             ; true ),
            ( est_inventario(Inv)  -> retractall(artefactosLogrados(_)), assertz(artefactosLogrados(Inv)) ; true ),
            ( est_usado(Us)        -> retractall(usado(_)),              assertz(usado(Us))              ; true ),
            ( est_lugares(Lug)     -> retractall(lugares(_)),            assertz(lugares(Lug))           ; true ),
            ( est_reparados(Rep)   -> retractall(reparados(_)),          assertz(reparados(Rep))         ; true ),
            ( est_rescatados(Resc) -> retractall(rescatados(_)),         assertz(rescatados(Resc))       ; true ),
            % Aplicar sistemas
            retractall(sistema(_,_,_,_)),
            forall(est_sistema(M,S,A,E), assertz(sistema(M,S,A,E))),
            % Aplicar tripulantes
            retractall(tripulante(_,_,_,_)),
            forall(est_tripulante(N,M,Ss,E), assertz(tripulante(N,M,Ss,E)))
        )
    ;
        true
    ).

% -----------------------------------------------------------
%  conexion/2 — Bidireccional
% -----------------------------------------------------------
conexion(A, B) :- enlace(A, B).
conexion(A, B) :- enlace(B, A).

% -----------------------------------------------------------
%  lugar_bloqueado/1
% -----------------------------------------------------------
lugar_bloqueado(Lugar) :-
    necesita(Lugar, Objeto),
    usado(Usados),
    \+ member(Objeto, Usados).

% -----------------------------------------------------------
%  visita_requerida/1
% -----------------------------------------------------------
visita_requerida(Dest) :-
    pasoPrevio(Dest, Previo),
    lugares(Vis),
    member(Previo, Vis).
visita_requerida(Dest) :-
    \+ pasoPrevio(Dest, _).

% -----------------------------------------------------------
%  tomar/1
% -----------------------------------------------------------
tomar(Objeto) :-
    cargar_estado,
    jugador(Lugar),
    artefacto(Objeto, Lugar),
    artefactosLogrados(Inv),
    \+ member(Objeto, Inv),
    retract(artefactosLogrados(Inv)),
    assertz(artefactosLogrados([Objeto|Inv])),
    guardar_estado,
    write('Tomaste: '), write(Objeto), nl.

tomar(Objeto) :-
    cargar_estado,
    artefactosLogrados(Inv), member(Objeto, Inv),
    write('ERROR: Ya tienes '), write(Objeto), nl, fail.

tomar(Objeto) :-
    cargar_estado,
    jugador(Lugar), \+ artefacto(Objeto, Lugar),
    write('ERROR: '), write(Objeto), write(' no esta aqui.'), nl, fail.

% -----------------------------------------------------------
%  usar/1
% -----------------------------------------------------------
usar(Objeto) :-
    cargar_estado,
    artefactosLogrados(Inv), member(Objeto, Inv),
    jugador(Lugar),
    conexion(Lugar, Destino),
    necesita(Destino, Objeto),
    usado(Us), \+ member(Objeto, Us),
    retract(usado(Us)),
    assertz(usado([Objeto|Us])),
    guardar_estado,
    write('Usaste '), write(Objeto), write(' — desbloqueaste '), write(Destino), nl.

usar(Objeto) :-
    cargar_estado,
    \+ (artefactosLogrados(Inv), member(Objeto, Inv)),
    write('ERROR: No tienes '), write(Objeto), nl, fail.

usar(Objeto) :-
    cargar_estado,
    write('ERROR: No puedes usar '), write(Objeto), write(' aqui.'), nl, fail.

% -----------------------------------------------------------
%  reparar/1
% -----------------------------------------------------------
reparar(Sistema) :-
    cargar_estado,
    jugador(Lugar),
    sistema(Lugar, Sistema, Arts, fallo),
    artefactosLogrados(Inv),
    coincidencias(Inv, Arts),
    reparados(Rep), \+ member(Sistema, Rep),
    retract(reparados(Rep)),
    assertz(reparados([Sistema|Rep])),
    retract(sistema(Lugar, Sistema, Arts, fallo)),
    assertz(sistema(Lugar, Sistema, Arts, restaurado)),
    guardar_estado,
    write('Sistema '), write(Sistema), write(' restaurado.'), nl.

reparar(Sistema) :-
    cargar_estado,
    jugador(Lugar),
    sistema(Lugar, Sistema, Arts, fallo),
    artefactosLogrados(Inv),
    \+ coincidencias(Inv, Arts),
    write('ERROR: Faltan artefactos. Necesitas: '), write(Arts), nl, fail.

reparar(_) :-
    cargar_estado,
    write('ERROR: No hay sistema reparable aqui o ya fue reparado.'), nl, fail.

% -----------------------------------------------------------
%  rescatar/1
% -----------------------------------------------------------
rescatar(Nombre) :-
    cargar_estado,
    jugador(Lugar),
    tripulante(Nombre, Lugar, SisNec, atrapado),
    reparados(Rep), coincidencias(Rep, SisNec),
    rescatados(Resc), \+ member(Nombre, Resc),
    retract(tripulante(Nombre, Lugar, SisNec, atrapado)),
    assertz(tripulante(Nombre, Lugar, SisNec, rescatado)),
    retract(rescatados(Resc)),
    assertz(rescatados([Nombre|Resc])),
    guardar_estado,
    write('Rescataste a '), write(Nombre), nl.

rescatar(Nombre) :-
    cargar_estado,
    jugador(Lugar),
    tripulante(Nombre, Lugar, SisNec, atrapado),
    reparados(Rep), \+ coincidencias(Rep, SisNec),
    write('ERROR: Necesitas reparar: '), write(SisNec), nl, fail.

rescatar(Nombre) :-
    cargar_estado,
    write('ERROR: No puedes rescatar a '), write(Nombre), write(' aqui o ya fue rescatado.'), nl, fail.

% -----------------------------------------------------------
%  mover/1
% -----------------------------------------------------------
mover(Lugar) :-
    cargar_estado,
    jugador(Actual),
    conexion(Actual, Lugar),
    visita_requerida(Lugar),
    \+ lugar_bloqueado(Lugar),
    ( necesitaEstado(Lugar, Srv, Est) -> sistema(_, Srv, _, Est) ; true ),
    retractall(jugador(_)),
    assertz(jugador(Lugar)),
    lugares(Vis),
    ( member(Lugar, Vis) -> true
    ; ( retract(lugares(Vis)), assertz(lugares([Lugar|Vis])) ) ),
    guardar_estado,
    write('Te moviste a '), write(Lugar), nl.

mover(Lugar) :-
    cargar_estado,
    write('ERROR: No puedes moverte a '), write(Lugar), nl, fail.

% -----------------------------------------------------------
%  Consultas
% -----------------------------------------------------------
donde_esta(Objeto) :-
    cargar_estado,
    artefactosLogrados(Inv), member(Objeto, Inv),
    write(Objeto), write(' esta en tu inventario.'), nl, !.
donde_esta(Objeto) :-
    cargar_estado,
    artefacto(Objeto, Lugar),
    write(Objeto), write(' esta en '), write(Lugar), nl, !.
donde_esta(Objeto) :-
    write(Objeto), write(' no encontrado.'), nl.

que_tengo :-
    cargar_estado,
    artefactosLogrados(Inv),
    write('Inventario:'), nl,
    leer_lista(Inv).

modulos_visitados :-
    cargar_estado,
    lugares(Vis),
    write('Visitados:'), nl,
    leer_lista(Vis).

% -----------------------------------------------------------
%  ruta/3
% -----------------------------------------------------------
ruta(Ini, Fin, Camino) :- sub_ruta(Ini, Fin, [Ini], Camino).

sub_ruta(Fin, Fin, C, C).
sub_ruta(Act, Fin, Vis, C) :-
    conexion(Act, Sig),
    \+ member(Sig, Vis),
    append(Vis, [Sig], NV),
    sub_ruta(Sig, Fin, NV, C).

% -----------------------------------------------------------
%  como_gano/0
% -----------------------------------------------------------
como_gano :-
    cargar_estado,
    jugador(Ini),
    nl, write('=== GUIA DE OBJETIVOS ==='), nl, nl,
    write('[ Sistemas ]'), nl,
    forall(objetivoS(Sis, restaurado),
        ( sistema(Mod, Sis, Arts, Est),
          ( Est = fallo -> Etq = 'PENDIENTE' ; Etq = 'LISTO' ),
          format('  [~w] ~w en ~w — requiere: ~w~n', [Etq, Sis, Mod, Arts]) )),
    nl,
    write('[ Tripulantes ]'), nl,
    forall(objetivoT(Nom, rescatado),
        ( tripulante(Nom, Mod, Sis, Est),
          ( Est = atrapado -> Etq = 'PENDIENTE' ; Etq = 'RESCATADO' ),
          format('  [~w] ~w en ~w — necesita: ~w~n', [Etq, Nom, Mod, Sis]) )),
    nl,
    write('[ Rutas desde tu posicion ]'), nl,
    forall(objetivoT(Nom, _),
        ( tripulante(Nom, Dest, _, _),
          ( ruta(Ini, Dest, Cam)
          -> format('  Hacia ~w: ~w~n', [Nom, Cam])
          ;  format('  Sin ruta hacia ~w~n', [Nom]) ) )), nl.

% -----------------------------------------------------------
%  verifica_gane/0
% -----------------------------------------------------------
verifica_gane :-
    cargar_estado,
    forall(objetivoS(S, restaurado), (reparados(R), member(S, R))),
    forall(objetivoT(N, rescatado),  (rescatados(Rs), member(N, Rs))),
    lugares(Vis), artefactosLogrados(Inv),
    reparados(Rep), rescatados(Resc),
    nl, write('*** OPERACION ATLAS COMPLETADA ***'), nl, nl,
    write('Ruta:'),        nl, leer_lista(Vis),  nl,
    write('Artefactos:'),  nl, leer_lista(Inv),  nl,
    write('Sistemas:'),    nl, leer_lista(Rep),  nl,
    write('Tripulacion:'), nl, leer_lista(Resc), nl,
    write('VICTORIA TOTAL.'), nl.

verifica_gane :-
    write('Aun no cumples todas las condiciones.'), nl, fail.

% -----------------------------------------------------------
%  estado_json/0
% -----------------------------------------------------------
estado_json :-
    cargar_estado,
    jugador(Lugar),
    modulo(Lugar, Desc),
    artefactosLogrados(Inv),
    usado(Us),
    reparados(Rep),
    rescatados(Resc),
    lugares(Vis),
    findall(C, conexion(Lugar, C), Cons),
    findall(A, artefacto(A, Lugar), ArtsAqui),
    findall(T, tripulante(T, Lugar, _, atrapado), TripsAqui),
    findall(S, sistema(Lugar, S, _, fallo), SisAqui),
    format('{"lugar":"~w","descripcion":"~w","inventario":~w,"usados":~w,"reparados":~w,"rescatados":~w,"visitados":~w,"conexiones":~w,"artefactos_aqui":~w,"tripulantes_aqui":~w,"sistemas_aqui":~w}',
        [Lugar, Desc, Inv, Us, Rep, Resc, Vis, Cons, ArtsAqui, TripsAqui, SisAqui]).
