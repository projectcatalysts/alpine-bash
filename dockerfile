ARG base_image
ARG package_version

# AlpineLinux plus bash
FROM "${base_image}"
LABEL package_version="${package_version}"

# do all in one step
RUN apk add --no-cache bash && \
	apk add --no-cache nano && \
	apk add --no-cache curl
