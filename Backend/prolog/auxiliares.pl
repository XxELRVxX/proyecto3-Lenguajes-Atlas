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

% Estado inicial por defecto (si no hay estado.pl)
jugador(puente_mando).
artefactosLogrados([]).
usado([]).
lugares([puente_mando]).
reparados([]).
rescatados([]).

% -----------------------------------------------------------
%  Carga estado.pl al arrancar si existe.
%  estado.pl usa retractall + assert para sobreescribir
%  los valores por defecto de arriba.
% -----------------------------------------------------------
:- working_directory(Dir, Dir),
   atomic_list_concat([Dir, '/prolog/estado.pl'], P),
   ( exists_file(P) -> consult(P) ; true ).

% -----------------------------------------------------------
%  guardar_estado/0
%  Guarda TODO el estado en estado.pl usando retractall+assert
%  para garantizar que al cargar no haya duplicados.
% -----------------------------------------------------------
guardar_estado :-
    jugador(J),
    artefactosLogrados(Inv),
    usado(Us),
    lugares(Lug),
    reparados(Rep),
    rescatados(Resc),
    findall(s(M,S,A,E), hechos:sistema(M,S,A,E),    Sistemas),
    findall(t(N,M,Ss,E), hechos:tripulante(N,M,Ss,E), Trips),
    working_directory(Dir, Dir),
    atomic_list_concat([Dir, '/prolog/estado.pl'], P),
    open(P, write, Stream),
    writeln(Stream, '% estado.pl — generado automaticamente'),
    % Estado del jugador — retractall + assert para no duplicar
    format(Stream, ':- retractall(auxiliares:jugador(_)), assertz(auxiliares:jugador(~w)).~n', [J]),
    format(Stream, ':- retractall(auxiliares:artefactosLogrados(_)), assertz(auxiliares:artefactosLogrados(~w)).~n', [Inv]),
    format(Stream, ':- retractall(auxiliares:usado(_)), assertz(auxiliares:usado(~w)).~n', [Us]),
    format(Stream, ':- retractall(auxiliares:lugares(_)), assertz(auxiliares:lugares(~w)).~n', [Lug]),
    format(Stream, ':- retractall(auxiliares:reparados(_)), assertz(auxiliares:reparados(~w)).~n', [Rep]),
    format(Stream, ':- retractall(auxiliares:rescatados(_)), assertz(auxiliares:rescatados(~w)).~n', [Resc]),
    % Sistemas — retractall + assert cada uno
    writeln(Stream, ':- retractall(hechos:sistema(_,_,_,_)).'),
    maplist(escribir_sistema(Stream), Sistemas),
    % Tripulantes — retractall + assert cada uno
    writeln(Stream, ':- retractall(hechos:tripulante(_,_,_,_)).'),
    maplist(escribir_tripulante(Stream), Trips),
    close(Stream).

escribir_sistema(Stream, s(M,S,A,E)) :-
    format(Stream, ':- assertz(hechos:sistema(~w,~w,~w,~w)).~n', [M,S,A,E]).

escribir_tripulante(Stream, t(N,M,Ss,E)) :-
    format(Stream, ':- assertz(hechos:tripulante(~w,~w,~w,~w)).~n', [N,M,Ss,E]).

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
