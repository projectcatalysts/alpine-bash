# Alpine Linux plus bash
ARG base_image
FROM ${base_image}

ARG package_version
LABEL package_version="${package_version}"

# do all in one step
RUN apk add --no-cache bash && \
	apk add --no-cache nano && \
	apk add --no-cache curl && \
	apk add --no-cache sudo

COPY docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["docker-entrypoint.sh"]