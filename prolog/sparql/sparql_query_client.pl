:- module(
  sparql_query_client,
  [
    sparql_ask/2,                 % +Iri,      +Query
    sparql_ask/3,                 % +Iri,      +Query,          +Opts
    sparql_build_ask//2,          % +Prefixes,         +Bgps
    sparql_build_ask//3,          % +Prefixes,         +Bgps,   +Opts
    sparql_build_select//3,       % +Prefixes, +Vars,  +Bgps
    sparql_build_select//4,       % +Prefixes, +Vars,  +Bgps,   +Opts
    sparql_query/4,               % +Iri,      +Query, -Result, +Opts
    sparql_query_random_triple/2, % +Iri,              -Triple
    sparql_select/3,              % +Iri,      +Query, -Result
    sparql_select/4               % +Iri,      +Query, -Result, +Opts
  ]
).

/** <module> SPARQL Query client

High-level API for making SPARQL queries.

The following debug flags are defined:

  - sparql(request)

@author Wouter Beek
@version 2015/08, 2015/12, 2016/03-2016/04
*/

:- use_module(library(apply)).
:- use_module(library(dcg/dcg_ext)).
:- use_module(library(debug)).
:- use_module(library(error)).
:- use_module(library(http/http_ext)).
:- use_module(library(http/http_io)).
:- use_module(library(http/http11)).
:- use_module(library(iri/iri_ext)).
:- use_module(library(list_ext)).
:- use_module(library(math/math_ext)).
:- use_module(library(option)).
:- use_module(library(q/q_datatype)).
:- use_module(library(random)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(semweb/sparql_client)).
:- use_module(library(sparql/sparql_build)).
:- use_module(library(sparql/sparql_ext)).





%! sparql_ask(+Iri, +Query) is semidet.
%! sparql_ask(+Iri, +Query, +Opts) is semidet.

sparql_ask(Iri, Q) :-
  sparql_ask(Iri, Q, []).


sparql_ask(Iri, Q, Opts) :-
  sparql_query(Iri, Q, true, Opts).



%! sparql_build_ask(+Prefixes, +Bgps)// is det.
%! sparql_build_ask(+Prefixes, +Bgps, +Opts)// .

sparql_build_ask(Prefixes, Bgps) -->
  sparql_build_ask(Prefixes, Bgps, []).


sparql_build_ask(Prefixes, Bgps, Opts) -->
  sparql_build(ask, Prefixes, [], Bgps, Opts).



%! sparql_build_select(+Prefixes, +Vars, +Bgps)// is det.
%! sparql_build_select(+Prefixes, +Vars, +Bgps, +Opts)// is det.

sparql_build_select(Prefixes, Vars, Bgps) -->
  sparql_build_select(Prefixes, Vars, Bgps, []).


sparql_build_select(Prefixes, Vars, Bgps, Opts) -->
  sparql_build(select, Prefixes, Vars, Bgps, Opts).



%! sparql_query(+Iri, +Query, -Result, +Opts) is det.
% The following options are supported:
%   * variable_names(-list(atom))

sparql_query(Iri1, Q, Result, Opts1) :-
  uri_components(Iri1, uri_components(Scheme,Auth,Path1,_,_)),
  sparql_path(query, Path1, Path2, Opts1),
  sparql_graph_params(query, Opts1, GParams, Opts2),
  uri_query_components(Query, [query-Q|GParams]),
  uri_components(Iri2, uri_components(Scheme,Auth,Path2,Query,_)),
  merge_options(
    [request_header('Accept'='application/sparql-results+json')],
    Opts2,
    Opts3
  ),
  http_get(Iri2, sparql_read_reply0(Result0), Opts3),
  (   % SPARQL query: ASK
      Result0 = ask(Result)
  ->  true
  ;   % SPARQL query: SELECT.
      Result0 = select(VarTerm, Rows),
      maplist(list_row, Result, Rows),
      % Optionally return the variable names.
      VarTerm =.. [_|VarNames],
      ignore(option(variable_names(VarNames), Opts1))
  ).


sparql_read_reply0(Result, In, Path, Path) :-
  (   http_header('Content-Type', Path, media_type("application", Subtype, _))
  ->  (   Subtype == "sparql-results+xml"
      ->  sparql_read_xml_result(stream(In), Result)
      ;   Subtype == "sparql-results+json"
      ->  sparql_read_json_result(stream(In), Result)
      )
  ;   domain_error(sparql_result_document, no_content_type)
  ).



%! sparql_query_random_triple(+Iri, -Trip) is det.
% Retruns a random triples from the given endpoint.

sparql_query_random_triple(Iri, rdf(S,P,O)) :-
  atom_phrase(
    Q1,
    sparql_build(select, [], [count([])], [rdf(var(s),var(p),var(o))], [])
  ),
  sparql_select(Iri, Q1, [[Count^^_]]),
  random_between(1, Count, Index),
  atom_phrase(
    Q2,
    sparql_build(
      select,
      [],
      [s,p,o],
      [rdf(var(s),var(p),var(o))],
      [limit(1),offset(Index)]
    )
  ),
  sparql_select(Iri, Q2, [[S,P,O]]).



%! sparql_select(+Iri, +Query, -Results) is det.
%! sparql_select(+Iri, +Query, -Results, +Opts) is det.

sparql_select(Iri, Q, Result) :-
  sparql_select(Iri, Q, Result, []).


sparql_select(Iri, Q1, Result, Opts) :-
  % Pagination.
  option(page_size(PageSize), Opts, 20000),
  betwixt(0, inf, PageSize, Offset),
  query_suffix(Q1, PageSize, Offset, Q2),

  sparql_query(Iri, Q2, Result0, Opts),

  % Determinism.
  (var(Result0) -> !, fail ; true),
  (Result0 == [] -> !, fail ; true),
  Result = Result0.





% MESSAGES %

:- multifile
    prolog:message//1.

prolog:message(sparql_query(Status,Q)) -->
  ["SPARQL query returned HTTP status code ~d for query ~w."-[Status,Q]].





% HELPERS %

%! query_suffix(+Query, +Limit, +Offset, -SuffixedQuery) is det.

query_suffix(Q1, Limit, Offset, Q2) :-
  format(atom(Suffix1), "LIMIT ~d~n", [Limit]),
  format(atom(Suffix2), "OFFSET ~d~n", [Offset]),
  atomic_list_concat([Q1,Suffix1,Suffix2], Q2),
  debug(sparql(request), "~a", [Q2]).
