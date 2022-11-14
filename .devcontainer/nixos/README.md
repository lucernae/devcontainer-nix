# (Experimental) Devcontainer-Nix with NixOS

This is an experimental effort to build Dockerfile recipe, capable of running NixOS using devcontainer mechanism.

We can build NixOS OCI image using nix, but it is not integrated nicely with vscode devcontainer mechanism.
For example, in docker-compose based devcontainer,
you can specify your own Dockerfile to build a custom 
image. Or specify your docker-compose file to 
customized a base image.

However, if you are using Nix to build the image, you 
need to push it to a docker registry, before you can 
use it as devcontainer. This is as opposed to a 
general workflow of vscode devcontainer where 
you can edit your devcontainer specification, and then 
switch to "rebuild the container" to develop from inside it.

There is no way to build nix package directly as triggered by vscode.

In this experiment, we want to see if such workflow is possible, given 
there are lots of things vscode-server did setup, on top of the running container (not at build time).