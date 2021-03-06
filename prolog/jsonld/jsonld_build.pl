:- module(
  jsonld_build,
  [
    quads_to_jsonld/3,   % +M, +Quads, -Dict
    subject_to_jsonld/3, % +M, +S, -Dict
    subject_to_jsonld/4, % +M, +S, ?G, -Dict
    triples_to_jsonld/3, % +M, +Triples, -Dict
    triples_to_jsonld/4  % +M, +Triples, ?G, -Dict
  ]
).

/** <module> JSON-LD build

@author Wouter Beek
@compat JSON-LD 1.1
@see http://www.w3.org/TR/json-ld/
@version 2016/01, 2016/06, 2016/08
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(assoc_ext)).
:- use_module(library(dict_ext)).
:- use_module(library(lists)).
:- use_module(library(pair_ext)).
:- use_module(library(q/q_datatype)).
:- use_module(library(q/q_list)).
:- use_module(library(q/q_shape)).
:- use_module(library(q/q_rdf)).
:- use_module(library(q/q_term)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(uri)).

:- rdf_meta
   quads_to_jsonld(+, t, -),
   subject_to_jsonld(+, r, -),
   subject_to_jsonld(+, r, r, -),
   triples_to_jsonld(+, t, -),
   triples_to_jsonld(+, t, r, -).





%! quads_to_jsonld(+M, +Quads, -Dict) is det.

quads_to_jsonld(M, Quads, Dict) :-
  findall(G-rdf(S,P,O), member(rdf(S,P,O,G), Quads), Pairs),
  group_pairs_by_key(Pairs, GroupedPairs),
  pairs_keys_values(GroupedPairs, Gs, Tripless),
  maplist(triples_to_jsonld(M), Tripless, Gs, Contexts, SDictss),
  (   Gs = [G],
      Contexts = [Context],
      SDictss = [SDicts]
  ->  Dict = _{'@context': Context, '@graph': SDicts, '@id': G}
  ;   merge_dicts(Contexts, Context),
      maplist(jsonld_graph_dict, Gs, SDictss, GDicts),
      Dict = _{'@context': Context, '@graph': GDicts}
  ).


jsonld_graph_dict(G, SDicts, _{'@graph': SDicts, '@id': G}).


merge_dicts([Dict], Dict) :- !.
merge_dicts([H1,H2|T], Dict) :-
  merge_dicts(H1, H2, H3),
  merge_dicts([H3|T], Dict).



%! subject_to_jsonld(+M, +S, -Dict) is det.
%! subject_to_jsonld(+M, +S, ?G, -Dict) is det.

subject_to_jsonld(M, S, Dict) :-
  subject_to_jsonld(M, S, _, Dict).


subject_to_jsonld(M, S, G, Dict) :-
  q_cbd_triples(M, S, G, Triples),
  triples_to_jsonld(M, Triples, G, Dict).



%! triples_to_jsonld(+M, +Triples, -Dict) is det.
%! triples_to_jsonld(+M, +Triples, ?G, -Dict) is det.

triples_to_jsonld(M, Triples, Dict) :-
  triples_to_jsonld(M, Triples, _, Dict).


triples_to_jsonld(M, Triples, G, Dict) :-
  triples_to_jsonld(M, Triples, G, Context, Dicts),
  (   Dicts = [Dict0]
  ->  put_dict('@context', Dict0, Context, Dict)
  ;   Dict = _{'@context': Context, '@graph': Dicts}
  ).


triples_to_jsonld(M, Triples, G, Context, Dicts) :-
  jsonld_triples_context(M, Triples, G, PDefs, DefLang, Context),
  jsonld_triples_tree(Triples, Tree),
  assoc_to_keys(Tree, Ss),
  maplist(jsonld_subject_tree(M, PDefs, DefLang, Tree, G), Ss, Dicts).



%! jsonld_subject_tree(+M, +PDefs:list(pair), ?DefLang, +Tree, +G, +S, -Dict) is det.

jsonld_subject_tree(M, PDefs, DefLang, Tree, G, S1, Dict) :-
  get_assoc(S1, Tree, Subtree),

  % '@id'
  jsonld_abbreviate_iri0(S1, S2),
  (q_is_bnode(S1) -> Pairs1 = Pairs2 ; Pairs1 = ['@id'-S2|Pairs2]),

  % '@type'
  rdf_equal(rdf:type, RdfType),
  (   get_assoc(RdfType, Subtree, Cs1),
      maplist(jsonld_abbreviate_iri0, Cs1, Cs2)
  ->  (Cs2 = [Cs3] -> true ; Cs3 = Cs2),
      Pairs2 = ['@type'-Cs3|Pairs3]
  ;   Pairs2 = Pairs3
  ),

  % Predicate-object pairs.
  assoc_to_keys(Subtree, Ps1),
  subtract(Ps1, [RdfType], Ps2),
  maplist(jsonld_ptree(M, PDefs, DefLang, Subtree, G), Ps2, Pairs3),

  % Pairs → dict.
  dict_pairs(Dict, Pairs1).



%! jsonld_triples_context(+M, +Triples, +G, -PDefs, -DefLang, -Context) is det.

jsonld_triples_context(M, Triples, G, PDefs, _LTag, Context) :-
  % Prefixes.
  aggregate_all(
    set(Alias-Prefix),
    (
      member(Triple, Triples),
      (q_triple_iri(Triple, Iri) ; q_triple_datatype(Triple, Iri)),
      q_iri_alias_prefix(Iri, Alias, Prefix)
    ),
    Aliases
  ),

  /*
  % Default language, if any.
  (   jsonld_default_language(Triples, LTag)
  ->  DefLang = ['@language'-LTag]
  ;   DefLang = []
  ),
  */

  % Predicate definitions.
  aggregate_all(set(P), member(rdf(_,P,_), Triples), Ps),
  p_defs(M, Triples, Ps, G, PDefs),

  append(Aliases, PDefs, Pairs),
  dict_pairs(Context, Pairs).



%! jsonld_default_language(+Triples, -LTag) is semidet.

jsonld_default_language(Triples, LTag) :-
  aggregate_all(set(LTag), member(rdf(_,_,_@LTag), Triples), LTags),
  maplist(language_occurrences0(Triples), LTags, Ns),
  pairs_keys_values(Pairs, Ns, LTags),
  desc_pairs_values(Pairs, [LTag|_]).


language_occurrences0(Triples, LTag, N) :-
  aggregate_all(count, member(rdf(_,_,_@LTag), Triples), N).



%! jsonld_triples_tree(+Triples, -Trees) is det.

jsonld_triples_tree(Triples, Assoc) :-
  empty_assoc(Assoc0),
  jsonld_triples_tree(Triples, Assoc0, Assoc).


jsonld_triples_tree([rdf(S,P,O)|Triples], Assoc1, Assoc3) :- !,
  (get_assoc(S, Assoc1, SubAssoc1) -> true ; empty_assoc(SubAssoc1)),
  put_assoc_ord_member(P, SubAssoc1, O, SubAssoc2),
  put_assoc(S, Assoc1, SubAssoc2, Assoc2),
  jsonld_triples_tree(Triples, Assoc2, Assoc3).
jsonld_triples_tree([], Assoc, Assoc).



%! jsonld_ptree(+M, +PDefs, ?DefLang, +Tree, +G, +P, -POs) is det.

jsonld_ptree(M, PDefs, DefLang, Tree, G, P1, P2-O2) :-
  jsonld_abbreviate_iri0(P1, P2),
  get_assoc(P1, Tree, Os1),
  maplist(jsonld_oterm(M, PDefs, DefLang, P2, G), Os1, Os2),
  (Os2 = [O2] -> true ; O2 = Os2).



%! jsonld_oterm(+M, +PDefs, ?DefLang, +P, +G, +O, -DictO) is det.

jsonld_oterm(M, PDefs, _, P2, G, O1, L2) :-
  q_is_subject(O1),
  q_maximal_list(M, O1, L1, G),
  memberchk(P2-PDef, PDefs),
  '@list' == PDef.get('@container'), !,
  maplist(jsonld_abbreviate_iri0, L1, L2).
jsonld_oterm(_, PDefs, _DefLang, P2, _, O1, O2) :-
  O1 = Lex@LTag, !,
  (   memberchk(P2-PDef, PDefs),
      _ = PDef.get('@language')
  ->  O2 = Lex
  %;   LTag == DefLang
  %->  O2 = Lex
  ;   O2 = literal{'@language': LTag}
  ).
jsonld_oterm(_, PDefs, _, P2, _, O1, O2) :-
  O1 = _^^D1, !,
  q_literal_lex(O1, Lex),
  (   memberchk(P2-PDef, PDefs),
      _ = PDef.get('@type')
  ->  O2 = Lex
  ;   q_literal_datatype(O1, D1),
      jsonld_abbreviate_iri0(D1, D2),
      O2 = literal{'@type':D2, '@value':Lex}
  ).
jsonld_oterm(_, _, _, _, _, O1, O2) :-
  jsonld_abbreviate_iri0(O1, O2).



%! p_defs(+M, +Triples, +Ps, +G, -Pairs) is det.

p_defs(M, Triples, [P1|Ps1], G, [P2-odef{'@container': '@list'}|Ps2]) :-
  p_container(M, Triples, P1, G), !,
  jsonld_abbreviate_iri0(P1, P2),
  p_defs(M, Triples, Ps1, G, Ps2).
p_defs(M, Triples, [P1|Ps1], G, [P2-odef{'@language': LTag}|Ps2]) :-
  p_ltag(Triples, P1, LTag), !,
  jsonld_abbreviate_iri0(P1, P2),
  p_defs(M, Triples, Ps1, G, Ps2).
p_defs(M, Triples, [P1|Ps1], G, [P2-odef{'@type': '@id'}|Ps2]) :-
  p_iri(Triples, P1), !,
  jsonld_abbreviate_iri0(P1, P2),
  p_defs(M, Triples, Ps1, G, Ps2).
p_defs(M, Triples, [P1|Ps1], G, [P2-odef{'@type': D2}|Ps2]) :-
  p_datatype(Triples, P1, D1), !,
  jsonld_abbreviate_iri0(P1, P2),
  jsonld_abbreviate_iri0(D1, D2),
  p_defs(M, Triples, Ps1, G, Ps2).
p_defs(M, Triples, [_|T1], G, T2) :- !,
  p_defs(M, Triples, T1, G, T2).
p_defs(_, _, [], _, []).



%! p_container(+M, +Triples, +P, +G) is semidet.
%
% Predicate P always has an RDF container as its object term.

p_container(M, Triples, P, G) :-
  forall(
    member(rdf(_,P,O), Triples),
    (
      q_is_subject(O),
      q_maximal_list(M, O, G)
    )
  ).



%! p_datatype(+Triples, +P, -D) is semidet.
%

p_datatype(Triples, P, Sup) :-
  memberchk(rdf(_,P,O), Triples),
  q_literal_datatype(O, D),
  aggregate_all(
    set(D),
    (member(rdf(_,P,O), Triples), q_literal_datatype(O, D)),
    Ds
  ),
  q_datatype_supremum(Ds, Sup).



%! p_iri(+Triples, +P) is semidet.

p_iri(Triples, P) :-
  forall(member(rdf(_,P,O), Triples), uri_is_global(O)).



%! p_ltag(+Triples, +P, -LTag) is semidet.
% Predicate P always has a language tagged string as its object term.

p_ltag(Triples, P, LTag) :-
  memberchk(rdf(_,P,_@LTag), Triples),
  forall(member(rdf(_,P,O), Triples), q_is_lts(O)).



%! jsonld_abbreviate_iri0(+Iri, -Abbr) is det.

jsonld_abbreviate_iri0(Iri, Abbr) :-
  uri_is_global(Iri),
  rdf_global_id(Alias:Local, Iri), !,
  atomic_list_concat([Alias,Local], :, Abbr).
jsonld_abbreviate_iri0(Iri, Iri).
