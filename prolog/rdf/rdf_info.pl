:- module(
  rdf_info,
  [
    rdf_info/0
  ]
).

/** <module> Prints executive summaries about the RDF DB

@author Wouter Beek
@version 2015/08-2015/09, 2015/12
*/

:- use_module(library(ansi_ext)).
:- use_module(library(dcg/dcg_ext)).
:- use_module(library(list_ext)).
:- use_module(library(rdf/rdf_print)).
:- use_module(library(rdf/rdf_stats)).





%! rdf_info is det.

rdf_info:-
  % Table header.
  ansi_format(user_output, [bold], 'Number of triples~30|Graph~n', []),

  % First row: all triples.
  rdf_number_of_triples(T),
  format(user_output, '~D~25|All~n', [T]),

  % Consective rows: one for each named graph.
  findall(N-G, rdf_number_of_triples(G, N), Pairs),
  sort(1, @>=, Pairs, SortedPairs),
  list_truncate(SortedPairs, 10, TopSortedPairs),
  forall(member(N-G, TopSortedPairs), (
    dcg_with_output_to(atom(A), rdf_print_term(G)),
    format(user_output, '~D~25|~a~n', [N,A])
  )),
  nl.
