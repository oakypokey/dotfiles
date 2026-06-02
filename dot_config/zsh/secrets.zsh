export GITEA_ACCESS_TOKEN="$(security find-generic-password -s "GITEA_ACCESS_TOKEN" -w -a "$(whoami)")"
