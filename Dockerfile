FROM ubuntu:23.04 as setup

ARG CONCURRENCY

# set paths
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32
RUN export DEBIAN_FRONTEND=noninteractive && apt update && apt install -y sudo git

# install deps
RUN mkdir -p /usr/local/src
WORKDIR /usr/local/src
RUN git clone https://github.com/valhalla/valhalla
RUN bash /usr/local/src/valhalla/scripts/install-linux-deps.sh
RUN rm -rf /var/lib/apt/lists/*

# get the code into the right place and prepare to build it
WORKDIR /usr/local/src/valhalla
RUN git submodule sync && git submodule update --init --recursive
RUN rm -rf build && mkdir build

FROM setup as builder

# configure the build with symbols turned on so that crashes can be triaged
WORKDIR /usr/local/src/valhalla/build
# switch back to -DCMAKE_BUILD_TYPE=RelWithDebInfo and uncomment the block below if you want debug symbols
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DENABLE_SINGLE_FILES_WERROR=Off -DBENCHMARK_ENABLE_WERROR=Off \
-DENABLE_TESTS=OFF -DENABLE_BENCHMARKS=OFF -DENABLE_CCACHE=OFF \
-DBUILD_SHARED_LIBS=OFF -DENABLE_PYTHON_BINDINGS=OFF -DENABLE_TOOLS=OFF \
-DENABLE_SERVICES=OFF -DENABLE_HTTP=OFF -DENABLE_DATA_TOOLS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON
RUN make all -j${CONCURRENCY:-$(nproc)}
RUN make install

FROM builder as shared
COPY ./bindings/valhalla_go.* .
RUN cp -r /usr/local/include/valhalla/third_party/* /usr/local/include/
RUN g++ \
valhalla_go.cpp \
-fPIC \
-shared \
-o libvalhallago.so \
-Wl,-Bstatic \
-lvalhalla \
-Wl,-Bdynamic \
-lprotobuf-lite \
-lz \
-lpthread
RUN cp libvalhallago.so /usr/local/lib/

FROM shared as gobuilder
RUN curl -LO https://go.dev/dl/go1.21.6.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
COPY *.go .
RUN rm bindings_gen.go
COPY ./bindings/valhalla_go.h .
ENV CGO_ENABLED=1
ENV LD_LIBRARY_PATH=/usr/local/lib/
RUN go test -c -o foo -ldflags '-extldflags "-L/usr/local/lib/ -lvalhallago"' *.go