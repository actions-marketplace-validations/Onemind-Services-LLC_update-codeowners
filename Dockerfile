FROM casperdcl/git-fame:1.15.2

RUN apk update && apk add --no-cache jq curl

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
