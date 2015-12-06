:- module(
  rdf_graph_viz,
  [
    rdf_graph_to_export_graph/2, % +Graph, -ExportGraph
    rdf_graph_to_export_graph/3 % +Graph:rdf_graph
                                % -ExportGraph:compound
                                % +Options:list(compound)
  ]
).

/** <module> RDF graph visualization

Predicates for exporting RDF graphs to the graph export format
handled by plGraphViz.

@author Wouter Beek
@version 2015/07, 2015/10, 2015/12
*/

:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(dcg/dcg_phrase)).
:- use_module(library(graph/build_export_graph)).
:- use_module(library(graph/l/l_graph)).
:- use_module(library(gv/gv_color)).
:- use_module(library(list_ext)).
:- use_module(library(option)).
:- use_module(library(rdf/rdf_graph_theory)).
:- use_module(library(rdf/rdf_image)).
:- use_module(library(rdf/rdf_prefix)).
:- use_module(library(rdf/rdf_print)).
:- use_module(library(rdf/rdf_statement)).
:- use_module(library(rdf/rdf_term)).
:- use_module(library(semweb/rdfs), [rdfs_individual_of/2,rdfs_subclass_of/2]).
:- use_module(library(typecheck)).

:- dynamic
     rdf:rdf_class_color/3,
     rdf:rdf_edge_style/3,
     rdf:rdf_predicate_label/3.
:- multifile
     rdf:rdf_class_color/3,
     rdf:rdf_edge_style/3,
     rdf:rdf_predicate_label/3.

:- rdf_meta(rdf_term_to_export_graph(r,-,+)).

:- predicate_options(rdf_edges_to_export_graph/3, 3, [
     colorscheme(+oneof([none,svg,x11])),
     pass_to(build_export_graph/3, 3),
     pass_to(rdf_term_name//2, 2)
   ]).
:- predicate_options(rdf_graph_to_export_graph/3, 3, [
     pass_to(rdf_edges_to_export_graph/3, 3)
   ]).
:- predicate_options(rdf_term_to_export_graph/3, 3, [
     depth(+nonneg),
     graph(+atom),
     pass_to(rdf_edges_to_export_graph/3, 3)
   ]).





%! create_namespace_map(
%!   +Scheme:oneof([svg,x11]),
%!   -PrefixColors:list(pair)
%! ) is det.

create_namespace_map(Scheme, Map):-
  rdf_prefixes(Prefixes),
  create_namespace_map(Prefixes, Scheme, Map).



%! create_namespace_map(
%!   +Prefixes:list(atom),
%!   +Colorscheme:oneof([svg,x11]),
%!   -PrefixColors:list(pair)
%! ) is det.

create_namespace_map(Prefixes, Scheme, Map):-
  length(Prefixes, NP),
  aggregate_all(set(C), gv_color(Scheme, C), Cs),
  length(Cs, NC),
  Delta is NC // NP,
  findall(
    Prefix-C,
    (
      nth0(I, Prefixes, Prefix),
      % In case there are more namespaces than colors, Delta=1 and we use
      % the same color for all namespaces with index I mod M.
      J is (I * Delta) mod NC,
      % J can be 0 because of the modulus function so we do not use nth1/3.
      nth0chk(J, Cs, C)
    ),
    Map
  ).



%! rdf_edges_to_export_graph(
%!   +Triples:list(compound),
%!   -ExportGraph:compound,
%!   +Options:list(compound)
%! ) is det.
% The following options are supported:
%   * colorscheme(+oneof([none,svg,x11]))
%     The colorscheme for the colors assigned to vertices and edges.
%     Supported values are `svg`, `x11`, and `none` (for black and white).
%     Default is `svg`.
%   * prefix_colors(+list(pair))
%     Default is [].

rdf_edges_to_export_graph(Es, ExportG, Opts1):-
  % Options `colorscheme' and `namespace_colors' are special
  % since their values are reused by other options.
  select_option(colorscheme(Colorscheme), Opts1, Opts2, x11),
  (   select_option(prefix_colors(Map), Opts2, Opts3)
  ->  true
  ;   create_namespace_map(Colorscheme, Map)
  ),
  merge_options(
    Opts3,
    [
      edge_arrowhead(rdf_edge_arrowhead),
      edge_color(rdf_edge_color(Colorscheme,Map)),
      edge_label(rdf_edge_label),
      edge_style(rdf_edge_style),
      graph_charset('UTF-8'),
      graph_colorscheme(Colorscheme),
      graph_directed(true),
      vertex_color(rdf_vertex_color(Colorscheme,Map)),
      vertex_image(rdf_vertex_image),
      vertex_label(rdf_vertex_label),
      vertex_peripheries(rdf_vertex_peripheries),
      vertex_shape(rdf_vertex_shape)
    ],
    Opts4
  ),
  l_edges_vertices(Es, Vs),
  build_export_graph(graph(Vs,Es), ExportG, Opts4).



%! rdf_graph_to_export_graph(+Graph:rdf_graph, -ExportGraph:compound) is det.
% Wrapper around rdf_graph_to_export_graph/3 with default options.

rdf_graph_to_export_graph(G, ExportG):-
  rdf_graph_to_export_graph(G, ExportG, []).


%! rdf_graph_to_export_graph(
%!   +Graph:rdf_graph,
%!   -ExportGraph:compound,
%!   +Options:list(compound)
%! ) is det.

rdf_graph_to_export_graph(G, ExportG, Opts):-
  rdf_graph_edges(G, Es),
  rdf_edges_to_export_graph(Es, ExportG, Opts).



%! rdf_term_to_export_graph(
%!   +Term:rdf_term,
%!   -ExportGraph:compound,
%!   +Options:list(compound)
%! ) is det.
% The following options are supported:
%   * depth(+nonneg)
%     How much context is taken into account when exporting an RDF term.
%     Default is 1.
%   * Other options are passed to rdf_graph_to_export_graph/4.

rdf_term_to_export_graph(T, ExportG, Opts1):-
  select_option(depth(Depth), Opts1, Opts2, 1),
  rdf_ego(T, Depth, Ts),
  maplist(rdf_triple_edge, Ts, Es),
  rdf_edges_to_export_graph(Es, ExportG, Opts2).





% ATTRIBUTE-SETTING PREDICATES %

%! rdf_edge_arrowhead(+Edge:compound, -ArrowHead:atom) is det.

% RDFS subclass.
rdf_edge_arrowhead(edge(_,P,_), box):-
  rdf_expand_ct(P, rdfs:subClassOf), !.
% RDFS subproperty.
rdf_edge_arrowhead(edge(_,P,_), diamond):-
  rdf_expand_ct(P, rdfs:subPropertyOf), !.
% RDF type.
rdf_edge_arrowhead(edge(_,P,_), empty):-
  rdf_expand_ct(P, rdf:type), !.
% RDFS label.
rdf_edge_arrowhead(edge(_,P,_), none):-
  rdf_expand_ct(P, rdfs:label), !.
% Others.
rdf_edge_arrowhead(_, normal).



%! rdf_edge_color(
%!   +Colorscheme:oneof([none,svg,x11]),
%!   +PrefixColors:list(pair),
%!   +Graph:rdf_graph,
%!   +Edge:compound,
%!   -Color:atom
%! ) is det.

% Disable colorization.
rdf_edge_color(none, _, _, _, black):- !.
% The edge color is based on the predicate term.
rdf_edge_color(Colorscheme, Map, G, edge(_,P,_), EColor):-
  rdf_vertex_color(Colorscheme, Map, G, P, EColor), !.
% If the edge color is not specified, then see whether its vertices
% agree on their color.
rdf_edge_color(Colorscheme, Map, G, edge(FromV,_,ToV), EColor):-
  rdf_vertex_color(Colorscheme, Map, G, FromV, FromVColor),
  rdf_vertex_color(Colorscheme, Map, G, ToV, ToVColor),
  FromVColor == ToVColor, !,
  EColor = FromVColor.
% Others.
rdf_edge_color(_, _, _, _, black).



%! rdf_edge_label(+Graph:rdf_graph, +Edge:compound, -Label:atom) is det.

% User-supplied customization.
rdf_edge_label(G, edge(_,P,_), ELabel):-
  rdf:rdf_predicate_label(G, P, ELabel), !.
% Some edge labels are not displayed.
rdf_edge_label(_, edge(_,P,_), ''):-
  (   rdf_expand_ct(rdf:type, P)
  ;   rdf_expand_ct(rdfs:label, P)
  ;   rdf_expand_ct(rdfs:subClassOf, P)
  ;   rdf_expand_ct(rdfs:subPropertyOf, P)
  ), !.
% Others: the edge name is the predicate term.
rdf_edge_label(_, edge(_,P,_), ELabel):-
  dcg_with_output_to(atom(ELabel), rdf_print_term(P)).



%! rdf_edge_style(+Graph:rdf_graph, +Edge:compound, -Style:atom) is det.

% User-supplied customization.
rdf_edge_style(G, E, EStyle):-
  rdf:rdf_edge_style(G, E, EStyle), !.
% Certain RDFS schema terms.
rdf_edge_style(_, edge(_,P,_), solid):-
  (   rdf_expand_ct(rdf:type, P)
  ;   rdf_expand_ct(rdfs:subClassOf, P)
  ;   rdf_expand_ct(rdfs:subPropertyOf, P)
  ), !.
% RDFS label.
rdf_edge_style(_, edge(_,P,_), dotted):-
  rdf_expand_ct(rdfs:label, P), !.
% Others.
rdf_edge_style(_, _, solid).



%! rdf_vertex_color(
%!   +Colorscheme:oneof([none,svg,x11]),
%!   +PrefixColors:list(pair),
%!   +Graph:rdf_graph,
%!   +Term:rdf_term,
%!   -Color:atom
%! ) is det.
% Returns a color name for the given vertex.

% No color scheme.
rdf_vertex_color(none, _, _, _, black):- !.
% Literal
rdf_vertex_color(_, _, _, T, blue):-
  rdf_is_literal(T), !.
% Blank node
rdf_vertex_color(_, _, _, T, purple):-
  rdf_is_bnode(T), !.
% Individual or subclass of a color-registered class.
rdf_vertex_color(_, _, G, V, VColor):-
  (   rdfs_individual_of(V, C)
  ;   rdfs_subclass_of(V, C)
  ),
  rdf:rdf_class_color(G, C, VColor), !.
% IRI with a colored namespace.
rdf_vertex_color(_, Map, _, T, VColor):-
  rdf_expand_rt(Prefix:_, T),
  memberchk(Prefix-VColor, Map), !.
% Other IRI.
rdf_vertex_color(_, _, _, _, black).



%! rdf_vertex_image(+Graph:rdf_graph, +Term:rdf_term, -ImageFile:atom) is det.
% Only display the first picture that is found for Term.

rdf_vertex_image(G, V, VImage):-
  once(rdf_image(V, _, VImage, G)).



%! rdf_vertex_label(
%!   +Options:list(compound),
%!   +Term:rdf_term,
%!   -Label:atom
%! ) is det.

rdf_vertex_label(Opts1, V, VLabel):-
  merge_options(Opts1, [literal_ellipsis(50)], Opts2),
  dcg_with_output_to(atom(VLabel), rdf_print_term(V, Opts2)).



%! rdf_vertex_peripheries(+Term:rdf_term, -Peripheries:nonnneg) is det.

% Literal
rdf_vertex_peripheries(literal(_), 0):- !.
% Blank node
rdf_vertex_peripheries(Term, 1):-
  rdf_is_bnode(Term), !.
% Class
rdf_vertex_peripheries(Term, 2):-
  rdfs_individual_of(Term, rdfs:'Class'), !.
% Property
rdf_vertex_peripheries(Term, 1):-
  rdfs_individual_of(Term, rdf:'Property'), !.
% IRIs that are not classes or properties.
rdf_vertex_peripheries(_, 1).



%! rdf_vertex_shape(+Term:rdf_term, -Shape:atom) is det.

% Literal
rdf_vertex_shape(literal(_), plaintext):- !.
% Blank node
rdf_vertex_shape(T, circle):-
  rdf_is_bnode(T), !.
% Class
rdf_vertex_shape(T, octagon):-
  rdfs_individual_of(T, rdfs:'Class'), !.
% Property
rdf_vertex_shape(T, hexagon):-
  rdfs_individual_of(T, rdf:'Property'), !.
% IRIs that are not classes or properties.
rdf_vertex_shape(_, ellipse).
