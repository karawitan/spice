
Option 1: Export PYENV_VERSION manually
Set the environment variable before running jhbuild:

bash
export PYENV_VERSION=$(pyenv version-name)
~/spice/bin/jhbuild bootstrap
Option 2: Initialize pyenv properly
Make sure pyenv is properly initialized in your shell. Add this to your shell profile (.bashrc, .zshrc, etc.) if it's not already there:

bash
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
Then source your profile or restart your terminal:

bash
source ~/.bashrc  # or ~/.zshrc

