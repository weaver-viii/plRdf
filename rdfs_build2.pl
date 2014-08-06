:- module(
  rdfs_build2,
  [
    rdfs_assert_class/5, % +Class:iri
                         % +Parent:iri
                         % +Label:or([atom,pair(atom)])
                         % +Comment:or([atom,pair(atom)])
                         % +Graph:atom
    rdfs_assert_property/6 % +Property:iri
                           % +Domain:iri
                           % +Range:iri
                           % +Label:or([atom,pair(atom)])
                           % +Comment:or([atom,pair(atom)])
                           % +Graph:atom
  ]
).

/** <module> RDFS build2

Predicates for building higher-level RDFS constructs.

@author Wouter Beek
@versdion 2014/06, 2014/08
*/

:- use_module(library(semweb/rdf_db)). % Declaration.

:- use_module(plRdf(rdf_build)).
:- use_module(plRdf(rdfs_build)).
:- use_module(plRdf(rdfs_label_ext)).

:- rdf_meta(rdfs_assert_class(r,r,+,+,+)).
:- rdf_meta(rdfs_assert_property(r,r,r,+,+,+)).



%! rdfs_assert_class(
%!   +Class:iri,
%!   +Parent:iri,
%!   +Label:or([atom,pair(atom)]),
%!   +Comment:or([atom,pair(atom)]),
%!   +Graph:atom
%! ) is det.

rdfs_assert_class(Class, Parent, Label, Comment, Graph):-
  rdfs_assert_subclass(Class, Parent, Graph),
  rdfs_assert_label_wrapper(Class, Label, Graph),
  rdfs_assert_comment_wrapper(Class, Comment, Graph).


%! rdfs_assert_property(
%!   +Property:iri,
%!   +Domain:iri,
%!   +Range:iri,
%!   +Label:or([atom,pair(atom)]),
%!   +Comment:or([atom,pair(atom)]),
%!   +Graph:atom
%! ) is det.

rdfs_assert_property(Property, Domain, Range, Label, Comment, Graph):-
  rdf_assert_property(Property, Graph),
  rdfs_assert_domain(Property, Domain, Graph),
  rdfs_assert_range(Property, Range, Graph),
  rdfs_assert_label_wrapper(Property, Label, Graph),
  rdfs_assert_comment_wrapper(Property, Comment, Graph).

% Allow language tags to be specified using pair notation.
rdfs_assert_label_wrapper(Resource, Label-LangTag, Graph):- !,
  rdfs_assert_label(Resource, Label, LangTag, Graph).
rdfs_assert_label_wrapper(Resource, Label, Graph):-
  rdfs_assert_label(Resource, Label, en, Graph).

% Allow language tags to be specified using pair notation.
rdfs_assert_comment_wrapper(Resource, Comment-LangTag, Graph):- !,
  rdfs_assert_comment(Resource, Comment, LangTag, Graph).
rdfs_assert_comment_wrapper(Resource, Comment, Graph):-
  rdfs_assert_comment(Resource, Comment, en, Graph).

