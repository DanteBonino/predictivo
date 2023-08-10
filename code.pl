%Base de conocimiento
% mensaje(ListaDePalabras, Receptor).
%	Los receptores posibles son:
%	Persona: un simple átomo con el nombre de la persona; ó
%	Grupo: una lista de al menos 2 nombres de personas que pertenecen al grupo.
mensaje(['hola', ',', 'qué', 'onda', '?'], nico).
mensaje(['todo', 'bien', 'dsp', 'hablamos'], nico).
mensaje(['q', 'parcial', 'vamos', 'a', 'tomar', '?'], [nico, lucas, maiu]).
mensaje(['todo', 'bn', 'dsp', 'hablamos'], [nico, lucas, maiu]).
mensaje(['todo', 'bien', 'después', 'hablamos'], mama).
mensaje(['¿','y','q', 'onda', 'el','parcial', '?'], nico).
mensaje(['¿','y','qué', 'onda', 'el','parcial', '?'], lucas).

% abreviatura(Abreviatura, PalabraCompleta) relaciona una abreviatura con su significado.
abreviatura('dsp', 'después').
abreviatura('q', 'que').
abreviatura('q', 'qué').
abreviatura('bn', 'bien').

% signo(UnaPalabra) indica si una palabra es un signo.
signo('¿').    signo('?').   signo('.').   signo(','). 

% filtro(Contacto, Filtro) define un criterio a aplicar para las predicciones para un contacto
filtro(nico, masDe(0.5)).
filtro(nico, ignorar(['interestelar'])).
filtro(lucas, masDe(0.7)).
filtro(lucas, soloFormal).
filtro(mama, ignorar(['dsp','paja'])).

%Punto 1:
recibioMensaje(Mensaje, Receptor):-
    mensaje(Mensaje,PosibleRecepto),
    receptor(PosibleRecepto, Receptor).

receptor(Receptor,Receptor):-%Esto me genera dudas pq, justo se da que filtro abarca a todos los que reciben mensajes solos. Pero si alguno no tuviese filtro no se generaria.
    not(member(_,Receptor)).
receptor(Receptores, Receptor):-
    member(Receptor, Receptores).

%Punto 2:
demasiadoFormal(Mensaje):-
    noTieneAbreviatura(Mensaje),
    tieneMasDe20CaracteresOEmpiezaConPregunta(Mensaje).

tieneAbreviatura(Mensaje):-
    abreviatura(Abreviatura,_),
    member(Abreviatura, Mensaje).
noTieneAbreviatura(Mensaje):-
    mensaje(Mensaje,_),
    not(tieneAbreviatura(Mensaje)).

tieneMasDe20CaracteresOEmpiezaConPregunta(Mensaje):-
    tieneMasDeNCaracteres(Mensaje,20).
tieneMasDe20CaracteresOEmpiezaConPregunta(Mensaje):-
    nth0(0,Mensaje,'¿').

tieneMasDeNCaracteres(Mensaje, Minimo):-
    length(Mensaje, Cantidad),
    Cantidad > Minimo.

%Punto 3:
esAceptable(Palabra,Persona):-
    palabra(Palabra),
    recibioMensaje(_,Persona),
    forall(filtro(Persona,Filtro), superaElFiltro(Palabra, Filtro, Persona)).

palabra(Palabra):-
    mensajeQueTienePalabra(_,Palabra).

superaElFiltro(Palabra, ignorar(Palabras), _):-
    not(member(Palabra,Palabras)).
superaElFiltro(Palabra,soloFormal,_):-
    demasiadoFormal(Mensaje),
    member(Palabra, Mensaje).
superaElFiltro(Palabra, masDe(Cantidad), Persona):-
    tasaDeUso(Palabra, Persona, TasaDeUso),
    TasaDeUso > Cantidad.

tasaDeUso(Palabra, Persona, TasaDeUso):-
    cantidadDeVecesQueApareceLaPalabra(Palabra,Persona,Cantidad),
    cantidadDeVecesQueApareceLaPalabra(Palabra,_, CantidadGeneral),
    TasaDeUso is Cantidad / CantidadGeneral.

cantidadDeVecesQueApareceLaPalabra(Palabra, Persona, Cantidad):-
    findall(Persona, recibioPalabra(Palabra, Persona), Personas),
    length(Personas, Cantidad).

recibioPalabra(Palabra, Persona):-
    recibioMensaje(Mensaje, Persona),
    member(Palabra, Mensaje).
    

%Punto 4:
dicenLoMismo(Mensaje, OtroMensaje):-
    mensaje(Mensaje,_),
    mensaje(OtroMensaje,_),
    forall(member(Palabra, Mensaje), hayEquivalenteEnSuPosicion(Palabra, Mensaje, OtroMensaje)).

hayEquivalenteEnSuPosicion(Palabra, MensajeDeReferencia, Mensaje):-
    nth0(Posicion,MensajeDeReferencia,Palabra),
    nth0(Posicion,Mensaje, OtraPalabra),
    esEquivalente(Palabra, OtraPalabra).

esEquivalente(Palabra,Palabra).
esEquivalente(UnaPalabra, OtraPalabra):-
    algunaEsAbreviatura(UnaPalabra, OtraPalabra).

algunaEsAbreviatura(Palabra,OtraPalabra):-
    abreviatura(Palabra, OtraPalabra).
algunaEsAbreviatura(Palabra, OtraPalabra):-
    abreviatura(OtraPalabra,Palabra).

%Version 2:
dicenLoMismoV2(Mensaje,OtroMensaje):-
    mensaje(Mensaje,_),
    mensaje(OtroMensaje,_),
    forall(palabrasEnMismaPosicion(Mensaje,OtroMensaje, Palabra, OtraPalabra), esEquivalente(Palabra, OtraPalabra)).

palabrasEnMismaPosicion(Mensaje, OtroMensaje, Palabra, OtraPalabra):-
    nth0(Posicion,Mensaje,Palabra),
    nth0(Posicion,OtroMensaje, OtraPalabra).

%Punto 5
fraseCelebre(FraseCelebre):-
    mensaje(FraseCelebre,_),
    forall(contacto(Receptor), recibioElMismoMensaje(FraseCelebre,Receptor)).

contacto(Receptor):-
    recibioMensaje(_,Receptor).

recibioElMismoMensaje(FraseCelebre, Receptor):-
    mensajeEquivalente(FraseCelebre, MensajeEquivalente),
    recibioMensaje(MensajeEquivalente, Receptor).

mensajeEquivalente(Mensaje, Mensaje).
mensajeEquivalente(Mensaje, MensajeEquivalente):-
    dicenLoMismoV2(Mensaje, MensajeEquivalente).

%Punto 6:
prediccion(Mensaje, Receptor, Prediccion):-
    not(fraseCelebre(Mensaje)),
    prediccionPotencial(Mensaje, Prediccion),
    esAceptableParaTodos(Receptor, Prediccion).

prediccionPotencial(Mensaje, Prediccion):-
    ultimaPalabra(Mensaje, UltimaPalabra),
    palabraQueSeUsoDespuesDe(Prediccion, UltimaPalabra).

ultimaPalabra(Mensaje, UltimaPalabra):-
    length(Mensaje, CantidadPalabras),
    nth1(CantidadPalabras, Mensaje, UltimaPalabra).

palabraQueSeUsoDespuesDe(PalabraSiguiente, PalabraDeReferencia):-
    mensajeQueTienePalabra(Mensaje, PalabraDeReferencia),
    nth0(PosicionPalabraRef,Mensaje, PalabraDeReferencia),
    nth0(PosicionSiguiente, Mensaje, PalabraSiguiente),
    PosicionSiguiente is PosicionPalabraRef + 1.

mensajeQueTienePalabra(Mensaje, Palabra):-
    mensaje(Mensaje,_),
    member(Palabra, Mensaje).

esAceptableParaTodos(Receptor,Palabra):-
    esAceptable(Palabra, Receptor).
esAceptableParaTodos(Receptores, Palabra):-
    member(_,Receptores),
    forall(member(Receptor, Receptores), esAceptable(Palabra,Receptor)).
