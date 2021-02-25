Japanese translation of https://cs.au.dk/~amoeller/spa/spa.pdf

## How to build

Build in the docker container like:

```sh
docker build -t spa-sphinx .
docker run --rm -v $(pwd):/docs spa-sphinx make html
```

## Copyright

Copyright © 2008–2020 Anders Møller and Michael I. Schwartzbach

Department of Computer Science
Aarhus University, Denmark

This work is licensed under the Creative Commons Attribution-NonCommercialNoDerivatives 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.
