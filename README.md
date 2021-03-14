Japanese translation of https://cs.au.dk/~amoeller/spa/spa.pdf

## How to build

This document uses [Sphinx's internationalization feature](https://www.sphinx-doc.org/en/master/usage/advanced/intl.html) to generate contents in Japanese.

```sh
# build the docker container to run Sphinx
docker build -t spa-sphinx .
# reflect changes in .rst file to .pot file
docker run --rm -v $(pwd):/docs spa-sphinx make gettext
# reflect changes in .pot file to .po file
docker run --rm -v $(pwd):/docs spa-sphinx sphinx-intl update -p _build/gettext -l ja
# build the document in Japansese
docker run --rm -v $(pwd):/docs spa-sphinx make html
```

## Copyright

Copyright © 2008–2020 Anders Møller and Michael I. Schwartzbach

Department of Computer Science
Aarhus University, Denmark

This work is licensed under the Creative Commons Attribution-NonCommercialNoDerivatives 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.
