FROM docker:27-cli

RUN apk add --no-cache bash grep sed coreutils jq

COPY generate-easymesh-datamodel.sh /usr/local/bin/generate-easymesh-datamodel.sh

RUN sed -i 's/\r$//' /usr/local/bin/generate-easymesh-datamodel.sh && \
    chmod +x /usr/local/bin/generate-easymesh-datamodel.sh

CMD ["/usr/local/bin/generate-easymesh-datamodel.sh"]
