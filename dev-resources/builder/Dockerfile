FROM busybox

COPY ./sleep45.sh /sleep45.sh
COPY ./sleep45.sh /bin/unpack
RUN chmod +x /sleep45.sh /bin/unpack

ENTRYPOINT ["/sleep45.sh"]
