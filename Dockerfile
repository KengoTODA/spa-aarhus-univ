FROM sphinxdoc/sphinx:4.1.0

RUN /usr/local/bin/python -m pip install --upgrade pip
# https://sphinx-rtd-theme.readthedocs.io/en/stable/
RUN pip install sphinx_rtd_theme sphinx-intl
