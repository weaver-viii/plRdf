:- module(
  jsonld_test,
  [
    run_test/2 % +Mode:oneof([build,read])
               % +Number:positive_integer
  ]
).

/** <module> JSON-LD tests

Largely derived from the JSON-LD 1.0 specification (W3C).

@author Wouter Beek
@version 2015/07-2015/08
*/

:- use_module(library(deb_ext)).
:- use_module(library(dict_ext)).
:- use_module(library(error)).
:- use_module(library(jsonld/jsonld_build)).
:- use_module(library(jsonld/jsonld_read)).
:- use_module(library(print_ext)).
:- use_module(library(rdf/rdf_print)).
:- use_module(library(semweb/rdf_db)).





%! run_test(+Mode:oneof([build,read]), +Number:positive_integer) is det.

run_test(build, N):- !,
  formatln('JSON-LD build test ~D', [N]),

  atomic_list_concat([build,N], -, G),
  rdf_unload_graph(G),
  test(build, N, G),
  rdf_print_graph(G, [abbr_list(true),indent(2)]),

  once(rdf(S, _, _, G)),
  jsonld_build(S, D),
  formatln('Dictionary:'),
  print_dict(D, 2),
  nl,

  formatln('Parsed statements:'),
  forall(
    jsonld_read(D, T, [base('http://example.com/resource/'),graph(G)]),
    rdf_print_statement(T, [abbr_list(true),indent(2)])
  ),
  nl.
run_test(reade, N):-
  \+ test(read, N, _), !,
  existence_error(test, N).
run_test(read, N):- !,
  formatln('JSON-LD read test ~D', [N]),

  test(read, N, D),
  formatln('Dictionary:'),
  print_dict(D, 2),
  nl,

  formatln('Parsed statements:'),
  G = test,
  rdf_unload_graph(G),
  forall(
    jsonld_read(D, T, [base('http://example.com/resource/'),graph(G)]),
    rdf_print_statement(T, [abbr_list(true),indent(2)])
  ),
  nl.



test(build, 1, G):-
  rdf_assert(rdf:s, rdf:type, rdf:'C', G),
  rdf_assert(rdf:s, rdf:p, rdf:o, G),
  rdf_bnode(B),
  rdf_assert(rdf:s, rdf:p, B, G),
  rdf_assert(rdf:s, 'http://www.example.com/aap', rdf:o, G),
  rdf_assert(rdf:s, 'http://www.example.com/aap', literal(aap), G).



% Sample JSON-LD document using full IRIs instead of terms.
test(read, 2, _{
  'http://schema.org/name': 'Manu Sporny',
  'http://schema.org/url': _{'@id': 'http://manu.sporny.org/'},
  'http://schema.org/image': _{'@id': 'http://manu.sporny.org/images/manu.png'}
}).

% In-line context definition.
test(read, 5, _{
  '@context': _{
    'name': 'http://schema.org/name',
    'image': _{'@id': 'http://schema.org/image', '@type': '@id'},
    'homepage': _{'@id': 'http://schema.org/url', '@type': '@id'}
  },
  'name': 'Manu Sporny',
  'homepage': 'http://manu.sporny.org/',
  'image': 'http://manu.sporny.org/images/manu.png'
}).

% Values of @id are interpreted as IRI.
test(read, 6, _{
  '@context': _{
    'name': 'http://schema.org/name',
    'image': _{'@id': 'http://schema.org/image', '@type': '@id'},
    'homepage': _{'@id': 'http://schema.org/url', '@type': '@id'}
  },
  homepage: _{'@id': 'http://example.com/'}
}).

% IRIs can be relative.
test(read, 7, _{
  '@context': _{
    'name': 'http://schema.org/name',
    'image': _{'@id': 'http://schema.org/image', '@type': '@id'},
    'homepage': _{'@id': 'http://schema.org/url', '@type': '@id'}
  },
  homepage: _{'@id': '../'}
}).

% IRI as a key.
test(read, 8, _{
  'http://schema.org/name': 'Manu Sporny'
}).

% Term expansion from context definition.
test(read, 9, _{
  '@context': _{name: 'http://schema.org/name'},
  name: 'Manu Sporny',
  status: 'trollin\''
}).

% Type coercion.
test(read, 10, _{
  '@context': _{homepage: _{'@id': 'http://schema.org/url', '@type': '@id'}},
  homepage: 'http://manu.sporny.org/'
}).

% Identifying a node.
test(read, 11, _{
  '@context': _{name: 'http://schema.org/name'},
  '@id': 'http://me.markus-lanthaler.com/',
  name: 'Markus Lanthaler'
}).

% Specifyg the type for a node.
test(read, 12, _{
  '@id': 'http://example.org/places#BrewEats',
  '@type': 'http://schema.org/Restaurant'
}).

% Specifying multiple types for a node.
test(read, 13, _{
  '@id': 'http://example.org/places#BrewEats',
  '@type': ['http://schema.org/Restaurant','http://schema.org/Brewery']
}).

% Using a term to specify the type.
test(read, 14, _{
  '@context': _{
    'Restaurant': 'http://schema.org/Restaurant',
    'Brewery': 'http://schema.org/Brewery'
  },
  '@id': 'http://example.org/places#BrewEats',
  '@type': ['Restaurant','Brewery']
}).

% Use a relative IRI as node identifier.
test(read, 15, _{
  '@context': _{label: 'http://www.w3.org/2000/01/rdf-schema#label'},
  '@id': '',
  'label': 'Just a simple document'
}).

% Setting the document base in a document.
test(read, 16, _{
  '@context': _{
    '@base': 'http://example.com/document.jsonld',
    label: 'http://www.w3.org/2000/01/rdf-schema#label'
  },
  '@id': '',
  label: 'Just a simple document'
}).

% Using a common vocabulary prefix.
test(read, 17, _{
  '@context': _{'@vocab': 'http://schema.org/'},
  '@id': 'http://example.org/places#BrewEats',
  '@type': 'Restaurant',
  name: 'Brew Eats'
}).

% Using the null keyword to ignore data.
test(read, 18, _{
  '@context': _{'@vocab': 'http://schema.org/', databaseId: null},
  '@id': 'http://example.org/places#BrewEats',
  '@type': 'Restaurant',
  name: 'Brew Eats',
  databaseId: '23987520'
}).

% Prefix expansion.
test(read, 19, _{
  '@context': _{foaf: 'http://xmlns.com/foaf/0.1/'},
  '@type': 'foaf:Person',
  'foaf:name': 'Dave Longley'
}).

% Using vocabularies.
test(read, 20, _{
  '@context': _{
    xsd: 'http://www.w3.org/2001/XMLSchema#',
    foaf: 'http://xmlns.com/foaf/0.1/',
    'foaf:homepage': _{'@type': '@id'},
    picture: _{'@id': 'foaf:depiction', '@type': '@id'}
  },
  '@id': 'http://me.markus-lanthaler.com/',
  '@type': 'foaf:Person',
  'foaf:name': 'Markus Lanthaler',
  'foaf:homepage': 'http://www.markus-lanthaler.com/',
  picture: 'http://twitter.com/account/profile_image/markuslanthaler'
}).

% Expanded term definition with type coercion.
test(read, 21, _{
  '@context': _{
    modified: _{
      '@id': 'http://purl.org/dc/terms/modified',
      '@type': 'http://www.w3.org/2001/XMLSchema#dateTime'
    }
  },
  '@id': 'http://example.com/docs/1',
  modified: '2010-05-29T14:17:39+02:00'
}).

% Expanded value with type.
test(read, 22, _{
  '@context': _{
    modified: _{'@id': 'http://purl.org/dc/terms/modified'}
  },
  modified: _{
    '@value': '2010-05-29T14:17:39+02:00',
    '@type': 'http://www.w3.org/2001/XMLSchema#dateTime'
  }
}).

% Example demonstrating the context-sensitivity for @type.
test(read, 23, _{
  '@context': _{'@vocab': 'http://example.org/'},
  '@id': 'http://example.org/posts#TripToWestVirginia',
  '@type': 'http://schema.org/BlogPosting',
  modified: _{
    '@value': '2010-05-29T14:17:39+02:00',
    '@type': 'http://www.w3.org/2001/XMLSchema#dateTime'
  }
}).

% Expanded term definition with types.
test(read, 24, _{
  '@context': _{
    xsd: 'http://www.w3.org/2001/XMLSchema#',
    name: 'http://xmlns.com/foaf/0.1/name',
    age: _{
      '@id': 'http://xmlns.com/foaf/0.1/age',
      '@type': 'xsd:integer'
    },
    'homepage': _{
      '@id': 'http://xmlns.com/foaf/0.1/homepage',
      '@type': '@id'
    }
  },
  '@id': 'http://example.com/people#john',
  name: 'John Smith',
  age: '41',
  homepage: [
    'http://personal.example.org/',
    'http://work.example.com/jsmith/'
  ]
}).

% Term definitions using compact and absolute IRIs.
test(read, 25, _{
  '@context': _{
    foaf: 'http://xmlns.com/foaf/0.1/',
    'foaf:age': _{
      '@id': 'http://xmlns.com/foaf/0.1/age',
      '@type': 'xsd:integer'
    },
    'http://xmlns.com/foaf/0.1/homepage': _{'@type': '@id'}
  },
  'foaf:name': 'John Smith',
  'foaf:age': '41',
  'http://xmlns.com/foaf/0.1/homepage': [
    'http://personal.example.org/',
    'http://work.example.com/jsmith/'
  ]
}).

% Embedding a node object as property value of another node object.
test(read, 26, _{
  '@context': _{'@vocab': foaf, foaf: 'http://xmlns.com/foaf/0.1/'},
  name: 'Manu Sporny',
  knows: _{'@type': 'Person', name: 'Gregg Kellogg'}
}).

% Setting the default language of a JSON-LD document.
test(read, 31, _{
  '@context': _{'@language': ja, '@vocab': 'http://xmlns.com/foaf/0.1/'},
  name: '花澄',
  occupation: '科学者'
}).

% Expanded term definition with language.
%
% ```nquads
% _:8 <http://example.com/vocab/name> "Yagyū Muneyoshi"^^<http://www.w3.org/2001/XMLSchema#string> .
% _:8 <http://example.com/vocab/occupation> "忍者"@ja .
% _:8 <http://example.com/vocab/occupation> "Nindža"@cs .
% _:8 <http://example.com/vocab/occupation> "Ninja"@en .
% ```
test(read, 33, _{
  '@context': _{
    ex: 'http://example.com/vocab/',
    '@language': ja,
    name: _{'@id': 'ex:name', '@language': null},
    occupation: _{'@id': 'ex:occupation'},
    occupation_en: _{'@id': 'ex:occupation', '@language': en},
    occupation_cs: _{'@id': 'ex:occupation', '@language': cs}
  },
  name: 'Yagyū Muneyoshi',
  occupation: '忍者',
  occupation_en: 'Ninja',
  occupation_cs: 'Nindža'
}).

% Overriding default language using an expanded value.
%
% ```nquads
% _:11 <http://example.com/name> "花澄"@ja .
% _:11 <http://example.com/occupation> "Scientist"@en .
% ```
test(read, 35, _{
  '@context': _{'@language': ja, '@vocab': 'http://example.com/'},
  name: '花澄',
  occupation: _{'@language': en, '@value': 'Scientist'}
}).

% Removing language information using an expanded value.
%
% ```nquads
% _:12 <http://example.com/name> "Frank"^^<http://www.w3.org/2001/XMLSchema#string> .
% _:12 <http://example.com/occupation> "Ninja"@en .
% _:12 <http://example.com/speciality> "手裏剣"@ja .
% ```
test(read, 36, _{
  '@context': _{'@language': ja, '@vocab': 'http://example.com/'},
  name: _{'@value': 'Frank'},
  occupation: _{'@language': en, '@value': 'Ninja'},
  speciality: '手裏剣'
}).

% IRI expansion within a context
test(37, _{
  '@context': _{
    xsd: 'http://www.w3.org/2001/XMLSchema#',
    name: 'http://xmlns.com/foaf/0.1/name',
    age: _{
      '@id': 'http://xmlns.com/foaf/0.1/age',
      '@type': 'xsd:integer'
    },
    homepage: _{
      '@id': 'http://xmlns.com/foaf/0.1/homepage',
      '@type': '@id'
    }
  },
  homepage: '',
  age: 0,
  name: ''
}).

% Using a term to define the IRI of another term within a context.
test(read, 38, _{
  '@context': _{
    foaf: 'http://xmlns.com/foaf/0.1/',
    xsd: 'http://www.w3.org/2001/XMLSchema#',
    name: 'foaf:name',
    age: _{
      '@id': 'foaf:age',
      '@type': 'xsd:integer'
    },
    homepage: _{
      '@id': 'foaf:homepage',
      '@type': '@id'
    }
  },
  homepage: '',
  age: 0,
  name: ''
}).

% Using a compact IRI as a term.
test(read, 39, _{
  '@context': _{
    foaf: 'http://xmlns.com/foaf/0.1/',
    xsd: 'http://www.w3.org/2001/XMLSchema#',
    name: 'foaf:name',
    'foaf:age': _{'@type': 'xsd:integer'},
    'foaf:homepage': _{'@type': '@id'}
  },
  'foaf:homepage': '',
  'foaf:age': 0,
  name: ''
}).

% Associating context definitions with absolute IRIs.
test(read, 40, _{
  '@context': _{
    foaf: 'http://xmlns.com/foaf/0.1/',
    xsd: 'http://www.w3.org/2001/XMLSchema#',
    name: 'foaf:name',
    'foaf:age': _{'@id': 'foaf:age', '@type': 'xsd:integer'},
    'http://xmlns.com/foaf/0.1/homepage': _{'@type': '@id'}
  },
  'foaf:homepage': '',
  'foaf:age': 0,
  name: ''
}).

% Multiple values with no inherent order.
test(read, 42, _{
  '@context': _{'@vocab': 'http://example.org/'},
  '@id': 'http://example.org/people#joebob',
  nick: [joe,bob,'JB']
}).

% Using an expanded form to set multiple values.
test(read, 43, _{
  '@context': _{dc: 'http://purl.org/dc/elements/1.1/'},
  '@id': 'http://example.org/articles/8',
  'dc:title': [
    _{'@value': 'Das Kapital', '@language': de},
    _{'@value': 'Capital', '@language': en}
  ]
}).

% An ordered collection of values in JSON-LD.
test(read, 44, _{
  '@context': _{foaf: 'http://xmlns.com/foaf/0.1/'},
  '@id': 'http://example.org/people#joebob',
  'foaf:nick': _{'@list': [joe,bob,jaybee]}
}).

% Specifying that a collection is ordered in the context.
test(read, 45, _{
  '@context': _{
    nick: _{
      '@id': 'http://xmlns.com/foaf/0.1/nick',
      '@container': '@list'
    }
  },
  '@id': 'http://example.org/people#joebob',
  nick: [joe,bob,jaybee]
}).

% A document with children linking to their parent.
test(read, 46, [
  _{
    '@id': '#homer',
    'http://example.com/vocab#name': 'Homer'
  },
  _{
    '@id': '#bart',
    'http://example.com/vocab#name': 'Bart',
    'http://example.com/vocab#parent': _{'@id': '#homer'}
  },
  _{
    '@id': '#lisa',
    'http://example.com/vocab#name': 'Lisa',
    'http://example.com/vocab#parent': _{'@id': '#homer'}
  }
]).

% Specifying a local blank node identifier.
test(read, 52, _{
  '@context': _{'@vocab': 'http://www.example.org/'},
  '@id': '_:n1',
  name: 'Secret Agent 1',
  knows: _{name: 'Secret Agent 2', knows: _{'@id': '_:n1'}}
}).
