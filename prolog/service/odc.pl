:- module(
  odc,
  [
    odc_entry/2 % -S, -Triples
  ]
).

/** <module> Open Data Communities (ODC)

@author Wouter Beek
@version 2014/05, 2016/05-2016/06
*/

:- use_module(library(q/q_stmt)).
:- use_module(library(q/q_term)).
:- use_module(library(rdf/rdfio)).
:- use_module(library(solution_sequences)).
:- use_module(library(yall)).





%! odc_entry(-S, -Triples) is nondet.

odc_entry(S, Triples) :-
  rdf_call_on_graph('http://opendatacommunities.org/data.ttl',
    {S,Triples}/[G,M,M]>>odc_entry0(S, Triples, G)
  ).


odc_entry0(S, Triples, G) :-
  distinct(S, q_subject(rdf, Res, G)),
  q_triples(rdf, S, _, _, G, Triples).
