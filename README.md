Japanese translation of https://cs.au.dk/~amoeller/spa/spa.pdf

## How to build

Build in the docker container like:

```sh
docker build -t spa-sphinx .
# build the document in English
docker run --rm -v $(pwd):/docs spa-sphinx make html
```

## How to translate

This document uses [Sphinx's internationalization feature](https://www.sphinx-doc.org/en/master/usage/advanced/intl.html) to generate contents in Japanese.

```sh
docker build -t spa-sphinx .
# reflect changes in .rst file to .po file
docker run --rm -v $(pwd):/docs spa-sphinx make gettext
# build the document in Japanese
docker run --rm -v $(pwd):/docs spa-sphinx sphinx-intl update -p _build/gettext -l ja
```

## Copyright

Copyright © 2008–2020 Anders Møller and Michael I. Schwartzbach

Department of Computer Science
Aarhus University, Denmark

This work is licensed under the Creative Commons Attribution-NonCommercialNoDerivatives 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.
