:- module(
  id_show,
  [
    id_show/0
  ]
).

/** <module> Identity show

@author Wouter Beek
@version 2015/12
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(dcg/dcg_ext)).
:- use_module(library(dcg/dcg_table)).
:- use_module(library(option)).
:- use_module(library(ordsets)).
:- use_module(library(pair_ext)).
:- use_module(library(q/q_print)).
:- use_module(library(service/ll_api)).





id_show:-
  ldf(X, owl:sameAs, Y),
  rdf_term_diff(X, Y).

%! rdf_term_diff(+Term1:list(compound), +Term2:list(compound)) is det.
% The diff between two collections of RDF statements.
% Showing:
%   0. Resource identifier.
%   1. Shared P-Os.
%   2. Shared P; dissimilar Os.
%     2a. ⊇ Os
%     2b. ⊆ Os
%     2c. ≠ Os
%   3. Dissimilar PO.

rdf_term_diff(X, Y):-
  maplist(term_pairs, [X,Y], [XPos,YPos]),
  rdf_term_diff(X, XPos, Y, YPos).

rdf_term_diff(X, XPos, Y, YPos):-
  format(current_output, "X: ~a~tY: ~a~n", [X,Y]),
  ord_intersection(XPos, YPos, XYPos),
  print_shared(XYPos).
 

term_pairs(S, GroupedPairs):-
  aggregate(set(P-O), ldf(S, P, O), Pairs),
  group_pairs_by_key(Pairs, GroupedPairs).


print_shared(Pos):-
  maplist(pair_list, Pos, Rows),
  dcg_with_output_to(current_output,
    dcg_table(Rows, [caption("Shared PO"),cell(id_show_cell)])
  ).

id_show_cell(Os) --> {is_list(Os)}, !, set(q_print_object, Os).
id_show_cell(P) --> q_print_predicate(P).
