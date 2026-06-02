% estado.pl — generado automaticamente
:- retractall(auxiliares:jugador(_)), assertz(auxiliares:jugador(modulo_escape)).
:- retractall(auxiliares:artefactosLogrados(_)), assertz(auxiliares:artefactosLogrados([fusible,traje_espacial,tarjeta_seguridad])).
:- retractall(auxiliares:usado(_)), assertz(auxiliares:usado([tarjeta_seguridad,traje_espacial])).
:- retractall(auxiliares:lugares(_)), assertz(auxiliares:lugares([modulo_escape,modulo_energia,laboratorio,enfermeria,puente_mando])).
:- retractall(auxiliares:reparados(_)), assertz(auxiliares:reparados([energia,comunicaciones])).
:- retractall(auxiliares:rescatados(_)), assertz(auxiliares:rescatados([kai,elena])).
:- retractall(hechos:sistema(_,_,_,_)).
:- assertz(hechos:sistema(laboratorio,comunicaciones,[fusible,traje_espacial],restaurado)).
:- assertz(hechos:sistema(modulo_energia,energia,[fusible],restaurado)).
:- retractall(hechos:tripulante(_,_,_,_)).
:- assertz(hechos:tripulante(elena,modulo_energia,[energia],rescatado)).
:- assertz(hechos:tripulante(kai,enfermeria,[energia],rescatado)).
