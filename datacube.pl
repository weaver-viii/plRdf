:- module(
  datacube,
  [
    assert_datastructure_definition/4, % +Dimensions:list(iri)
                                       % +Measure:iri
                                       % +Attributes:list(iri)
                                       % +Graph:atom
    assert_datastructure_definition/5, % +Dimensions:list(iri)
                                       % +Measure:iri
                                       % +Attributes:list(iri)
                                       % +Graph:atom
                                       % -DataStructureDefinition:iri
    assert_observation/4, % +Dataset:iri
                          % +Property:iri
                          % :Goal
                          % +Graph
    assert_observation/5 % +Dataset:iri
                         % +Property:iri
                         % :Goal
                         % +Graph
                         % -Observation:iri
  ]
).

/** <module> RDF measurement

Predicates for perfoming measurements represented in RDF.

@author Wouter Beek
@version 2014/09
*/

:- use_module(library(apply)).
:- use_module(library(lambda)).
:- use_module(library(lists)).
:- use_module(library(semweb/rdf_db)).

:- use_module(plRdf(rdf_build)).
:- use_module(plRdf(rdfs_build)).
:- use_module(plRdf_rei(rdf_reification_write)).
:- use_module(plRdf_term(rdf_datatype)).
:- use_module(plRdf_term(rdf_dateTime)).

:- use_module(plXsd(xsd)).

:- meta_predicate(assert_observation(+,+,1,+,-)).

:- rdf_meta(assert_datastructure_definition(t,r,t,+,-)).
:- rdf_meta(assert_observation(r,r,:,+,-)).

:- rdf_register_prefix(dct, 'http://purl.org/dc/terms/').
:- rdf_register_prefix(qb, 'http://purl.org/linked-data/cube#').
:- rdf_register_prefix('sdmx-dimension', 'http://purl.org/linked-data/sdmx/2009/dimension#').



%! assert_datastructure_definition(
%!   +Dimensions:list(iri),
%!   +Measure:iri,
%!   +Attributes:list(iri),
%!   +Graph:atom
%! ) is det.
% @see assert_datastructure_definition/5

assert_datastructure_definition(Ds, M, As, G):-
  assert_datastructure_definition(Ds, M, As, G, _).


%! assert_datastructure_definition(
%!   +Dimensions:list(iri),
%!   +Measure:iri,
%!   +Attributes:list(iri),
%!   +Graph:atom,
%!   -DataStructureDefinition:iri
%! ) is det.
% @tbd Add support for qb:order.
% @tbd Add support for qb:componentRequired.

assert_datastructure_definition(
  Dimensions,
  Measure,
  Attributes,
  Graph,
  DSDef
):-
  rdf_create_next_resource(data_structure_definition, dhm, DSDef),
  rdf_assert_instance(DSDef, qb:'DataStructureDefinition', Graph),
  
  maplist(
    \Dimension^Component^assert_relation(Component, qb:dimension, Dimension, Graph),
    Dimensions,
    Components1
  ),
  assert_relation(Component, qb:measure, Measure, Graph),
  maplist(
    \Attribute^Component^assert_relation(Component, qb:attribute, Attribute, Graph),
    Attributes,
    Components2
  ),
  append([Component|Components1], Components2, Components),
  
  maplist(
    \Component^rdf_assert(DSDef, qb:component, Component, Graph),
    Components
  ).


%! assert_observation(+Dataset:iri, +Property:iri, :Goal, +Graph:atom) is det.
% @see assert_observation/5

assert_observation(D, P, Goal, G):-
  assert_observation(D, P, Goal, G, _).


%! assert_observation(
%!   +Dataset:iri,
%!   +Property:iri,
%!   :Goal,
%!   +Graph:atom,
%!   -Observation:iri
%! ) is det.

assert_observation(Dataset, Property, Goal, Graph, Observation):-
  % Extract the datatype.
  rdf(Property, rdfs:range, Datatype),
  xsd_datatype(Datatype),
  
  % Create the observation.
  rdf_create_next_resource(observation, qb, Observation),
  rdf_assert_instance(Observation, qb:'Observation', Graph),
  
  % qb:dataSet
  rdf_assert(Observation, qb:dataSet, Dataset, Graph),
  
  % Assert the measurement value.
  call(Goal, Value),
  rdf_assert_datatype(Observation, Property, Value, Datatype, Graph),
  
  % Assert the temporal dimension value.
  rdf_assert_now(Observation, 'sdmx-dimension':timePeriod, Graph).



% Helpers

assert_relation(Component, Relation, Dimension, Graph):-
  rdf(Component, Relation, Dimension,  Graph), !.
assert_relation(Component, Relation, Dimension, Graph):-
  rdf_bnode(Component),
  rdf_assert(Component, Relation, Dimension, Graph).

