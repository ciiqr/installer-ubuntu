# installer-ubuntu

Installs ubuntu with my custom configuration (see [ciiqr/config](https://github.com/ciiqr/config))

# generate iso from non-ubuntu system with docker
```
# build
docker build -t installer-ubuntu .

# run (ie. for windows)
docker run -v /c/config:/config -v /c/config-private:/config-private -v /c/Users/william/Dropbox/Projects/installer-ubuntu:/app -t installer-ubuntu
```
