{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.sqlite
    pkgs.python310
    pkgs.python310Packages.fastapi
    pkgs.python310Packages.sqlalchemy
    pkgs.python310Packages.uvicorn
    pkgs.python310Packages.psycopg2
    pkgs.python310Packages.pip
    pkgs.python310Packages.setuptools
  ];
  shellHook = ''
    # Tells pip to put packages into $PIP_PREFIX instead of the usual locations.
    # See https://pip.pypa.io/en/stable/user_guide/#environment-variables.
    export PIP_PREFIX=$(pwd)/_build/pip_packages
    export PYTHONPATH="$PIP_PREFIX/${pkgs.python310.sitePackages}:$PYTHONPATH"
    export PATH="$PIP_PREFIX/bin:$PATH"
    unset SOURCE_DATE_EPOCH
    pip install sqlalchemy-cockroachdb
  '';
}
