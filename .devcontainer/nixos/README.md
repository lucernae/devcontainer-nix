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

# Development

We uses nix inside the Dockerfile to generate tarball of NixOS rootfs. 
Then we uses minimal docker base image to generate the final image.

For development, you can check the image without having to retrigger VSCode's "Rebuild Container".
Simply run `nix-build systemd-docker.nix` to produce `result-2` link, which 
is a `streamedLayerImage` executable. You can then load it into docker
using `./streamedLayerImage | docker load`.

To check the image, run `docker-compose up` after you load it.
The goal is to have SystemD running as PID 1, and then you can enter the shell as root
using `docker-compose exec devcontainer bash`