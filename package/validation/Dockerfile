FROM registry.suse.com/bci/bci-base:15.7
RUN curl -L https://github.com/open-policy-agent/opa/releases/download/v0.62.1/opa_linux_amd64 > /usr/bin/opa
RUN chmod +x /usr/bin/opa
COPY validation/policies /usr/share/opa/policies/
COPY validation/entrypoint.sh /usr/bin/

ENTRYPOINT ["/usr/bin/entrypoint.sh"]