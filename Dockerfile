# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git g++ make zlib1g-dev

## Add source code to the build stage.
WORKDIR /
ADD https://api.github.com/repos/capuanob/mutscan/git/refs/heads/mayhem version.json
RUN git clone -b mayhem https://github.com/capuanob/mutscan.git
WORKDIR mutscan

## Build
RUN make -j$(nproc)

## Consolidate all dynamic libraries used by the fuzzer
RUN mkdir /deps
RUN cp `ldd /mutscan/mutscan | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || :

## Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
COPY --from=builder /mutscan/mutscan /mutscan
COPY --from=builder /deps /usr/lib

CMD /mutscan -1 @@
