:- module(
  rdf_write,
  [
    fresh_iri/2, % +Prefix:atom
                 % -Iri:iri
    fresh_iri/3, % +Prefix:atom
                 % +SubPaths:list(atom)
                 % -Iri:iri
    rdf_assert_instance/3, % +Instance:or([bnode,iri])
                           % ?Class:iri
                           % ?Graph:atom
    rdf_assert_literal/5, % +Subject:or([bnode,iri])
                          % +Predicate:iri
                          % +LexicalForm:atom
                          % ?Datatype:iri
                          % ?Graph:atom
    rdf_assert_now/3, % +Subject:iri
                      % +Predicate:iri
                      % +Graph:atom
    rdf_assert_property/3, % +Property:iri
                           % ?Parent:iri
                           % ?Graph:atom
    rdf_assert2/4, % +Subject:or([bnode,iri])
                   % +Predicate:iri
                   % +Object:rdf_term
                   % ?Graph:atom
    rdf_retractall_literal/5, % ?Subject:or([bnode,iri])
                              % ?Predicate:iri
                              % ?Datatype:iri
                              % ?Value
                              % ?Graph:atom
    rdf_retractall_resource/2, % +Resource:rdf_term
                               % ?Graph:atom
    rdf_retractall_term/2 % +Term:rdf_term
                          % ?Graph:atom
  ]
).

/** <module> RDF write

Simple asserion and retraction predicates for RDF.

@author Wouter Beek
@version 2017/07
*/

:- use_module(library(default)).
:- use_module(library(rdf/rdf_datatype)).
:- use_module(library(rdf/rdf_read)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(uri)).
:- use_module(library(uuid_ext)).

:- rdf_meta(rdf_assert_instance(r,r,?)).
:- rdf_meta(rdf_assert_literal(r,r,+,r,?)).
:- rdf_meta(rdf_assert_now(r,r,+)).
:- rdf_meta(rdf_assert_property(r,r,?)).
:- rdf_meta(rdf_assert2(t,r,o,?)).
:- rdf_meta(rdf_retractall_literal(r,r,r,?,?)).
:- rdf_meta(rdf_retractall_resource(r,?)).
:- rdf_meta(rdf_retractall_simple_literal(r,r,?,?)).
:- rdf_meta(rdf_retractall_string(r,r,?,?)).
:- rdf_meta(rdf_retractall_term(r,?)).
:- rdf_meta(rdf_retractall_typed_literal(r,r,?,r,?)).





%! fresh_iri(+Prefix:atom, -Iri:atom) is det.
% Succeeds with a fresh IRI within the RDF namespace denoted by Prefix.

fresh_iri(Prefix, Iri):-
  fresh_iri(Prefix, [], Iri).

%! fresh_iri(+Prefix:atom, +SubPaths:list(atom), -Iri:atom) is det.
% Succeeds with a fresh IRI within the RDF namespace denoted by Prefix
% and the given SubPaths.
%
% IRI freshness is guaranteed by the UUID that is used as the path suffix.
%
% @arg Prefix   A registered RDF prefix name.
% @arg SubPaths A list of path names that prefix the UUID.
% @arg Iri      A fresh IRI.

fresh_iri(Prefix, SubPaths0, Iri):-
  uuid_no_hyphen(Id),
  append(SubPaths0, [Id], SubPaths),
  atomic_list_concat(SubPaths, /, LocalName),
  
  % Resolve the absolute IRI against the base IRI denoted by the RDF prefix.
  rdf_global_id(Prefix:LocalName, Iri).



%! rdf_assert_instance(
%!   +Instance:or([bnode,iri]),
%!   ?Class:iri,
%!   ?Graph:atom
%! ) is det.
% Asserts an instance/class relationship.
%
% The following triples are added to the database:
%
% ```nquads
% <TERM,rdf:type,CLASS,GRAPH>
% ```
%
% @arg Instance A resource-denoting subject term (IRI or blank node).
% @arg Class    A class-denoting IRI or `rdfs:Resource` if uninstantiated.
% @arg Graph    The atomic name of an RDF graph or `user` if uninstantiated.

rdf_assert_instance(I, C, G):-
  default(rdfs:'Resource', C),
  rdf_assert2(I, rdf:type, C, G).



%! rdf_assert_literal(
%!   +Subject:or([bnode,iri]),
%!   +Predicate:iri,
%!   +Value,
%!   ?Datatype:iri,
%!   ?Graph:atom
%! ) is det.

rdf_assert_literal(S, P, D, V, G):-
  rdf_assert_literal(S, P, D, V, G, _).

%! rdf_assert_literal(
%!   +Subject:or([bnode,iri]),
%!   +Predicate:iri,
%!   +Value,
%!   ?Datatype:iri,
%!   ?Graph:atom,
%!   -Triple:compound
%! ) is det.
% Asserts a triple with a literal object term.
%
% Only emits canonical representations for XSD values.
%
% @compat RDF 1.1 Concepts and Abstract Syntax
% @compat XSD 1.1 Schema 2: Datatypes

% Language-tagged strings.
rdf_assert_literal(S, P, rdf:langString, LangTag0-LexicalForm, G, Triple):-
  nonvar(LangTag), !,
  % @ tbd Use 'Language-Tag'//1.
  atomic_list_concat(LangTag0, '-', LangTag),
  O = literal(lang(LangTag,LexicalForm)),
  rdf_assert2(S, P, O, G),
  Triple = rdf(S,P,O).
% Language-tagged strings using the default language.
rdf_assert_literal(S, P, rdf:langString, LexicalForm, G, Triple):-
  atom(LexicalForm), !,
  rdf_assert_literal(S, P, rdf:langString, [en,'US']-LexicalForm, G, Triple).
% Simple literals.
rdf_assert_literal(S, P, D, V, G, Triple):-
  var(Datatype), !,
  rdf_assert_literal(S, P, xsd:string, V, G, Triple).
% (Explicitly) typed literals.
rdf_assert_literal(S, P, D, V, G, rdf(S,P,O)):-
  rdf_canonical_map(D, V, LexicalForm),
  O = literal(type(D,LexicalForm)),
  rdf_assert2(S, P, O, G).



%! rdf_assert_now(
%!   +Subject:or([bnode,iri]),
%!   +Predicate:iri,
%!   +Graph:atom
%! ) is det.

rdf_assert_now(S, P, G):-
  get_time(Now),
  rdf_assert_literal(S, P, xsd:dateTime, Now, G).



%! rdf_assert_property(+Property:iri, ?Parent:iri, ?Graph:atom) is det.
% Asserts an RDF property.
%
% The following triples are added to the database:
%
% ```nquads
% <TERM,rdf:type,rdf:Property,GRAPH>
% ```

rdf_assert_property(P, Parent, G):-
  default(rdf:'Property', Parent),
  rdf_assert_instance(P, Parent, G).



%! rdf_assert2(
%!   +Subject:or([bnode,iri]),
%!   +Predicate:iri,
%!   +Object:rdf_term,
%!   ?Graph:atom
%! ) is det.
% Alternative of rdf/4 that allows Graph to be uninstantiated.
%
% @see rdf_db:rdf/4

rdf_assert2(S, P, O, G):-
  var(G), !,
  rdf_assert(S, P, O).
rdf_assert2(S, P, O, G):-
  rdf_assert(S, P, O, G).



%! rdf_retractall_literal(
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Datatype:iri,
%!   ?Value,
%!   ?Graph:atom
%! ) is det.
% Retracts all matching RDF triples that have literal object terms.
%
% Implementation note: this assumes that simple literals are always
% asserted with datatype IRI `xsd:string`.
% We do not retract literal compound terms of the form
% `literal(LexicalForm:atom)`.

% If no RDF datatype is given we assume XSD string,
% as specified by the RDF 1.1 standard.
rdf_retractall_literal(S, P, D, V, G):-
  var(D), !,
  rdf_retractall_literal(S, P, xsd:string, V, G).
% Retract RDF language-tagged string statements.
rdf_retractall_typed_literal(S, P, rdf:langString, V0, G):- !,
  (   atomic(V0)
  ->  V = V0
  ;   V0 = LangTag0-V,
      atomic_list_concat(LangTag0, -, LangTag)
  ),
  rdf_retractall(S, P, literal(lang(LangTag,V)), G).
% Retract XSD string statements.
rdf_retractall_typed_literal(S, P, xsd:string, V, G):- !,
  atomic(V),
  % There are two ways to assert XSD strings in rdf_db:
  % implicit and explicit.
  rdf_retractall(S, P, literal(V), G),
  rdf_retractall(S, P, literal(type(xsd:string,V)), G).
rdf_retractall_literal(S, P, D, V, G):-
  % Retract language-tagged strings only if:
  %   1. Datatype is unifiable with `rdf:langString`, and
  %   2. Value us unifiable with a value from the value space of
  %       language-tagged strings.
  rdf_retractall(S, P, literal(lang(LangTag,LexicalForm)), G),

  % Retract all matching typed literals.
  forall(
    (
      rdf(S, P, literal(type(Datatype,LexicalForm)), Graph),
      % Possibly computationally intensive!
      rdf_lexical_map(Datatype, LexicalForm, Value)
    ),
    rdf_retractall(S, P, literal(type(Datatype,LexicalForm)), Graph)
  ).



%! rdf_retractall_resource(+Resource:rdf_term, ?Graph:atom) is det.
% Removes all triples in which the resource denoted by the given RDF term
%  occurs.

rdf_retractall_resource(Term, Graph):-
  forall(
    rdf_id(Term, Term0),
    rdf_retractall_term(Term0, Graph)
  ).



%! rdf_retractall_term(+Term:rdf_term, ?Graph:atom) is det.
% Removes all triples in which the given RDF term occurs.

rdf_retractall_term(Term, Graph):-
  rdf_retractall(Term, _, _, Graph),
  rdf_retractall(_, Term, _, Graph),
  rdf_retractall(_, _, Term, Graph).



%! rdf_retractall_typed_literal(
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Value,
%!   ?Datatype:iri,
%!   ?Graph:atom
%! ) is det.

rdf_retractall_typed_literal(S, P, Value, Datatype, G):-
  rdf_retractall(S, P, literal(type(Datatype,Value)), G).
