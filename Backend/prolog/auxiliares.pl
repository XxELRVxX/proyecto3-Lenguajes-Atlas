% ============================================================
%  auxiliares.pl — Estado dinámico y persistencia
% ============================================================

:- module(auxiliares, [
    jugador/1, artefactosLogrados/1, usado/1,
    lugares/1, reparados/1, rescatados/1,
    guardar_estado/0, leer_lista/1, coincidencias/2, eliminar/3
]).

:- dynamic jugador/1.
:- dynamic artefactosLogrados/1.
:- dynamic usado/1.
:- dynamic lugares/1.
:- dynamic reparados/1.
:- dynamic rescatados/1.

% Valores por defecto
jugador(puente_mando).
artefactosLogrados([]).
usado([]).
lugares([puente_mando]).
reparados([]).
rescatados([]).

% -----------------------------------------------------------
%  ruta_estado(-Path)
%  Calcula la ruta a estado.pl sin doble barra.
% -----------------------------------------------------------
ruta_estado(P) :-
    working_directory(Dir, Dir),
    ( sub_atom(Dir, _, 1, 0, '/') -> DirLimpio = Dir ; atom_concat(Dir, '/', DirLimpio) ),
    atom_concat(DirLimpio, 'prolog/estado.pl', P).

% -----------------------------------------------------------
%  guardar_estado/0
%  Guarda el estado completo en estado.pl como hechos est_*.
% -----------------------------------------------------------
guardar_estado :-
    jugador(J),
    artefactosLogrados(Inv),
    usado(Us),
    lugares(Lug),
    reparados(Rep),
    rescatados(Resc),
    findall(est_sistema(M,S,A,E),  hechos:sistema(M,S,A,E),    Sistemas),
    findall(est_tripulante(N,M,Ss,E), hechos:tripulante(N,M,Ss,E), Trips),
    ruta_estado(P),
    open(P, write, Stream),
    writeln(Stream, '% estado.pl — generado automaticamente'),
    format(Stream, 'est_jugador(~w).~n',       [J]),
    format(Stream, 'est_inventario(~w).~n',    [Inv]),
    format(Stream, 'est_usado(~w).~n',         [Us]),
    format(Stream, 'est_lugares(~w).~n',       [Lug]),
    format(Stream, 'est_reparados(~w).~n',     [Rep]),
    format(Stream, 'est_rescatados(~w).~n',    [Resc]),
    maplist(escribir_termino(Stream), Sistemas),
    maplist(escribir_termino(Stream), Trips),
    close(Stream).

escribir_termino(Stream, Term) :-
    format(Stream, '~w.~n', [Term]).

% -----------------------------------------------------------
%  Utilidades
% -----------------------------------------------------------
leer_lista([]).
leer_lista([H|T]) :- write('  - '), write(H), nl, leer_lista(T).

coincidencias(_, []).
coincidencias(L, [H|T]) :- member(H, L), coincidencias(L, T).

eliminar(_, [], []).
eliminar(X, [X|T], T) :- !.
eliminar(X, [C|T], [C|R]) :- eliminar(X, T, R).
