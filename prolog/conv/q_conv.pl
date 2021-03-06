:- module(
  q_conv,
  [
    q_conv_options/2 % +Opts1, -Opts2
  ]
).

/** <module> Quine conversion generics

@author Wouter Beek
@version 2016/08, 2016/10
*/

:- use_module(library(dict_ext)).
:- use_module(library(iri/iri_ext)).





%! q_conv_options(+Opts1, -Opts2) is det.

q_conv_options(Opts1, Opts2) :-
  iri_prefix(Scheme, Auth),
  merge_dicts(_{concept: resource, host: Auth, scheme: Scheme}, Opts1, Opts2).
