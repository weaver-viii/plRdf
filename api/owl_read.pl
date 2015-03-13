:- module(
  owl_read,
  [
    owl_class_equivalence/2, % ?Class1:uri
                             % ?Class2:uri
    owl_disjointWith/2, % ?Class:iri
                        % ?Class:iri
    owl_identity_set/2, % +IRI:iri
                        % -IdentitySet:ordset(iri)
    owl_resource_identity/2, % ?Resource1:uri
                             % ?Resource2:uri
    owl_resource_identity/3, % ?Resource1:uri
                             % ?Resource2:uri
                             % ?Graph:atom
    owl_resource_identity/4, % ?Resource1:uri
                             % ?Graph1:atom
                             % ?Resource2:uri
                             % ?Graph2:atom
    owl_resource_identity/5 % ?Resource1:uri
                            % ?Graph1:atom
                            % ?Resource2:uri
                            % ?Graph2:atom
                            % ?LinkGraph:atom
  ]
).

/** <module> OWL read

Predicates for reading from OWL data.

@author Wouter Beek
@version 2013/01, 2013/03-2013/05, 2013/08, 2014/06, 2014/11
*/

:- use_module(library(ordsets)).
:- use_module(library(semweb/rdf_db), except([rdf_node/1])).
:- use_module(library(semweb/rdfs)).

:- use_module(plc(generics/meta_ext)).

:- use_module(plRdf(term/rdf_term)).

:- rdf_meta(owl_class_equivalence(r,r)).
:- rdf_meta(owl_disjointWith(+,r,r)).
:- rdf_meta(owl_resource_identity(r,r)).





owl_class_equivalence(Class1, Class2):-
  rdf_has(Class1, owl:equivalentClass, Class2).

owl_disjointWith(C1, C2):-
  rdf(C1, owl:disjointWith, C2), !,
  rdfs_individual_of(C1, rdfs:'Class'),
  rdfs_individual_of(C2, rdfs:'Class'),
  \+ ((
    rdfs_individual_of(X, C1),
    rdfs_individual_of(X, C1)
  )).

%! owl_identity_set(+IRI:iri, -IdentitySet:ordset(iri)) is det.
% Returns the identity set for the given IRI.

owl_identity_set(IRI, I_Set):-
  rdf_iri(IRI), !,
  % No double occurrences.
  findall(
    I_IRI,
    owl_resource_identity(IRI, I_IRI),
    I_IRIs
  ),
  update_datastructure(ord_add_element, [], [IRI|I_IRIs], I_Set).

owl_resource_identity(Resource1, Resource2):-
  rdf_has(Resource1, owl:sameAs, Resource2).
owl_resource_identity(Resource, Resource).

owl_resource_identity(R1, R2, G):-
  rdf(R1, owl:sameAs, R2, G).

owl_resource_identity(Resource1, G1, Resource2, G2):-
  owl_resource_identity(Resource1, G1, Resource2, G2, _LinkG).

owl_resource_identity(Resource1, G1, Resource2, G2, LinkG):-
  rdf(Resource1, owl:sameAs, Resource2, LinkG),
  rdf(Resource1, _P1, _O1, G1),
  rdf(Resource2, _P2, _O2, G2).
owl_resource_identity(Resource, G, Resource, G, _LinkG).
